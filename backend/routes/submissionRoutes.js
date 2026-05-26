import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { dbPool } from '../index.js';
import { fetchPistonRuntimes, runAgainstSampleTestCases } from '../services/judgeService.js';
import { submissionQueue } from '../services/submissionQueue.js';

let io;

export function setSocketIo(socketIo) {
  io = socketIo;
}

const router = Router();

router.post('/', authMiddleware, async (req, res) => {
  try {
    const { problemId, contestId, teamId, language, version, code } = req.body;

    if (!problemId || !language || !version || !code) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const insertResult = await dbPool.query(
      `INSERT INTO submissions 
       (user_id, problem_id, contest_id, team_id, language, language_version, code, verdict, passed_cases, total_cases, time_ms, memory_kb) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
       RETURNING id`,
      [req.user.id, problemId, contestId || null, teamId || null, language, version, code, 'pending', 0, 0, 0, 0]
    );

    const submissionId = insertResult.rows[0].id;

    await submissionQueue.add({
      submissionId,
      userId: req.user.id,
      username: req.user.username,
      problemId,
      contestId: contestId || null,
      teamId: teamId || null,
      language,
      version,
      code,
    });

    res.status(202).json({
      submissionId,
      status: 'queued',
    });
  } catch (error) {
    console.error('Submit error:', error);
    res.status(500).json({ error: 'Failed to submit code', code: 'SUBMIT_ERROR' });
  }
});

router.get('/runtimes', async (req, res) => {
  try {
    const forceRefresh = String(req.query.refresh || '').toLowerCase() == 'true';
    const runtimes = await fetchPistonRuntimes({ forceRefresh });
    res.json({ runtimes });
  } catch (error) {
    console.error('Runtime fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch runtimes', code: 'RUNTIME_FETCH_ERROR' });
  }
});

router.post('/run', authMiddleware, async (req, res) => {
  try {
    const { problemId, language, version, code } = req.body;

    if (!problemId || !language || !version || !code) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const results = await runAgainstSampleTestCases(code, language, version, problemId, dbPool);

    const firstError = results.find((r) => r.passed === false && r.error);

    res.json({
      results,
      run_error: firstError?.error || null,
      run_error_type: firstError?.errorType || null,
    });
  } catch (error) {
    console.error('Run error:', error);
    res.status(500).json({ error: 'Failed to run code', code: 'RUN_ERROR' });
  }
});

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { userId, problemId, contestId, page = 1 } = req.query;
    const limit = 20;
    const offset = (parseInt(page) - 1) * limit;

    let query = 'SELECT id, user_id, problem_id, verdict, language, passed_cases, total_cases, created_at FROM submissions WHERE 1=1';
    const params = [];

    if (userId) {
      query += ` AND user_id = $${params.length + 1}`;
      params.push(userId);
    }

    if (problemId) {
      query += ` AND problem_id = $${params.length + 1}`;
      params.push(problemId);
    }

    if (contestId) {
      query += ` AND contest_id = $${params.length + 1}`;
      params.push(contestId);
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit);
    params.push(offset);

    const result = await dbPool.query(query, params);

    res.json({
      submissions: result.rows,
      page: parseInt(page),
      limit,
    });
  } catch (error) {
    console.error('Get submissions error:', error);
    res.status(500).json({ error: 'Failed to fetch submissions', code: 'FETCH_ERROR' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const submissionId = parseInt(req.params.id, 10);
    if (Number.isNaN(submissionId)) {
      return res.status(400).json({ error: 'Invalid submission id', code: 'INVALID_INPUT' });
    }

    const query = req.user.role === 'admin'
      ? `SELECT id, user_id, problem_id, contest_id, team_id, verdict, passed_cases, total_cases, time_ms, memory_kb, language, language_version, created_at
         FROM submissions
         WHERE id = $1`
      : `SELECT id, user_id, problem_id, contest_id, team_id, verdict, passed_cases, total_cases, time_ms, memory_kb, language, language_version, created_at
         FROM submissions
         WHERE id = $1 AND user_id = $2`;

    const params = req.user.role === 'admin'
      ? [submissionId]
      : [submissionId, req.user.id];

    const result = await dbPool.query(query, params);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Submission not found', code: 'NOT_FOUND' });
    }

    res.json({ submission: result.rows[0] });
  } catch (error) {
    console.error('Get submission by id error:', error);
    res.status(500).json({ error: 'Failed to fetch submission', code: 'FETCH_ERROR' });
  }
});

export default router;
