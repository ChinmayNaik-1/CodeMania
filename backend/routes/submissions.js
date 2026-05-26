import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { dbPool } from '../index.js';
import { buildExecutableCode, runAgainstTestCase } from '../services/judgeService.js';

const router = Router();

function normalizeOutput(output = '') {
  return output
    .replace(/\r\n/g, '\n')
    .split('\n')
    .map((line) => line.trimEnd())
    .join('\n')
    .trim();
}

function normalizeCompare(output = '') {
  return String(output).replace(/\s+/g, '').toLowerCase();
}

function extractErrorLine(message = '') {
  if (!message) return null;
  const patterns = [/line\s+(\d+)/i, /:(\d+):(\d+)/, /\((\d+)\)/];
  for (const pattern of patterns) {
    const match = String(message).match(pattern);
    if (!match) continue;
    const value = parseInt(match[1], 10);
    if (!Number.isNaN(value)) return value;
  }
  return null;
}

async function buildRunCode(problemId, language, userCode) {
  return buildExecutableCode(problemId, language, userCode, dbPool);
}

function mapRunFailureStatus(run) {
  if (run.run_status === 'TO') return 'Time Limit Exceeded';
  if (run.code !== 0) return 'Runtime Error';
  return 'Wrong Answer';
}

router.post('/run', authMiddleware, async (req, res) => {
  try {
    const { problemId, language, version, code, test_input: testInput } = req.body;

    if (!problemId || !language || !version || !code) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const injectedCode = await buildRunCode(problemId, language, code);

    if (typeof testInput === 'string' && testInput.trim().length > 0) {
      const run = await runAgainstTestCase(injectedCode, language, version, testInput);

      const compileFailed =
        (run.compile_code !== undefined && run.compile_code !== null && run.compile_code !== 0) ||
        (run.compile_status && run.compile_status !== 'OK');

      if (compileFailed) {
        const compileError = run.compile_stderr || run.compile_stdout || run.compile_message || 'Compilation failed';
        return res.json({
          status: 'Compile Error',
          runtime_ms: 0,
          memory_kb: 0,
          error_message: compileError,
          error_line: extractErrorLine(compileError),
          results: [
            {
              input: testInput,
              expected: null,
              actual: '',
              passed: false,
              errorType: 'compilation_error',
              error: compileError,
              runtime_ms: 0,
            },
          ],
        });
      }

      if (run.code !== 0 || run.run_status === 'TO') {
        const errorMessage = run.stderr || run.run_message || 'Runtime error';
        const status = run.run_status === 'TO' ? 'Time Limit Exceeded' : 'Runtime Error';
        return res.json({
          status,
          runtime_ms: run.time_ms ?? 0,
          memory_kb: run.memory_kb ?? 0,
          error_message: errorMessage,
          error_line: extractErrorLine(errorMessage),
          actual_output: normalizeOutput(run.stdout || ''),
          results: [
            {
              input: testInput,
              expected: null,
              actual: normalizeOutput(run.stdout || ''),
              passed: false,
              errorType: run.run_status === 'TO' ? 'time_limit_exceeded' : 'runtime_error',
              error: errorMessage,
              runtime_ms: run.time_ms ?? 0,
            },
          ],
        });
      }

      const expectedResult = await dbPool.query(
        `SELECT expected_output
         FROM test_cases
         WHERE problem_id = $1 AND input = $2 AND COALESCE(is_hidden, false) = false
         ORDER BY created_at ASC
         LIMIT 1`,
        [problemId, testInput]
      );

      const expected = expectedResult.rows[0]?.expected_output ?? null;
      const actual = normalizeOutput(run.stdout || '');
      const passed = expected == null || normalizeCompare(actual) === normalizeCompare(expected);

      return res.json({
        status: passed ? 'Accepted' : 'Wrong Answer',
        runtime_ms: run.time_ms ?? 0,
        memory_kb: run.memory_kb ?? 0,
        error_message: null,
        error_line: null,
        actual_output: actual,
        results: [
          {
            input: testInput,
            expected,
            actual,
            passed,
            errorType: null,
            error: null,
            runtime_ms: run.time_ms ?? 0,
          },
        ],
      });
    }

    const visibleCases = await dbPool.query(
      `SELECT id, input, expected_output
       FROM test_cases
       WHERE problem_id = $1 AND COALESCE(is_hidden, false) = false
       ORDER BY id ASC`,
      [problemId]
    );

    const results = [];
    let status = 'Accepted';
    let topError = null;

    for (const tc of visibleCases.rows) {
      const run = await runAgainstTestCase(injectedCode, language, version, tc.input);
      const compileFailed =
        (run.compile_code !== undefined && run.compile_code !== null && run.compile_code !== 0) ||
        (run.compile_status && run.compile_status !== 'OK');

      if (compileFailed) {
        const compileError = run.compile_stderr || run.compile_stdout || run.compile_message || 'Compilation failed';
        results.push({
          input: tc.input,
          expected: tc.expected_output,
          actual: '',
          passed: false,
          errorType: 'compilation_error',
          error: compileError,
          runtime_ms: 0,
        });
        status = 'Compile Error';
        topError = compileError;
        break;
      }

      if (run.code !== 0 || run.run_status === 'TO') {
        const errorMessage = run.stderr || run.run_message || 'Runtime error';
        const errType = run.run_status === 'TO' ? 'time_limit_exceeded' : 'runtime_error';
        status = run.run_status === 'TO' ? 'Time Limit Exceeded' : 'Runtime Error';
        topError = errorMessage;
        results.push({
          input: tc.input,
          expected: tc.expected_output,
          actual: normalizeOutput(run.stdout || ''),
          passed: false,
          errorType: errType,
          error: errorMessage,
          runtime_ms: run.time_ms ?? 0,
        });
        break;
      }

      const actual = normalizeOutput(run.stdout || '');
      const passed = normalizeCompare(actual) === normalizeCompare(tc.expected_output || '');
      results.push({
        input: tc.input,
        expected: tc.expected_output,
        actual,
        passed,
        errorType: null,
        error: null,
        runtime_ms: run.time_ms ?? 0,
      });

      if (!passed && status === 'Accepted') {
        status = 'Wrong Answer';
      }
    }

    return res.json({
      status,
      runtime_ms: results.length === 0 ? 0 : Math.max(...results.map((r) => Number(r.runtime_ms || 0))),
      error_message: topError,
      results,
    });
  } catch (error) {
    console.error('Run error:', error);
    return res.status(500).json({ error: 'Failed to run code', code: 'RUN_ERROR' });
  }
});

