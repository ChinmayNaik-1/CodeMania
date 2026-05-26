import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';

const router = Router();

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

function parseInputMap(inputText = '', inputFormat = []) {
  const lines = String(inputText)
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  if (lines.length === 0) return {};

  const parsed = {};
  let hasNamedInputs = false;

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const separator = line.indexOf('=');
    if (separator > 0) {
      const key = line.slice(0, separator).trim();
      const value = line.slice(separator + 1).trim();
      if (key.length > 0) {
        parsed[key] = value;
        hasNamedInputs = true;
      }
    }
  }

  if (!hasNamedInputs) {
    if (Array.isArray(inputFormat) && inputFormat.length > 0) {
      for (let i = 0; i < inputFormat.length; i += 1) {
        parsed[inputFormat[i]] = i < lines.length ? lines[i] : '';
      }
    } else {
      for (let i = 0; i < lines.length; i += 1) {
        parsed[`input${i + 1}`] = lines[i];
      }
    }
  }

  return parsed;
}

function normalizeInputMapOrder(inputMap, inputFormat) {
  if (!Array.isArray(inputFormat) || inputFormat.length === 0) {
    return inputMap;
  }

  const ordered = {};
  for (const key of inputFormat) {
    ordered[key] = Object.prototype.hasOwnProperty.call(inputMap, key) ? inputMap[key] : '';
  }

  for (const [key, value] of Object.entries(inputMap)) {
    if (!Object.prototype.hasOwnProperty.call(ordered, key)) {
      ordered[key] = value;
    }
  }

  return ordered;
}

router.get('/', authMiddleware, async (req, res) => {
  try {
    const { difficulty, tag, search, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let query = 'SELECT id, title, description, difficulty, tags, is_active, created_at FROM problems WHERE is_active = true';
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

    const totalQuery = 'SELECT COUNT(*) FROM problems WHERE is_active = true ' +
      (difficulty ? 'AND difficulty = $1' : '') +
      (tag ? ` AND $${difficulty ? 2 : 1} = ANY(tags)` : '') +
      (search ? ` AND (title ILIKE $${(difficulty ? 2 : 1) + (tag ? 1 : 0)} OR description ILIKE $${(difficulty ? 2 : 1) + (tag ? 1 : 0) + 1})` : '');

    const countResult = await dbPool.query(
      'SELECT COUNT(*) as total FROM problems WHERE is_active = true'
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
    const optionalProblemCols = ['constraints', 'input_format', 'topics', 'companies', 'hint'];
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
    if (testCaseColumns.has('is_sample')) testCaseSelectCols.push('is_sample');
    if (testCaseColumns.has('explanation')) testCaseSelectCols.push('explanation');

    const testCasesResult = await dbPool.query(
      `SELECT ${testCaseSelectCols.join(', ')}
       FROM test_cases
       WHERE problem_id = $1 ${testCaseColumns.has('is_sample') ? 'AND is_sample = true' : ''}
       ORDER BY id ASC`,
      [id]
    );

    const problem = problemResult.rows[0];

    const inputFormat = parseListField(problem.input_format);
    const constraints = parseListField(problem.constraints);

    const testCases = testCasesResult.rows.map((testCase) => {
      const parsedInputs = parseInputMap(testCase.input, inputFormat);
      const orderedInputs = normalizeInputMapOrder(parsedInputs, inputFormat);

      return {
        id: String(testCase.id),
        inputs: orderedInputs,
        expected_output: testCase.expected_output,
        explanation: testCase.explanation ?? null,
      };
    });

    const normalizedInputFormat = inputFormat.length > 0
      ? inputFormat
      : (testCases.length > 0 ? Object.keys(testCases[0].inputs) : []);

    res.json({
      ...problem,
      constraints,
      input_format: normalizedInputFormat,
      test_cases: testCases,
      sample_test_cases: testCasesResult.rows,
    });
  } catch (error) {
    console.error('Get problem error:', error);
    res.status(500).json({ error: 'Failed to fetch problem', code: 'FETCH_ERROR' });
  }
});

router.post('/', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { title, description, difficulty, tags, testCases } = req.body;

    if (!title || !description || !difficulty) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const client = await dbPool.connect();

    try {
      await client.query('BEGIN');

      const problemResult = await client.query(
        'INSERT INTO problems (title, description, difficulty, tags, created_by) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [title, description, difficulty, tags || [], req.user.firebase_uid]
      );

      const problemId = problemResult.rows[0].id;

      if (testCases && testCases.length > 0) {
        for (const tc of testCases) {
          await client.query(
            'INSERT INTO test_cases (problem_id, input, expected_output, is_sample) VALUES ($1, $2, $3, $4)',
            [problemId, tc.input, tc.expected_output, tc.is_sample || false]
          );
        }
      }

      await client.query('COMMIT');

      res.status(201).json({
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
    res.status(500).json({ error: 'Failed to create problem', code: 'CREATE_ERROR' });
  }
});

router.put('/:id', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, difficulty, tags, is_active } = req.body;

    const updates = [];
    const params = [];
    let paramCount = 1;

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

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Update problem error:', error);
    res.status(500).json({ error: 'Failed to update problem', code: 'UPDATE_ERROR' });
  }
});

router.post('/:id/testcases', authMiddleware, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { input, expected_output, is_sample } = req.body;

    if (!input || !expected_output) {
      return res.status(400).json({ error: 'Missing input or expected_output', code: 'INVALID_INPUT' });
    }

    const problemCheck = await dbPool.query('SELECT id FROM problems WHERE id = $1', [id]);
    if (problemCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found', code: 'NOT_FOUND' });
    }

    const result = await dbPool.query(
      'INSERT INTO test_cases (problem_id, input, expected_output, is_sample) VALUES ($1, $2, $3, $4) RETURNING *',
      [id, input, expected_output, is_sample || false]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Add test case error:', error);
    res.status(500).json({ error: 'Failed to add test case', code: 'CREATE_ERROR' });
  }
});

export default router;
