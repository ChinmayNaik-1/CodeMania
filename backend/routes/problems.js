import { Router } from 'express';
import { authMiddleware, optionalAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { dbPool } from '../index.js';

const router = Router();
const allowedCodeStubKeys = new Set(['cpp', 'python', 'java', 'javascript']);

function validateCodeStubs(raw) {
  if (raw === undefined) {
    return { value: undefined, error: null };
  }

  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    return { value: undefined, error: 'code_stubs must be an object' };
  }

  for (const [key, value] of Object.entries(raw)) {
    if (!allowedCodeStubKeys.has(key)) {
      return { value: undefined, error: `Invalid language key in code_stubs: ${key}` };
    }
    if (typeof value !== 'string') {
      return { value: undefined, error: `code_stubs.${key} must be a string` };
    }
  }

  return { value: raw, error: null };
}

function validateStringArray(value, fieldName) {
  if (value === undefined) {
    return { value: undefined, error: null };
  }

  if (!Array.isArray(value)) {
    return { value: undefined, error: `${fieldName} must be an array of strings` };
  }

  return { value: value.map((item) => String(item)), error: null };
}

function normalizeProblemRow(row) {
  return {
    ...row,
    topics: row.topics ?? [],
    hints: row.hints ?? [],
    follow_up: row.follow_up ?? null,
    code_stubs: row.code_stubs ?? {},
  };
}

router.get('/', optionalAuth, async (req, res) => {
  try {
    const userId = req.user?.id || 0;

    const isAdmin = req.user?.role === 'admin';

    const result = await dbPool.query(
      `SELECT p.id,
              p.title,
              p.difficulty,
              p.topics,
              p.is_contest_exclusive,
              p.problem_number,
              EXISTS (
                SELECT 1
                FROM submissions s
                WHERE s.problem_id = p.id
                  AND s.user_id = $1
                  AND s.verdict = 'accepted'
              ) AS is_solved
       FROM problems p
       WHERE (p.is_contest_exclusive = false OR $2 = true)
       ORDER BY p.problem_number ASC`,
      [userId, isAdmin]
    );

    return res.json(result.rows.map((row) => ({
      ...row,
      topics: row.topics ?? [],
      is_contest_exclusive: row.is_contest_exclusive === true,
      problem_number: row.problem_number,
      is_solved: row.is_solved === true,
    })));
  } catch (error) {
    console.error('Get problems error:', error);
    return res.status(500).json({ error: 'Failed to fetch problems', code: 'FETCH_ERROR' });
  }
});

