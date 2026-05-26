import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';

const router = Router();
const allowedCodeStubKeys = new Set(['cpp', 'python', 'java', 'javascript']);

function validateCodeStubs(raw) {
  if (raw === undefined) {
    return { value: null, error: null };
  }

  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    return { value: null, error: 'code_stubs must be an object' };
  }

  for (const [key, value] of Object.entries(raw)) {
    if (!allowedCodeStubKeys.has(key)) {
      return { value: null, error: `Invalid language key in code_stubs: ${key}` };
    }
    if (typeof value !== 'string') {
      return { value: null, error: `code_stubs.${key} must be a string` };
    }
  }

  return { value: raw, error: null };
}

function parseListField(value) {
  if (Array.isArray(value)) return value.map((v) => String(v));
  if (typeof value !== 'string') return [];

  const trimmed = value.trim();
  if (!trimmed) return [];

  try {
    const parsed = JSON.parse(trimmed);
    if (Array.isArray(parsed)) return parsed.map((v) => String(v));
  } catch (_) {
    // Ignore JSON parse errors; fallback to line/comma split.
  }

  if (trimmed.includes('\n')) {
    return trimmed
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 0);
  }

  if (trimmed.includes(',')) {
    return trimmed
      .split(',')
      .map((part) => part.trim())
      .filter((part) => part.length > 0);
  }

  return [trimmed];
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { difficulty, tag, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const columnsResult = await dbPool.query(
      `SELECT column_name
       FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'problems'`
    );
    const problemColumns = new Set(columnsResult.rows.map((row) => row.column_name));
    const baseCols = ['id', 'title', 'description', 'difficulty', 'tags', 'is_active', 'created_at'];
    const selectedCols = problemColumns.has('code_stubs')
      ? [...baseCols, 'code_stubs']
      : baseCols;

    let query = `SELECT ${selectedCols.join(', ')} FROM problems WHERE is_active = true AND visibility = 'public'`;
    const params = [];

    if (difficulty) {
      query += ` AND difficulty = $${params.length + 1}`;
      params.push(difficulty);
    }

    if (tag) {
      query += ` AND $${params.length + 1} = ANY(tags)`;
      params.push(tag);
    }

    if (search) {
      query += ` AND (title ILIKE $${params.length + 1} OR description ILIKE $${params.length + 2})`;
      params.push(`%${search}%`);
      params.push(`%${search}%`);
    }

    query += ' ORDER BY created_at DESC LIMIT $' + (params.length + 1) + ' OFFSET $' + (params.length + 2);
    params.push(parseInt(limit));
    params.push(offset);

    const result = await dbPool.query(query, params);

    const countResult = await dbPool.query(
      "SELECT COUNT(*) as total FROM problems WHERE is_active = true AND visibility = 'public'"
    );

    res.json({
      problems: result.rows,
      total: parseInt(countResult.rows[0].total),
      page: parseInt(page),
      limit: parseInt(limit),
    });
  } catch (error) {
    console.error('Get problems error:', error);
    res.status(500).json({ error: 'Failed to fetch problems', code: 'FETCH_ERROR' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const isAdmin = req.user?.role === 'admin';

    const [problemColumnsResult, testCaseColumnsResult] = await Promise.all([
      dbPool.query(
        `SELECT column_name
         FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'problems'`
      ),
      dbPool.query(
        `SELECT column_name
         FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'test_cases'`
      ),
    ]);

    const problemColumns = new Set(problemColumnsResult.rows.map((row) => row.column_name));
    const testCaseColumns = new Set(testCaseColumnsResult.rows.map((row) => row.column_name));

    const baseProblemCols = ['id', 'title', 'description', 'difficulty', 'tags', 'is_active', 'created_at'];
    const optionalProblemCols = ['constraints', 'input_format', 'topics', 'companies', 'hint', 'code_stubs'];
    const selectedProblemCols = [
      ...baseProblemCols,
      ...optionalProblemCols.filter((col) => problemColumns.has(col)),
    ];

    const problemResult = await dbPool.query(
      `SELECT ${selectedProblemCols.join(', ')}
       FROM problems
       WHERE id = $1 AND is_active = true`,
      [id]
    );

    if (problemResult.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found', code: 'NOT_FOUND' });
    }

    const testCaseSelectCols = ['id', 'input', 'expected_output'];
    if (testCaseColumns.has('explanation')) testCaseSelectCols.push('explanation');
    if (testCaseColumns.has('is_hidden')) testCaseSelectCols.push('is_hidden');

    const testCasesResult = await dbPool.query(
      `SELECT ${testCaseSelectCols.join(', ')}
       FROM test_cases
       WHERE problem_id = $1
       ORDER BY id ASC`,
      [id]
    );

    const problem = problemResult.rows[0];
    const inputFormat = parseListField(problem.input_format);
    const constraints = parseListField(problem.constraints);

    const examples = [];
    const hiddenTestCases = [];

    for (const testCase of testCasesResult.rows) {
      const normalized = {
        id: String(testCase.id),
        input: testCase.input,
        expected_output: testCase.expected_output,
        explanation: testCase.explanation ?? null,
      };

      const isHidden = testCaseColumns.has('is_hidden') ? testCase.is_hidden === true : false;
      if (isHidden) {
        hiddenTestCases.push(normalized);
      } else {
        examples.push(normalized);
      }
    }

    const responseBody = {
      ...problem,
      constraints,
      input_format: inputFormat,
      examples,
    };

    if (isAdmin) {
      responseBody.hidden_testcases = hiddenTestCases;
      responseBody.hidden_count = hiddenTestCases.length;
    }

    return res.json(responseBody);
  } catch (error) {
    console.error('Get problem error:', error);
    return res.status(500).json({ error: 'Failed to fetch problem', code: 'FETCH_ERROR' });
  }
});

