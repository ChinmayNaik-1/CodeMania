import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';
import * as contestService from '../services/contestService.js';

const router = Router();

router.use(authMiddleware, requireAdmin);

router.delete('/problems/:problemId', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    if (Number.isNaN(problemId)) {
      return res.status(400).json({ error: 'Invalid problemId', code: 'INVALID_INPUT' });
    }
    
    await dbPool.query('DELETE FROM problems WHERE id = $1', [problemId]);
    return res.json({ success: true });
  } catch (error) {
    console.error('Delete problem error:', error);
    return res.status(500).json({ error: 'Failed to delete problem', code: 'ADMIN_PROBLEM_DELETE_ERROR' });
  }
});

router.post('/problems/:problemId/driver', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const { language, driver_prefix: driverPrefix, driver_suffix: driverSuffix } = req.body;

    if (Number.isNaN(problemId) || !language || driverPrefix === undefined || driverSuffix === undefined) {
      return res.status(400).json({
        error: 'problemId, language, driver_prefix and driver_suffix are required',
        code: 'INVALID_INPUT',
      });
    }

    await dbPool.query(
      `INSERT INTO driver_code (problem_id, language, driver_prefix, driver_suffix)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (problem_id, language)
       DO UPDATE SET driver_prefix = EXCLUDED.driver_prefix,
                     driver_suffix = EXCLUDED.driver_suffix,
                     updated_at = NOW()`,
      [problemId, language, driverPrefix ?? '', driverSuffix ?? '']
    );

    return res.json({
      success: true,
      language,
      driver_prefix: driverPrefix ?? '',
      driver_suffix: driverSuffix ?? '',
    });
  } catch (error) {
    console.error('Upsert driver code error:', error);
    return res.status(500).json({ error: 'Failed to save driver code', code: 'ADMIN_DRIVER_UPSERT_ERROR' });
  }
});

router.get('/problems/:problemId/drivers', async (req, res) => {
  console.log(`[DEBUG] GET /problems/${req.params.problemId}/drivers hit by user ${req.user?.id}`);
  try {
    const problemId = parseInt(req.params.problemId, 10);
    if (Number.isNaN(problemId)) {
      return res.status(400).json({ error: 'Invalid problemId', code: 'INVALID_INPUT' });
    }

    const result = await dbPool.query(
      `SELECT language, driver_prefix, driver_suffix
       FROM driver_code
       WHERE problem_id = $1
       ORDER BY language ASC`,
      [problemId]
    );

    return res.json({ drivers: result.rows });
  } catch (error) {
    console.error('Get driver codes error:', error);
    return res.status(500).json({ error: 'Failed to fetch driver code list', code: 'ADMIN_DRIVER_LIST_ERROR' });
  }
});

router.get('/problems/:problemId/driver/:language', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const { language } = req.params;

    if (Number.isNaN(problemId) || !language) {
      return res.status(400).json({ error: 'Invalid problemId or language', code: 'INVALID_INPUT' });
    }

    const result = await dbPool.query(
      `SELECT language, driver_prefix, driver_suffix
       FROM driver_code
       WHERE problem_id = $1 AND language = $2
       LIMIT 1`,
      [problemId, language]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No driver found for this language' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Get driver code error:', error);
    return res.status(500).json({ error: 'Failed to fetch driver code', code: 'ADMIN_DRIVER_GET_ERROR' });
  }
});

router.delete('/problems/:problemId/driver/:language', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const { language } = req.params;

    if (Number.isNaN(problemId) || !language) {
      return res.status(400).json({ error: 'Invalid problemId or language', code: 'INVALID_INPUT' });
    }

    await dbPool.query(
      'DELETE FROM driver_code WHERE problem_id = $1 AND language = $2',
      [problemId, language]
    );

    return res.json({ success: true });
  } catch (error) {
    console.error('Delete driver code error:', error);
    return res.status(500).json({ error: 'Failed to delete driver code', code: 'ADMIN_DRIVER_DELETE_ERROR' });
  }
});

router.get('/problems/:problemId/testcases', async (req, res) => {
  console.log(`[DEBUG] GET /problems/${req.params.problemId}/testcases hit by user ${req.user?.id}`);
  try {
    const problemId = parseInt(req.params.problemId, 10);
    if (Number.isNaN(problemId)) {
      return res.status(400).json({ error: 'Invalid problemId', code: 'INVALID_INPUT' });
    }

    const result = await dbPool.query(
      `SELECT id, input, expected_output, explanation, image_url, is_hidden
       FROM test_cases
       WHERE problem_id = $1
       ORDER BY is_hidden ASC, id ASC`,
      [problemId]
    );

    return res.json(result.rows);
  } catch (error) {
    console.error('Get admin testcases error:', error);
    return res.status(500).json({ error: 'Failed to fetch test cases', code: 'ADMIN_TESTCASE_LIST_ERROR' });
  }
});

router.post('/problems/:problemId/testcases', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const {
      input,
      expected_output: expectedOutput,
      explanation,
      image_url: imageUrl,
      is_hidden: isHidden,
    } = req.body;

    if (Number.isNaN(problemId) || !input || !expectedOutput) {
      return res.status(400).json({
        error: 'problemId, input and expected_output are required',
        code: 'INVALID_INPUT',
      });
    }

    const result = await dbPool.query(
      `INSERT INTO test_cases (problem_id, input, expected_output, explanation, image_url, is_hidden)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, input, expected_output, explanation, image_url, is_hidden`,
      [problemId, input, expectedOutput, explanation ?? null, imageUrl ?? null, isHidden === true]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Create admin testcase error:', error);
    return res.status(500).json({ error: 'Failed to create test case', code: 'ADMIN_TESTCASE_CREATE_ERROR' });
  }
});