router.post('/submit', authMiddleware, async (req, res) => {
  try {
    const { problemId, contestId, teamId, language, version, code } = req.body;

    if (!problemId || !language || !version || !code) {
      return res.status(400).json({ error: 'Missing required fields', code: 'INVALID_INPUT' });
    }

    const allCases = await dbPool.query(
      `SELECT id, input, expected_output, COALESCE(is_hidden, false) AS is_hidden
       FROM test_cases
       WHERE problem_id = $1
       ORDER BY is_hidden ASC, id ASC`,
      [problemId]
    );

    const injectedCode = await injectDriverCode(problemId, language, code);

    let passed = 0;
    let failedCase = null;
    let failureStatus = null;
    let errorMessage = null;
    let errorLine = null;
    let runtimeMs = 0;
    let memoryKb = 0;
    let actualOutput = '';

    for (const tc of allCases.rows) {
      const run = await runAgainstTestCase(injectedCode, language, version, tc.input);

      const compileFailed =
        (run.compile_code !== undefined && run.compile_code !== null && run.compile_code !== 0) ||
        (run.compile_status && run.compile_status !== 'OK');

      if (compileFailed) {
        failureStatus = 'Compile Error';
        errorMessage = run.compile_stderr || run.compile_stdout || run.compile_message || 'Compilation failed';
        errorLine = extractErrorLine(errorMessage);
        break;
      }

      if (run.code !== 0 || run.run_status === 'TO') {
        failureStatus = mapRunFailureStatus(run);
        errorMessage = run.stderr || run.run_message || 'Runtime error';
        errorLine = extractErrorLine(errorMessage);
        actualOutput = normalizeOutput(run.stdout || '');
        runtimeMs = Math.max(runtimeMs, Number(run.time_ms || 0));
        memoryKb = Math.max(memoryKb, Number(run.memory_kb || 0));
        break;
      }

      const actual = normalizeOutput(run.stdout || '');
      const expected = normalizeOutput(tc.expected_output || '');
      actualOutput = actual;
      runtimeMs = Math.max(runtimeMs, Number(run.time_ms || 0));
      memoryKb = Math.max(memoryKb, Number(run.memory_kb || 0));

      if (normalizeCompare(actual) === normalizeCompare(expected)) {
        passed += 1;
      } else {
        failedCase = {
          ...tc,
          actual,
          expected_output: tc.expected_output,
        };
        failureStatus = 'Wrong Answer';
        break;
      }
    }

    const total = allCases.rows.length;
    const status = failureStatus || (passed === total ? 'Accepted' : 'Wrong Answer');

    const verdictForDb =
      status === 'Accepted'
        ? 'accepted'
        : status === 'Compile Error'
          ? 'compilation_error'
          : status === 'Runtime Error'
            ? 'runtime_error'
            : status === 'Time Limit Exceeded'
              ? 'time_limit_exceeded'
              : 'wrong_answer';

    const insertResult = await dbPool.query(
      `INSERT INTO submissions
       (user_id, problem_id, contest_id, team_id, language, language_version, code, verdict, status, passed_cases, total_cases, time_ms, runtime_ms, memory_kb, error_message, stderr, error_line)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
       RETURNING id`,
      [
        req.user.id,
        problemId,
        contestId || null,
        teamId || null,
        language,
        version,
        code,
        verdictForDb,
        status,
        passed,
        total,
        runtimeMs,
        runtimeMs,
        memoryKb,
        errorMessage,
        errorMessage,
        errorLine,
      ]
    );

    const hiddenFailure = failedCase?.is_hidden === true;

    return res.json({
      submissionId: insertResult.rows[0].id,
      status,
      passed,
      total,
      runtime_ms: runtimeMs,
      memory_kb: memoryKb,
      error_message: errorMessage,
      error_line: errorLine,
      failed_input: hiddenFailure ? null : (failedCase?.input ?? null),
      expected_output: hiddenFailure ? null : (failedCase?.expected_output ?? null),
      actual_output: actualOutput,
    });
  } catch (error) {
    console.error('Submit error:', error);
    return res.status(500).json({ error: 'Failed to submit code', code: 'SUBMIT_ERROR' });
  }
});