router.post('/', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const {
      title,
      description,
      difficulty,
      tags,
      testCases,
      constraints,
      input_format,
      visibility: visibilityRaw,
      contest_id: contestIdRaw,
      code_stubs: codeStubsRaw,
    } = req.body;

    const { value: codeStubs, error: codeStubError } = validateCodeStubs(codeStubsRaw);
    if (codeStubError) {
      return res.status(400).json({ error: codeStubError, code: 'INVALID_INPUT' });
    }

    if (!title || !description || !difficulty) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const visibility = visibilityRaw || 'public';
    if (!['public', 'contest_only'].includes(visibility)) {
      return res.status(400).json({ error: 'Invalid visibility', code: 'INVALID_INPUT' });
    }

    const contestId = contestIdRaw ?? null;

    if (contestId !== null && visibility === 'contest_only') {
      const contestCheck = await dbPool.query('SELECT id FROM contests WHERE id = $1', [contestId]);
      if (contestCheck.rows.length === 0) {
        return res.status(400).json({ error: 'Contest not found', code: 'INVALID_INPUT' });
      }
    }

    const client = await dbPool.connect();

    try {
      await client.query('BEGIN');

      const problemColumnsResult = await client.query(
        `SELECT column_name
         FROM information_schema.columns
         WHERE table_schema = 'public' AND table_name = 'problems'`
      );
      const problemColumns = new Set(problemColumnsResult.rows.map((row) => row.column_name));

      const insertCols = ['title', 'description', 'difficulty', 'tags', 'created_by'];
      const insertValues = [title, description, difficulty, tags || [], req.user.firebase_uid];

      if (problemColumns.has('visibility')) {
        insertCols.push('visibility');
        insertValues.push(visibility);
      }

      if (problemColumns.has('contest_id')) {
        insertCols.push('contest_id');
        insertValues.push(contestId);
      }

      if (problemColumns.has('constraints')) {
        insertCols.push('constraints');
        insertValues.push(Array.isArray(constraints) ? constraints : []);
      }
      if (problemColumns.has('input_format')) {
        insertCols.push('input_format');
        insertValues.push(Array.isArray(input_format) ? input_format : []);
      }
      if (problemColumns.has('code_stubs')) {
        insertCols.push('code_stubs');
        insertValues.push(JSON.stringify(codeStubs ?? {}));
      }

      const placeholders = insertCols
        .map((col, idx) => (col === 'code_stubs' ? `$${idx + 1}::jsonb` : `$${idx + 1}`))
        .join(', ');

      const problemResult = await client.query(
        `INSERT INTO problems (${insertCols.join(', ')}) VALUES (${placeholders}) RETURNING id`,
        insertValues
      );

      const problemId = problemResult.rows[0].id;

      if (Array.isArray(testCases) && testCases.length > 0) {
        for (const tc of testCases) {
          await client.query(
            `INSERT INTO test_cases (problem_id, input, expected_output, explanation, is_hidden)
             VALUES ($1, $2, $3, $4, $5)`,
            [
              problemId,
              tc.input,
              tc.expected_output,
              tc.explanation ?? null,
              tc.is_hidden === true,
            ]
          );
        }
      }

      await client.query('COMMIT');

      return res.status(201).json({
        id: problemId,
        title,
        description,
        difficulty,
        tags,
      });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Create problem error:', error);
    return res.status(500).json({ error: 'Failed to create problem', code: 'CREATE_ERROR' });
  }
});

