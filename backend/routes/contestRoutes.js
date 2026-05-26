import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';
import { getLeaderboard } from '../services/leaderboardService.js';

const router = Router();

function generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const result = await dbPool.query(
      `SELECT c.id, c.title, c.description, c.start_time, c.end_time, c.status, c.created_at 
       FROM contests c 
       ORDER BY c.start_time DESC`
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Get contests error:', error);
    res.status(500).json({ error: 'Failed to fetch contests', code: 'FETCH_ERROR' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    const contestResult = await dbPool.query(
      `SELECT id, title, description, start_time, end_time, status FROM contests WHERE id = $1`,
      [id]
    );

    if (contestResult.rows.length === 0) {
      return res.status(404).json({ error: 'Contest not found', code: 'NOT_FOUND' });
    }

    const problemsResult = await dbPool.query(
      `SELECT p.id, p.title, p.difficulty, cp.points, cp.problem_order 
       FROM contest_problems cp 
       JOIN problems p ON cp.problem_id = p.id 
       WHERE cp.contest_id = $1 
       ORDER BY cp.problem_order ASC`,
      [id]
    );

    const teamsResult = await dbPool.query(
      `SELECT t.id, t.name, t.join_code FROM teams WHERE contest_id = $1 ORDER BY t.created_at`,
      [id]
    );

    res.json({
      ...contestResult.rows[0],
      problems: problemsResult.rows,
      teams: teamsResult.rows,
    });
  } catch (error) {
    console.error('Get contest error:', error);
    res.status(500).json({ error: 'Failed to fetch contest', code: 'FETCH_ERROR' });
  }
});

router.post('/', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { title, description, start_time, end_time, problems } = req.body;

    if (!title || !start_time || !end_time) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const client = await dbPool.connect();

    try {
      await client.query('BEGIN');

      const contestResult = await client.query(
        'INSERT INTO contests (title, description, start_time, end_time, created_by) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [title, description, start_time, end_time, req.user.firebase_uid]
      );

      const contestId = contestResult.rows[0].id;

      if (problems && problems.length > 0) {
        for (let i = 0; i < problems.length; i++) {
          await client.query(
            'INSERT INTO contest_problems (contest_id, problem_id, points, problem_order) VALUES ($1, $2, $3, $4)',
            [contestId, problems[i].problemId, problems[i].points || 100, i + 1]
          );
        }
      }

      await client.query('COMMIT');

      res.status(201).json({
        id: contestId,
        title,
        description,
        start_time,
        end_time,
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Create contest error:', error);
    res.status(500).json({ error: 'Failed to create contest', code: 'CREATE_ERROR' });
  }
});

router.post('/:id/teams', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { teamName } = req.body;

    if (!teamName) {
      return res.status(400).json({ error: 'Team name required', code: 'INVALID_INPUT' });
    }

    const contestCheck = await dbPool.query('SELECT id FROM contests WHERE id = $1', [id]);
    if (contestCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Contest not found', code: 'NOT_FOUND' });
    }

    const joinCode = generateJoinCode();

    const result = await dbPool.query(
      'INSERT INTO teams (contest_id, name, join_code) VALUES ($1, $2, $3) RETURNING *',
      [id, teamName, joinCode]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create team error:', error);
    res.status(500).json({ error: 'Failed to create team', code: 'CREATE_ERROR' });
  }
});

router.post('/:id/join', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { joinCode } = req.body;

    if (!joinCode) {
      return res.status(400).json({ error: 'Join code required', code: 'INVALID_INPUT' });
    }

    const teamResult = await dbPool.query(
      'SELECT id, contest_id FROM teams WHERE join_code = $1 AND contest_id = $2',
      [joinCode, id]
    );

    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Invalid join code', code: 'NOT_FOUND' });
    }

    const teamId = teamResult.rows[0].id;

    const existingMember = await dbPool.query(
      'SELECT * FROM team_members WHERE team_id = $1 AND user_id = $2',
      [teamId, req.user.firebase_uid]
    );

    if (existingMember.rows.length > 0) {
      return res.status(400).json({ error: 'Already a team member', code: 'DUPLICATE' });
    }

    const result = await dbPool.query(
      'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2) RETURNING *',
      [teamId, req.user.firebase_uid]
    );

    res.status(201).json({
      teamId,
      userId: req.user.firebase_uid,
      joinedAt: result.rows[0].joined_at,
    });
  } catch (error) {
    console.error('Join team error:', error);
    res.status(500).json({ error: 'Failed to join team', code: 'JOIN_ERROR' });
  }
});

router.get('/:id/leaderboard', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const leaderboard = await getLeaderboard(id);

    const teamsData = await Promise.all(
      leaderboard.map(async (item) => {
        const teamResult = await dbPool.query(
          'SELECT name FROM teams WHERE id = $1',
          [item.teamId]
        );

        const membersResult = await dbPool.query(
          'SELECT u.username FROM team_members tm JOIN users u ON tm.user_id = u.firebase_uid WHERE tm.team_id = $1',
          [item.teamId]
        );

        return {
          teamId: item.teamId,
          teamName: teamResult.rows[0]?.name || 'Unknown Team',
          score: item.score,
          members: membersResult.rows.map((r) => r.username),
        };
      })
    );

    res.json({ teams: teamsData, timestamp: new Date() });
  } catch (error) {
    console.error('Get leaderboard error:', error);
    res.status(500).json({ error: 'Failed to fetch leaderboard', code: 'FETCH_ERROR' });
  }
});

export default router;