router.get('/problem/:problemId', authMiddleware, async (req, res) => {
  try {
    const problemId = parseInt(req.params.problemId, 10);
    if (Number.isNaN(problemId)) {
      return res.status(400).json({ error: 'Invalid problem id', code: 'INVALID_INPUT' });
    }

    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const limitRaw = parseInt(req.query.limit || '20', 10);
    const limit = Number.isNaN(limitRaw) ? 20 : Math.min(Math.max(limitRaw, 1), 100);
    const offset = (page - 1) * limit;

    const result = await dbPool.query(
      `SELECT id,
              COALESCE(status,
                CASE verdict
                  WHEN 'accepted' THEN 'Accepted'
                  WHEN 'wrong_answer' THEN 'Wrong Answer'
                  WHEN 'compilation_error' THEN 'Compile Error'
                  WHEN 'runtime_error' THEN 'Runtime Error'
                  WHEN 'time_limit_exceeded' THEN 'Time Limit Exceeded'
                  ELSE 'Pending'
                END
              ) AS status,
              language,
              COALESCE(runtime_ms, time_ms) AS runtime_ms,
              memory_kb,
              to_char((created_at AT TIME ZONE 'UTC'), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS created_at
       FROM submissions
       WHERE user_id = $1 AND problem_id = $2
       ORDER BY created_at DESC
       LIMIT $3 OFFSET $4`,
      [req.user.id, problemId, limit, offset]
    );

    return res.json({
      submissions: result.rows,
      page,
      limit,
    });
  } catch (error) {
    console.error('Get problem submissions error:', error);
    return res.status(500).json({ error: 'Failed to fetch submissions', code: 'FETCH_ERROR' });
  }
});

router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const submissionId = parseInt(req.params.id, 10);
    if (Number.isNaN(submissionId)) {
      return res.status(400).json({ error: 'Invalid submission id', code: 'INVALID_INPUT' });
    }

    const result = await dbPool.query(
      `SELECT id,
              COALESCE(status,
                CASE verdict
                  WHEN 'accepted' THEN 'Accepted'
                  WHEN 'wrong_answer' THEN 'Wrong Answer'
                  WHEN 'compilation_error' THEN 'Compile Error'
                  WHEN 'runtime_error' THEN 'Runtime Error'
                  WHEN 'time_limit_exceeded' THEN 'Time Limit Exceeded'
                  ELSE 'Pending'
                END
              ) AS status,
              language,
              COALESCE(runtime_ms, time_ms) AS runtime_ms,
              memory_kb,
              passed_cases,
              total_cases,
              to_char((created_at AT TIME ZONE 'UTC'), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') AS created_at,
              code,
              error_message,
              stderr,
              error_line,
              NULL::text AS input,
              NULL::text AS expected_output,
              NULL::text AS your_output
       FROM submissions
       WHERE id = $1 AND user_id = $2`,
      [submissionId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Submission not found', code: 'NOT_FOUND' });
    }

    return res.json({ submission: result.rows[0] });
  } catch (error) {
    console.error('Get submission detail error:', error);
    return res.status(500).json({ error: 'Failed to fetch submission', code: 'FETCH_ERROR' });
  }
});

export default router;