router.put('/:id', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      difficulty,
      tags,
      is_active,
      constraints,
      input_format,
      visibility: visibilityRaw,
      contest_id: contestIdRaw,
      code_stubs: codeStubsRaw,
    } = req.body;

    const { value: codeStubs, error: codeStubError } = validateCodeStubs(codeStubsRaw);
    if (codeStubError) {
      return res.status(400).json({ error: codeStubError, code: 'INVALID_INPUT' });
    }

    const problemColumnsResult = await dbPool.query(
      `SELECT column_name
       FROM information_schema.columns
       WHERE table_schema = 'public' AND table_name = 'problems'`
    );
    const problemColumns = new Set(problemColumnsResult.rows.map((row) => row.column_name));

    const updates = [];
    const params = [];
    let paramCount = 1;

    if (visibilityRaw !== undefined && problemColumns.has('visibility')) {
      if (!['public', 'contest_only'].includes(visibilityRaw)) {
        return res.status(400).json({ error: 'Invalid visibility', code: 'INVALID_INPUT' });
      }
      updates.push(`visibility = $${paramCount++}`);
      params.push(visibilityRaw);
    }

    if (contestIdRaw !== undefined && problemColumns.has('contest_id')) {
      if (contestIdRaw !== null) {
        const contestCheck = await dbPool.query('SELECT id FROM contests WHERE id = $1', [contestIdRaw]);
        if (contestCheck.rows.length === 0) {
          return res.status(400).json({ error: 'Contest not found', code: 'INVALID_INPUT' });
        }
      }
      updates.push(`contest_id = $${paramCount++}`);
      params.push(contestIdRaw);
    }

    if (title !== undefined) {
      updates.push(`title = $${paramCount++}`);
      params.push(title);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramCount++}`);
      params.push(description);
    }
    if (difficulty !== undefined) {
      updates.push(`difficulty = $${paramCount++}`);
      params.push(difficulty);
    }
    if (tags !== undefined) {
      updates.push(`tags = $${paramCount++}`);
      params.push(tags);
    }
    if (is_active !== undefined) {
      updates.push(`is_active = $${paramCount++}`);
      params.push(is_active);
    }
    if (constraints !== undefined && problemColumns.has('constraints')) {
      updates.push(`constraints = $${paramCount++}`);
      params.push(Array.isArray(constraints) ? constraints : []);
    }
    if (input_format !== undefined && problemColumns.has('input_format')) {
      updates.push(`input_format = $${paramCount++}`);
      params.push(Array.isArray(input_format) ? input_format : []);
    }
    if (codeStubs !== null && problemColumns.has('code_stubs')) {
      updates.push(`code_stubs = $${paramCount++}::jsonb`);
      params.push(JSON.stringify(codeStubs));
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update', code: 'INVALID_INPUT' });
    }

    params.push(id);

    const result = await dbPool.query(
      `UPDATE problems SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`,
      params
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found', code: 'NOT_FOUND' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Update problem error:', error);
    return res.status(500).json({ error: 'Failed to update problem', code: 'UPDATE_ERROR' });
  }
});

export default router;