router.put('/problems/:problemId/testcases/:testcaseId', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const testcaseId = parseInt(req.params.testcaseId, 10);
    const {
      input,
      expected_output: expectedOutput,
      explanation,
      image_url: imageUrl,
      is_hidden: isHidden,
    } = req.body;

    if (Number.isNaN(problemId) || Number.isNaN(testcaseId)) {
      return res.status(400).json({ error: 'Invalid problemId or testcaseId', code: 'INVALID_INPUT' });
    }

    const updates = [];
    const params = [];
    let paramCount = 1;

    if (input !== undefined) {
      updates.push(`input = $${paramCount++}`);
      params.push(input);
    }
    if (expectedOutput !== undefined) {
      updates.push(`expected_output = $${paramCount++}`);
      params.push(expectedOutput);
    }
    if (explanation !== undefined) {
      updates.push(`explanation = $${paramCount++}`);
      params.push(explanation);
    }
    if (imageUrl !== undefined) {
      updates.push(`image_url = $${paramCount++}`);
      params.push(imageUrl);
    }
    if (isHidden !== undefined) {
      updates.push(`is_hidden = $${paramCount++}`);
      params.push(isHidden === true);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update', code: 'INVALID_INPUT' });
    }

    params.push(testcaseId, problemId);

    const result = await dbPool.query(
      `UPDATE test_cases
       SET ${updates.join(', ')}
       WHERE id = $${paramCount++} AND problem_id = $${paramCount}
       RETURNING id, input, expected_output, explanation, image_url, is_hidden`,
      params
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Test case not found', code: 'NOT_FOUND' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Update admin testcase error:', error);
    return res.status(500).json({ error: 'Failed to update test case', code: 'ADMIN_TESTCASE_UPDATE_ERROR' });
  }
});

router.delete('/problems/:problemId/testcases/:testcaseId', async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    const testcaseId = parseInt(req.params.testcaseId, 10);

    if (Number.isNaN(problemId) || Number.isNaN(testcaseId)) {
      return res.status(400).json({ error: 'Invalid problemId or testcaseId', code: 'INVALID_INPUT' });
    }

    await dbPool.query(
      'DELETE FROM test_cases WHERE id = $1 AND problem_id = $2',
      [testcaseId, problemId]
    );

    return res.json({ success: true });
  } catch (error) {
    console.error('Delete admin testcase error:', error);
    return res.status(500).json({ error: 'Failed to delete test case', code: 'ADMIN_TESTCASE_DELETE_ERROR' });
  }
});

router.post('/contests', async (req, res) => {
  try {
    const contest = await contestService.createContest(req.body, req.user.id);
    return res.status(201).json({ contest });
  } catch (error) {
    const status = error.status || 500;
    const message = error.status ? error.message : 'Failed to create contest';
    console.error('Create contest error:', error);
    return res.status(status).json({ error: message });
  }
});

router.patch('/contests/:contestId/status', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    const { status } = req.body;

    if (Number.isNaN(contestId)) {
      return res.status(400).json({ error: 'Invalid contest id' });
    }

    const result = await contestService.updateContestStatus(contestId, status);
    return res.json(result);
  } catch (error) {
    const statusCode = error.status || 500;
    const message = error.status ? error.message : 'Failed to update contest status';
    console.error('Update contest status error:', error);
    return res.status(statusCode).json({ error: message });
  }
});

router.post('/contests/:contestId/problems', async (req, res) => {
  try {
    const contestId = parseInt(req.params.contestId, 10);
    const problemId = parseInt(req.body.problemId, 10);

    if (Number.isNaN(contestId) || Number.isNaN(problemId)) {
      return res.status(400).json({ error: 'contestId and problemId are required' });
    }

    const contestResult = await dbPool.query(
      'SELECT id FROM contests WHERE id = $1',
      [contestId]
    );
    if (contestResult.rows.length === 0) {
      return res.status(404).json({ error: 'Contest not found' });
    }

    const problemResult = await dbPool.query(
      `SELECT id
       FROM problems
       WHERE id = $1 AND visibility = 'public'`,
      [problemId]
    );
    if (problemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found or not public' });
    }

    const existingResult = await dbPool.query(
      'SELECT 1 FROM contest_problems WHERE contest_id = $1 AND problem_id = $2',
      [contestId, problemId]
    );
    if (existingResult.rows.length > 0) {
      return res.status(409).json({ error: 'Problem already added to contest' });
    }

    await dbPool.query(
      `INSERT INTO contest_problems (contest_id, problem_id, order_index)
       VALUES ($1, $2,
         (SELECT COALESCE(MAX(order_index), 0) + 1
          FROM contest_problems WHERE contest_id = $1)
       )`,
      [contestId, problemId]
    );

    return res.status(201).json({ message: 'Problem added' });
  } catch (error) {
    console.error('Add contest problem error:', error);
    return res.status(500).json({ error: 'Failed to add problem to contest' });
  }
});

export default router;
