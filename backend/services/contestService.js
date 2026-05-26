import { dbPool } from '../index.js';
import { getRedisClient } from './leaderboardService.js';

function createError(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  return error;
}

async function getContestOrThrow(contestId) {
  const result = await dbPool.query(
    `SELECT id, title, description, status, max_team_size, penalty_minutes, starts_at, ends_at, created_by, created_at
     FROM contests
     WHERE id = $1`,
    [contestId]
  );

  if (result.rows.length === 0) {
    throw createError('Contest not found', 404);
  }

  return result.rows[0];
}

export async function getContests() {
  const redisClient = getRedisClient();
  const cacheKey = 'contests:list';

  if (redisClient) {
    try {
      const cached = await redisClient.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
    } catch (_) {
      // Cache miss or Redis unavailable.
    }
  }

  const result = await dbPool.query(
    `SELECT id, title, description, status, max_team_size, penalty_minutes, starts_at, ends_at, created_by, created_at
     FROM contests
     ORDER BY starts_at DESC`
  );

  if (redisClient) {
    try {
      await redisClient.set(cacheKey, JSON.stringify(result.rows), { EX: 30 });
    } catch (_) {
      // Ignore cache write failures.
    }
  }

  return result.rows;
}

export async function getContestById(contestId) {
  const contest = await getContestOrThrow(contestId);

  const problemsResult = await dbPool.query(
    `SELECT p.id,
            p.title,
            p.difficulty,
            COALESCE(cp.points, 100) AS points,
            COALESCE(cp.problem_order, 0) AS problem_order,
            p.visibility
     FROM problems p
     LEFT JOIN contest_problems cp
       ON cp.problem_id = p.id AND cp.contest_id = $1
     WHERE (p.contest_id = $1 OR cp.contest_id = $1)
     ORDER BY cp.problem_order NULLS LAST, p.id ASC`,
    [contestId]
  );

  const allowContestOnly = contest.status === 'in_progress' || contest.status === 'ended';
  const problems = problemsResult.rows.filter((problem) => {
    if (problem.visibility !== 'contest_only') return true;
    return allowContestOnly;
  });

  return { contest, problems };
}

export async function createContest(data, createdBy) {
  const {
    title,
    description,
    max_team_size: maxTeamSize,
    penalty_minutes: penaltyMinutes,
    starts_at: startsAt,
    ends_at: endsAt,
  } = data || {};

  if (!title || !startsAt || !endsAt) {
    throw createError('Missing required fields');
  }

  const result = await dbPool.query(
    `INSERT INTO contests
     (title, description, max_team_size, penalty_minutes, starts_at, ends_at, created_by)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING id, title, description, status, max_team_size, penalty_minutes, starts_at, ends_at, created_by, created_at`,
    [
      title,
      description ?? null,
      maxTeamSize ?? 1,
      penaltyMinutes ?? 20,
      startsAt,
      endsAt,
      createdBy,
    ]
  );

  return result.rows[0];
}

export async function updateContestStatus(contestId, status) {
  if (!status) {
    throw createError('Status is required');
  }

  await dbPool.query('UPDATE contests SET status = $1 WHERE id = $2', [status, contestId]);

  if (status === 'in_progress') {
    await dbPool.query(
      `UPDATE team_invites
       SET status = 'declined'
       WHERE status = 'pending'
         AND expires_at <= NOW()
         AND team_id IN (SELECT id FROM teams WHERE contest_id = $1)`,
      [contestId]
    );
  }

  return { success: true };
}

