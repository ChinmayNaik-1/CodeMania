import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';
import { checkAndUpdateContestStatus, refreshAllContestStatuses } from '../middleware/contestStatus.js';
import { getLeaderboard, recordContestSubmission } from '../services/contestService.js';
import { getRedisClient } from '../services/leaderboardService.js';
import { judgeSubmission } from '../services/judgeService.js';
import { submissionQueue } from '../services/submissionQueue.js';

const router = Router();
router.use(authMiddleware);

// ─────────────────────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────────────────────

function createError(msg, status = 400) {
  const e = new Error(msg);
  e.status = status;
  return e;
}

async function getContestOrThrow(contestId) {
  const r = await dbPool.query(`SELECT * FROM contests WHERE id = $1`, [contestId]);
  if (r.rows.length === 0) throw createError('Contest not found', 404);
  return r.rows[0];
}

async function getMyTeamInContest(contestId, userId) {
  const r = await dbPool.query(
    `SELECT ct.id AS team_id, ct.created_by
     FROM contest_teams ct
     JOIN contest_team_members ctm ON ctm.team_id = ct.id
     WHERE ct.contest_id = $1 AND ctm.user_id = $2
     LIMIT 1`,
    [contestId, userId]
  );
  return r.rows[0] ?? null;
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/contests — list split by status
// ─────────────────────────────────────────────────────────────────────────────
router.get('/', async (req, res) => {
  await refreshAllContestStatuses();

  const r = await dbPool.query(
    `SELECT
       c.id, c.title, c.contest_type, c.max_team_size,
       c.start_time, c.end_time, c.status,
       (SELECT COUNT(*) FROM contest_problems cp WHERE cp.contest_id = c.id)::int AS problem_count
     FROM contests c
     WHERE c.status != 'draft'
     ORDER BY c.start_time ASC`
  );

  const userId = req.user.id;
  const result = { upcoming: [], live: [], ended: [] };

  for (const row of r.rows) {
    // Check registration
    let isRegistered = false;
    if (row.contest_type === 'solo') {
      const reg = await dbPool.query(
        `SELECT 1 FROM contest_registrations WHERE contest_id = $1 AND user_id = $2`,
        [row.id, userId]
      );
      isRegistered = reg.rows.length > 0;
    } else {
      const team = await getMyTeamInContest(row.id, userId);
      isRegistered = team != null;
    }

    const entry = { ...row, is_registered: isRegistered };
    if (row.status === 'upcoming') result.upcoming.push(entry);
    else if (row.status === 'live') result.live.push(entry);
    else if (row.status === 'ended') result.ended.push(entry);
  }

  res.json(result);
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/contests/:id — full detail
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  if (isNaN(contestId)) return res.status(400).json({ error: 'Invalid id' });

  await checkAndUpdateContestStatus(contestId);
  const contest = await getContestOrThrow(contestId);
  const userId = req.user.id;

  // Problems with solved status
  const myTeam = await getMyTeamInContest(contestId, userId);
  const myTeamId = myTeam?.team_id ?? null;

  const problemsResult = await dbPool.query(
    `SELECT
       p.id, p.title, p.difficulty,
       cp.points, cp.problem_order,
       EXISTS (
         SELECT 1 FROM contest_problem_solves cps
         WHERE cps.contest_id = $1 AND cps.problem_id = p.id
           AND cps.user_id = $2 AND cps.team_id IS NULL
       ) AS is_solved_by_me,
       CASE WHEN $3::int IS NOT NULL THEN
         EXISTS (
           SELECT 1 FROM contest_problem_solves cps
           WHERE cps.contest_id = $1 AND cps.problem_id = p.id
             AND cps.team_id = $3
         )
       ELSE false END AS is_solved_by_team
     FROM contest_problems cp
     JOIN problems p ON p.id = cp.problem_id
     WHERE cp.contest_id = $1
     ORDER BY cp.problem_order ASC, p.id ASC`,
    [contestId, userId, myTeamId]
  );

  // My registration
  let myRegistration = null;
  if (contest.contest_type === 'solo') {
    const reg = await dbPool.query(
      `SELECT 1 FROM contest_registrations WHERE contest_id = $1 AND user_id = $2`,
      [contestId, userId]
    );
    if (reg.rows.length > 0) myRegistration = { type: 'solo', team: null };
  } else if (myTeam) {
    const membersResult = await dbPool.query(
      `SELECT ctm.user_id, u.username, u.avatar_url
       FROM contest_team_members ctm
       JOIN users u ON u.id = ctm.user_id
       WHERE ctm.team_id = $1`,
      [myTeamId]
    );
    const teamRow = await dbPool.query(
      `SELECT id, name FROM contest_teams WHERE id = $1`,
      [myTeamId]
    );
    myRegistration = {
      type: 'team',
      team: {
        id: myTeamId,
        name: teamRow.rows[0]?.name,
        is_leader: myTeam.created_by === userId,
        members: membersResult.rows,
      },
    };
  }

  // My team invitations (invites sent TO me)
  const invitationsResult = await dbPool.query(
    `SELECT cti.id, cti.team_id, ct.name AS team_name, u.username AS inviter_username
     FROM contest_team_invitations cti
     JOIN contest_teams ct ON ct.id = cti.team_id
     JOIN users u ON u.id = cti.inviter_id
     WHERE cti.contest_id = $1 AND cti.invitee_id = $2 AND cti.status = 'pending'`,
    [contestId, userId]
  );

  res.json({
    ...contest,
    problems: problemsResult.rows,
    my_registration: myRegistration,
    my_team_invitations: invitationsResult.rows,
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/contests/:id/register
// ─────────────────────────────────────────────────────────────────────────────
router.post('/:id/register', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  if (isNaN(contestId)) return res.status(400).json({ error: 'Invalid id' });

  await checkAndUpdateContestStatus(contestId);
  const contest = await getContestOrThrow(contestId);

  if (contest.status !== 'upcoming') {
    return res.status(400).json({ error: 'Registration only available for upcoming contests' });
  }

  const userId = req.user.id;

  if (contest.contest_type === 'solo') {
    await dbPool.query(
      `INSERT INTO contest_registrations (contest_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [contestId, userId]
    );
    return res.json({ success: true });
  }

  // Team contest — create team
  const { team_name } = req.body;
  if (!team_name || !team_name.trim()) {
    return res.status(400).json({ error: 'team_name required for team contests' });
  }

  // Check user not already in a team
  const existing = await getMyTeamInContest(contestId, userId);
  if (existing) return res.status(400).json({ error: 'Already in a team for this contest' });

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');
    const teamResult = await client.query(
      `INSERT INTO contest_teams (contest_id, name, created_by)
       VALUES ($1, $2, $3)
       RETURNING id, name`,
      [contestId, team_name.trim(), userId]
    );
    const team = teamResult.rows[0];
    await client.query(
      `INSERT INTO contest_team_members (team_id, user_id) VALUES ($1, $2)`,
      [team.id, userId]
    );
    await client.query('COMMIT');
    return res.json({ team_id: team.id, team_name: team.name });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') return res.status(400).json({ error: 'Team name already taken for this contest' });
    throw err;
  } finally {
    client.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// DELETE /api/contests/:id/register — unregister
// ─────────────────────────────────────────────────────────────────────────────
router.delete('/:id/register', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const contest = await getContestOrThrow(contestId);
  if (contest.status === 'live' || contest.status === 'ended') {
    return res.status(400).json({ error: 'Cannot unregister from a live or ended contest' });
  }

  const userId = req.user.id;

  if (contest.contest_type === 'solo') {
    await dbPool.query(
      `DELETE FROM contest_registrations WHERE contest_id = $1 AND user_id = $2`,
      [contestId, userId]
    );
    return res.json({ success: true });
  }

  // Team contest
  const myTeam = await getMyTeamInContest(contestId, userId);
  if (!myTeam) return res.status(404).json({ error: 'Not registered' });

  if (myTeam.created_by === userId) {
    // Leader — delete entire team (cascade removes members)
    await dbPool.query(`DELETE FROM contest_teams WHERE id = $1`, [myTeam.team_id]);
  } else {
    // Member — just leave
    await dbPool.query(
      `DELETE FROM contest_team_members WHERE team_id = $1 AND user_id = $2`,
      [myTeam.team_id, userId]
    );
  }

  res.json({ success: true });
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/contests/:id/team/search-users?q=
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id/team/search-users', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const q = (req.query.q || '').toString().trim();
  if (!q) return res.json({ users: [] });

  const result = await dbPool.query(
    `SELECT u.id, u.username, u.avatar_url
     FROM users u
     WHERE u.username ILIKE $1
       AND u.id NOT IN (
         SELECT ctm.user_id
         FROM contest_team_members ctm
         JOIN contest_teams ct ON ct.id = ctm.team_id
         WHERE ct.contest_id = $2
       )
       AND u.id NOT IN (
         SELECT invitee_id FROM contest_team_invitations
         WHERE contest_id = $2 AND status = 'pending'
       )
       AND u.id != $3
     LIMIT 10`,
    [`%${q}%`, contestId, req.user.id]
  );

  res.json({ users: result.rows });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/contests/:id/team/invite
// ─────────────────────────────────────────────────────────────────────────────
router.post('/:id/team/invite', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const { invitee_id } = req.body;
  if (!invitee_id) return res.status(400).json({ error: 'invitee_id required' });

  const contest = await getContestOrThrow(contestId);
  if (contest.status !== 'upcoming') return res.status(400).json({ error: 'Contest is not upcoming' });

  // Requester must be team leader
  const myTeam = await getMyTeamInContest(contestId, req.user.id);
  if (!myTeam || myTeam.created_by !== req.user.id) {
    return res.status(403).json({ error: 'Only team leader can invite' });
  }

  // Check team size
  const countResult = await dbPool.query(
    `SELECT COUNT(*)::int AS count FROM contest_team_members WHERE team_id = $1`,
    [myTeam.team_id]
  );
  if (countResult.rows[0].count >= contest.max_team_size) {
    return res.status(400).json({ error: 'Team is full' });
  }

  try {
    await dbPool.query(
      `INSERT INTO contest_team_invitations
         (team_id, contest_id, invitee_id, inviter_id)
       VALUES ($1, $2, $3, $4)`,
      [myTeam.team_id, contestId, invitee_id, req.user.id]
    );
  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ error: 'Invite already pending for this user' });
    throw err;
  }

  res.json({ success: true });
});

// ─────────────────────────────────────────────────────────────────────────────
// PUT /api/contests/:id/invitations/:invitationId — accept or reject invite
// ─────────────────────────────────────────────────────────────────────────────
router.put('/:id/invitations/:invitationId', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const invitationId = parseInt(req.params.invitationId, 10);
  const { action } = req.body; // 'accept' | 'reject'

  if (!['accept', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'action must be accept or reject' });
  }

  const invResult = await dbPool.query(
    `SELECT * FROM contest_team_invitations WHERE id = $1`,
    [invitationId]
  );
  if (invResult.rows.length === 0) return res.status(404).json({ error: 'Invitation not found' });

  const inv = invResult.rows[0];
  if (inv.invitee_id !== req.user.id) return res.status(403).json({ error: 'Not your invitation' });
  if (inv.status !== 'pending') return res.status(400).json({ error: 'Invitation already resolved' });

  if (action === 'reject') {
    await dbPool.query(
      `UPDATE contest_team_invitations SET status = 'rejected' WHERE id = $1`,
      [invitationId]
    );
    return res.json({ success: true });
  }

  // Accept — check not already in another team
  const existingTeam = await getMyTeamInContest(contestId, req.user.id);
  if (existingTeam) return res.status(400).json({ error: 'Already in a team for this contest' });

  // Check team not full
  const contest = await getContestOrThrow(contestId);
  const countResult = await dbPool.query(
    `SELECT COUNT(*)::int AS count FROM contest_team_members WHERE team_id = $1`,
    [inv.team_id]
  );
  if (countResult.rows[0].count >= contest.max_team_size) {
    return res.status(400).json({ error: 'Team is full' });
  }

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `INSERT INTO contest_team_members (team_id, user_id) VALUES ($1, $2)`,
      [inv.team_id, req.user.id]
    );
    await client.query(
      `UPDATE contest_team_invitations SET status = 'accepted' WHERE id = $1`,
      [invitationId]
    );
    await client.query('COMMIT');
    return res.json({ success: true });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/contests/:id/problems/:problemId/submit
// ─────────────────────────────────────────────────────────────────────────────
router.post('/:id/problems/:problemId/submit', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const problemId = parseInt(req.params.problemId, 10);

  await checkAndUpdateContestStatus(contestId);
  const contest = await getContestOrThrow(contestId);

  if (contest.status !== 'live') {
    return res.status(400).json({ error: 'Contest is not live' });
  }

  const userId = req.user.id;
  const { language, code } = req.body;

  // Get team_id if team contest
  let teamId = null;
  if (contest.contest_type === 'team') {
    const myTeam = await getMyTeamInContest(contestId, userId);
    if (!myTeam) return res.status(403).json({ error: 'Not registered in a team' });
    teamId = myTeam.team_id;
  } else {
    // Solo — check registered
    const reg = await dbPool.query(
      `SELECT 1 FROM contest_registrations WHERE contest_id = $1 AND user_id = $2`,
      [contestId, userId]
    );
    if (reg.rows.length === 0) return res.status(403).json({ error: 'Not registered for this contest' });
  }

  // Get language version
  const langVersionMap = {
    python: '3.10.0', javascript: '18.15.0', java: '15.0.2', cpp: '10.2.0', c: '10.2.0',
  };
  const version = langVersionMap[language?.toLowerCase()] ?? null;

  // Insert to global submissions table with contest_id + team_id
  const submResult = await dbPool.query(
    `INSERT INTO submissions (user_id, problem_id, contest_id, team_id, language, code, verdict, status)
     VALUES ($1, $2, $3, $4, $5, $6, 'pending', 'Pending')
     RETURNING id`,
    [userId, problemId, contestId, teamId, language, code]
  );
  const submissionId = submResult.rows[0].id;

  // Enqueue for judging
  const userResult = await dbPool.query(`SELECT username FROM users WHERE id = $1`, [userId]);
  const username = userResult.rows[0]?.username ?? '';

  await submissionQueue.add({
    submissionId,
    userId,
    username,
    problemId,
    contestId,
    teamId,
    language: language?.toLowerCase(),
    version,
    code,
  });

  res.json({ submission_id: submissionId });
});

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/contests/:id/problems/:problemId/run
// ─────────────────────────────────────────────────────────────────────────────
router.post('/:id/problems/:problemId/run', async (req, res) => {
  const problemId = parseInt(req.params.problemId, 10);
  const { language, code } = req.body;

  const result = await judgeSubmission(code, language, null, problemId, dbPool, { sampleOnly: true });
  res.json(result);
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/contests/:id/leaderboard
// ─────────────────────────────────────────────────────────────────────────────
router.get('/:id/leaderboard', async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  if (isNaN(contestId)) return res.status(400).json({ error: 'Invalid id' });

  const data = await getLeaderboard(contestId);
  res.json(data);
});

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ROUTES
// ─────────────────────────────────────────────────────────────────────────────

router.get('/admin/contests', requireAdmin, async (req, res) => {
  await refreshAllContestStatuses();

  const r = await dbPool.query(
    `SELECT
       c.id, c.title, c.contest_type, c.max_team_size,
       c.start_time, c.end_time, c.status,
       (SELECT COUNT(*) FROM contest_problems cp WHERE cp.contest_id = c.id)::int AS problem_count
     FROM contests c
     ORDER BY c.start_time DESC`
  );

  res.json(r.rows);
});

router.post('/admin/create', requireAdmin, async (req, res) => {
  const { title, description, contest_type, max_team_size, start_time, end_time, problems } = req.body;
  if (!title || !start_time || !end_time) {
    return res.status(400).json({ error: 'title, start_time, end_time required' });
  }

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');
    const contestResult = await client.query(
      `INSERT INTO contests (title, description, contest_type, max_team_size, start_time, end_time, status, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, 'draft', $7)
       RETURNING id`,
      [title, description ?? null, contest_type ?? 'solo', max_team_size ?? 1, start_time, end_time, req.user.id]
    );
    const contestId = contestResult.rows[0].id;

    if (Array.isArray(problems)) {
      for (const p of problems) {
        await client.query(
          `INSERT INTO contest_problems (contest_id, problem_id, points, problem_order)
           VALUES ($1, $2, $3, $4)`,
          [contestId, p.problem_id, p.points ?? 100, p.problem_order ?? 1]
        );
      }
    }

    await client.query('COMMIT');
    res.status(201).json({ contest_id: contestId });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

router.put('/admin/:id', requireAdmin, async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const contest = await getContestOrThrow(contestId);

  if (contest.status === 'live' || contest.status === 'ended') {
    return res.status(403).json({ error: 'Cannot edit live or ended contest' });
  }

  const { title, description, contest_type, max_team_size, start_time, end_time, problems } = req.body;

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');

    const updates = [];
    const params = [];
    let i = 1;
    if (title != null) { updates.push(`title = $${i++}`); params.push(title); }
    if (description != null) { updates.push(`description = $${i++}`); params.push(description); }
    if (contest_type != null) { updates.push(`contest_type = $${i++}`); params.push(contest_type); }
    if (max_team_size != null) { updates.push(`max_team_size = $${i++}`); params.push(max_team_size); }
    if (start_time != null) { updates.push(`start_time = $${i++}`); params.push(start_time); }
    if (end_time != null) { updates.push(`end_time = $${i++}`); params.push(end_time); }

    if (updates.length > 0) {
      params.push(contestId);
      await client.query(`UPDATE contests SET ${updates.join(', ')} WHERE id = $${i}`, params);
    }

    if (Array.isArray(problems)) {
      await client.query(`DELETE FROM contest_problems WHERE contest_id = $1`, [contestId]);
      for (const p of problems) {
        await client.query(
          `INSERT INTO contest_problems (contest_id, problem_id, points, problem_order)
           VALUES ($1, $2, $3, $4)`,
          [contestId, p.problem_id, p.points ?? 100, p.problem_order ?? 1]
        );
      }
    }

    await client.query('COMMIT');
    res.json({ success: true });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
});

router.put('/admin/:id/publish', requireAdmin, async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const r = await dbPool.query(
    `UPDATE contests SET status = 'upcoming' WHERE id = $1 AND status = 'draft' RETURNING id`,
    [contestId]
  );
  if (r.rows.length === 0) return res.status(400).json({ error: 'Contest not found or not in draft status' });
  res.json({ success: true });
});

router.delete('/admin/:id', requireAdmin, async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const r = await dbPool.query(
    `DELETE FROM contests WHERE id = $1 AND status = 'draft' RETURNING id`,
    [contestId]
  );
  if (r.rows.length === 0) return res.status(400).json({ error: 'Contest not found or not in draft status' });
  res.json({ success: true });
});

router.get('/admin/:id/submissions', requireAdmin, async (req, res) => {
  const contestId = parseInt(req.params.id, 10);
  const r = await dbPool.query(
    `SELECT cs.*, u.username, p.title AS problem_title,
            ct.name AS team_name
     FROM contest_submissions cs
     JOIN users u ON u.id = cs.user_id
     JOIN problems p ON p.id = cs.problem_id
     LEFT JOIN contest_teams ct ON ct.id = cs.team_id
     WHERE cs.contest_id = $1
     ORDER BY cs.submitted_at DESC`,
    [contestId]
  );
  res.json(r.rows);
});

export default router;