router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id || -1;
    const isAdmin = req.user?.role === 'admin';

    const result = await dbPool.query(
      `SELECT p.id,
              p.title,
              p.difficulty,
              p.description,
              p.topics,
              p.constraints,
              p.hints,
              p.follow_up,
              p.code_stubs,
              p.is_contest_exclusive,
              p.problem_number,
              EXISTS (
                SELECT 1
                FROM submissions s
                WHERE s.problem_id = p.id
                  AND s.user_id = $2
                  AND s.verdict = 'accepted'
              ) AS is_solved,
              COALESCE(
                (
                  SELECT json_agg(
                    json_build_object(
                      'id', t.id,
                      'input', t.input,
                      'expected_output', t.expected_output,
                      'explanation', t.explanation,
                      'image_url', t.image_url
                    )
                    ORDER BY t.id
                  )
                  FROM test_cases t
                  WHERE t.problem_id = p.id AND t.is_hidden = false
                ),
                '[]'::json
              ) AS examples,
              CASE WHEN $3
                THEN COALESCE(
                  (
                    SELECT json_agg(
                      json_build_object(
                        'id', t.id,
                        'input', t.input,
                        'expected_output', t.expected_output,
                        'explanation', t.explanation,
                        'image_url', t.image_url
                      )
                      ORDER BY t.id
                    )
                    FROM test_cases t
                    WHERE t.problem_id = p.id AND t.is_hidden = true
                  ),
                  '[]'::json
                )
                ELSE NULL
              END AS hidden_testcases
       FROM problems p
       WHERE p.id = $1`,
      [id, userId, isAdmin]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found', code: 'NOT_FOUND' });
    }

    const problem = normalizeProblemRow(result.rows[0]);

    return res.json({
      id: problem.id,
      title: problem.title,
      difficulty: problem.difficulty,
      description: problem.description,
      topics: problem.topics,
      constraints: problem.constraints,
      hints: problem.hints,
      follow_up: problem.follow_up,
      code_stubs: problem.code_stubs ?? {},
      is_contest_exclusive: problem.is_contest_exclusive === true,
      problem_number: problem.problem_number,
      is_solved: result.rows[0].is_solved === true,
      examples: problem.examples || [],
      hidden_testcases: problem.hidden_testcases ?? null,
    });
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
      topics,
      constraints,
      hints,
      follow_up: followUp,
      code_stubs: codeStubsRaw,
      testCases,
      is_contest_exclusive,
      problem_number,
    } = req.body;

    const normalizedDifficulty = typeof difficulty === 'string'
      ? difficulty.trim().toLowerCase()
      : difficulty;

    if (!title || !description || !normalizedDifficulty) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const { value: normalizedTopics, error: topicsError } = validateStringArray(topics, 'topics');
    if (topicsError) {
      return res.status(400).json({ error: topicsError, code: 'INVALID_INPUT' });
    }

    const { value: normalizedHints, error: hintsError } = validateStringArray(hints, 'hints');
    if (hintsError) {
      return res.status(400).json({ error: hintsError, code: 'INVALID_INPUT' });
    }

    const { value: codeStubs, error: codeStubError } = validateCodeStubs(codeStubsRaw);
    if (codeStubError) {
      return res.status(400).json({ error: codeStubError, code: 'INVALID_INPUT' });
    }

    if (testCases !== undefined && !Array.isArray(testCases)) {
      return res.status(400).json({ error: 'testCases must be an array', code: 'INVALID_INPUT' });
    }

    const client = await dbPool.connect();

    try {
      await client.query('BEGIN');

      let finalProblemNumber = problem_number;
      if (finalProblemNumber !== undefined) {
        // Validate uniqueness if provided
        const checkNum = await client.query('SELECT 1 FROM problems WHERE problem_number = $1', [finalProblemNumber]);
        if (checkNum.rows.length > 0) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: 'problem_number already exists', code: 'INVALID_INPUT' });
        }
      } else {
        const maxNumResult = await client.query('SELECT COALESCE(MAX(problem_number), 0) + 1 AS next_num FROM problems');
        finalProblemNumber = maxNumResult.rows[0].next_num;
      }

      const insertResult = await client.query(
        `INSERT INTO problems (
           title,
           description,
           difficulty,
           topics,
           constraints,
           hints,
           follow_up,
           code_stubs,
           is_contest_exclusive,
           problem_number
         )
         VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8::jsonb, $9, $10)
         RETURNING id, title, description, difficulty, topics, constraints, hints, follow_up, code_stubs, is_contest_exclusive, problem_number`,
        [
          title,
          description,
          normalizedDifficulty,
          normalizedTopics ?? [],
          constraints ?? null,
          JSON.stringify(normalizedHints ?? []),
          followUp ?? null,
          JSON.stringify(codeStubs ?? {}),
          is_contest_exclusive === true,
          finalProblemNumber,
        ]
      );

      const problem = insertResult.rows[0];

      if (Array.isArray(testCases) && testCases.length > 0) {
        for (const tc of testCases) {
          if (!tc?.input || !tc?.expected_output) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Each testCase needs input and expected_output', code: 'INVALID_INPUT' });
          }

          await client.query(
            `INSERT INTO test_cases (problem_id, input, expected_output, explanation, is_hidden, image_url)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [
              problem.id,
              tc.input,
              tc.expected_output,
              tc.explanation ?? null,
              tc.is_hidden === true,
              tc.image_url ?? null,
            ]
          );
        }
      }

      await client.query('COMMIT');

      return res.status(201).json(normalizeProblemRow(problem));
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
      topics,
      constraints,
      hints,
      follow_up: followUp,
      code_stubs: codeStubsRaw,
      is_contest_exclusive,
      problem_number,
    } = req.body;

    const normalizedDifficulty = typeof difficulty === 'string'
      ? difficulty.trim().toLowerCase()
      : difficulty;

    const { value: normalizedTopics, error: topicsError } = validateStringArray(topics, 'topics');
    if (topicsError) {
      return res.status(400).json({ error: topicsError, code: 'INVALID_INPUT' });
    }

    const { value: normalizedHints, error: hintsError } = validateStringArray(hints, 'hints');
    if (hintsError) {
      return res.status(400).json({ error: hintsError, code: 'INVALID_INPUT' });
    }

    const { value: codeStubs, error: codeStubError } = validateCodeStubs(codeStubsRaw);
    if (codeStubError) {
      return res.status(400).json({ error: codeStubError, code: 'INVALID_INPUT' });
    }

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
    if (normalizedDifficulty !== undefined) {
      updates.push(`difficulty = $${paramCount++}`);
      params.push(normalizedDifficulty);
    }
    if (normalizedTopics !== undefined) {
      updates.push(`topics = $${paramCount++}`);
      params.push(normalizedTopics);
    }
    if (constraints !== undefined) {
      updates.push(`constraints = $${paramCount++}`);
      params.push(constraints);
    }
    if (normalizedHints !== undefined) {
      updates.push(`hints = $${paramCount++}::jsonb`);
      params.push(JSON.stringify(normalizedHints));
    }
    if (followUp !== undefined) {
      updates.push(`follow_up = $${paramCount++}`);
      params.push(followUp);
    }
    if (codeStubs !== undefined) {
      updates.push(`code_stubs = $${paramCount++}::jsonb`);
      params.push(JSON.stringify(codeStubs));
    }
    if (is_contest_exclusive !== undefined) {
      updates.push(`is_contest_exclusive = $${paramCount++}`);
      params.push(is_contest_exclusive === true);
    }
    if (problem_number !== undefined) {
      const checkNum = await dbPool.query('SELECT 1 FROM problems WHERE problem_number = $1 AND id != $2', [problem_number, id]);
      if (checkNum.rows.length > 0) {
        return res.status(400).json({ error: 'problem_number already exists', code: 'INVALID_INPUT' });
      }
      updates.push(`problem_number = $${paramCount++}`);
      params.push(problem_number);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update', code: 'INVALID_INPUT' });
    }

    params.push(id);

    const result = await dbPool.query(
      `UPDATE problems
       SET ${updates.join(', ')}
       WHERE id = $${paramCount}
       RETURNING id, title, description, difficulty, topics, constraints, hints, follow_up, code_stubs, is_contest_exclusive, problem_number`,
      params
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Problem not found', code: 'NOT_FOUND' });
    }

    return res.json(normalizeProblemRow(result.rows[0]));
  } catch (error) {
    console.error('Update problem error:', error);
    return res.status(500).json({ error: 'Failed to update problem', code: 'UPDATE_ERROR' });
  }
});

export default router;