export async function createTeam(contestId, leaderId, teamName) {
  if (!teamName || teamName.trim().length === 0) {
    throw createError('Team name required');
  }

  const contest = await getContestOrThrow(contestId);
  if (contest.status !== 'registration_open') {
    throw createError('Contest is not open for registration');
  }

  const membershipCheck = await dbPool.query(
    `SELECT tm.team_id
     FROM team_members tm
     JOIN teams t ON t.id = tm.team_id
     WHERE tm.user_id = $1 AND t.contest_id = $2
     LIMIT 1`,
    [leaderId, contestId]
  );

  if (membershipCheck.rows.length > 0) {
    throw createError('User already in a team for this contest');
  }

  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');

    const teamResult = await client.query(
      `INSERT INTO teams (contest_id, name, leader_id)
       VALUES ($1, $2, $3)
       RETURNING id, contest_id, name, leader_id, created_at`,
      [contestId, teamName.trim(), leaderId]
    );

    const team = teamResult.rows[0];

    await client.query(
      `INSERT INTO team_members (team_id, user_id)
       VALUES ($1, $2)`,
      [team.id, leaderId]
    );

    await client.query('COMMIT');
    return team;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function inviteToTeam(teamId, inviteeId, requesterId) {
  const teamResult = await dbPool.query(
    `SELECT t.id, t.contest_id, t.leader_id, c.max_team_size, c.status, c.starts_at
     FROM teams t
     JOIN contests c ON c.id = t.contest_id
     WHERE t.id = $1`,
    [teamId]
  );

  if (teamResult.rows.length === 0) {
    throw createError('Team not found', 404);
  }

  const team = teamResult.rows[0];
  if (team.leader_id !== requesterId) {
    throw createError('Only team leader can invite members', 403);
  }

  if (team.status !== 'registration_open') {
    throw createError('Contest is not open for registration');
  }

  const teamCountResult = await dbPool.query(
    'SELECT COUNT(*)::int AS count FROM team_members WHERE team_id = $1',
    [teamId]
  );

  if (teamCountResult.rows[0].count >= team.max_team_size) {
    throw createError('Team is already full');
  }

  const membershipCheck = await dbPool.query(
    `SELECT tm.team_id
     FROM team_members tm
     JOIN teams t ON t.id = tm.team_id
     WHERE tm.user_id = $1 AND t.contest_id = $2
     LIMIT 1`,
    [inviteeId, team.contest_id]
  );

  if (membershipCheck.rows.length > 0) {
    throw createError('User already in a team for this contest');
  }

  const pendingCheck = await dbPool.query(
    `SELECT id FROM team_invites
     WHERE team_id = $1 AND invitee_id = $2 AND status = 'pending'
     LIMIT 1`,
    [teamId, inviteeId]
  );

  if (pendingCheck.rows.length > 0) {
    throw createError('Invite already pending');
  }

  const inviteResult = await dbPool.query(
    `INSERT INTO team_invites (team_id, invitee_id, expires_at)
     VALUES ($1, $2, $3)
     RETURNING id, team_id, invitee_id, status, expires_at, created_at`,
    [teamId, inviteeId, team.starts_at]
  );

  return inviteResult.rows[0];
}

export async function respondToInvite(inviteId, userId, accept) {
  const client = await dbPool.connect();
  try {
    await client.query('BEGIN');

    const inviteResult = await client.query(
      `SELECT ti.id, ti.team_id, ti.invitee_id, ti.status,
              t.contest_id, t.leader_id,
              c.max_team_size, c.status AS contest_status
       FROM team_invites ti
       JOIN teams t ON t.id = ti.team_id
       JOIN contests c ON c.id = t.contest_id
       WHERE ti.id = $1
       FOR UPDATE`,
      [inviteId]
    );

    if (inviteResult.rows.length === 0) {
      throw createError('Invite not found', 404);
    }

    const invite = inviteResult.rows[0];
    if (invite.invitee_id !== userId) {
      throw createError('Invite does not belong to user', 403);
    }

    if (invite.status !== 'pending') {
      throw createError('Invite already responded');
    }

    if (!accept) {
      await client.query(
        `UPDATE team_invites SET status = 'declined' WHERE id = $1`,
        [inviteId]
      );
      await client.query('COMMIT');
      return { declined: true };
    }

    if (invite.contest_status !== 'registration_open') {
      throw createError('Contest is not open for registration');
    }

    const memberCountResult = await client.query(
      'SELECT COUNT(*)::int AS count FROM team_members WHERE team_id = $1',
      [invite.team_id]
    );

    if (memberCountResult.rows[0].count >= invite.max_team_size) {
      throw createError('Team is already full');
    }

    await client.query(
      `UPDATE team_invites SET status = 'accepted' WHERE id = $1`,
      [inviteId]
    );

    await client.query(
      `INSERT INTO team_members (team_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [invite.team_id, userId]
    );

    await client.query('COMMIT');

    const teamResult = await dbPool.query(
      `SELECT id, contest_id, name, leader_id, created_at
       FROM teams WHERE id = $1`,
      [invite.team_id]
    );

    return { team: teamResult.rows[0] };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getMyTeam(contestId, userId) {
  const teamResult = await dbPool.query(
    `SELECT t.id, t.contest_id, t.name, t.leader_id, t.created_at
     FROM teams t
     JOIN team_members tm ON tm.team_id = t.id
     WHERE t.contest_id = $1 AND tm.user_id = $2
     LIMIT 1`,
    [contestId, userId]
  );

  if (teamResult.rows.length === 0) {
    return null;
  }

  const team = teamResult.rows[0];
  const membersResult = await dbPool.query(
    `SELECT tm.user_id, u.username, tm.joined_at
     FROM team_members tm
     JOIN users u ON u.id = tm.user_id
     WHERE tm.team_id = $1
     ORDER BY tm.joined_at ASC`,
    [team.id]
  );

  return {
    ...team,
    members: membersResult.rows,
  };
}

export async function getMyInvites(userId) {
  const result = await dbPool.query(
    `SELECT ti.id,
            ti.team_id,
            ti.status,
            ti.expires_at,
            t.name AS team_name,
            c.title AS contest_title,
            u.username AS leader_username
     FROM team_invites ti
     JOIN teams t ON t.id = ti.team_id
     JOIN contests c ON c.id = t.contest_id
     JOIN users u ON u.id = t.leader_id
     WHERE ti.invitee_id = $1
       AND ti.status = 'pending'
       AND ti.expires_at > NOW()
     ORDER BY ti.created_at DESC`,
    [userId]
  );

  return result.rows;
}
