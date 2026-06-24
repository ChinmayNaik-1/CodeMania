import { dbPool } from '../index.js';
import { getLeaderboard } from './contestService.js';
import {
  buildExecutableCode,
  runAgainstTestCase,
  normalizeOutput,
  normalizeCompare,
  extractErrorLine,
  mapRunFailureStatus
} from './judgeService.js';

export async function judgeContestSubmission(
  contestId, problemId, userId, teamId, language, userCode, io
) {
  const userResult = await dbPool.query(
    'SELECT username FROM users WHERE id = $1', [userId]
  );
  const user = userResult.rows[0];

  let teamName = null;
  if (teamId) {
    const teamResult = await dbPool.query(
      'SELECT name FROM contest_teams WHERE id = $1', [teamId]
    );
    teamName = teamResult.rows[0]?.name || null;
  }

  const allCases = await dbPool.query(
    `SELECT id, input, expected_output, COALESCE(is_hidden, false) AS is_hidden
     FROM test_cases
     WHERE problem_id = $1
     ORDER BY is_hidden ASC, id ASC`,
    [problemId]
  );

  const testCases = allCases.rows;

  if (testCases.length === 0) {
    await dbPool.query(`
      INSERT INTO contest_submissions
        (contest_id, problem_id, user_id, username,
         team_id, team_name, language, code,
         verdict)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
      [contestId, problemId, userId, user.username,
       teamId || null, teamName, language, userCode, 'No test cases']
    );
    return { verdict: 'No test cases', scoreAwarded: 0, firstSolve: false };
  }

  const fullCode = await buildExecutableCode(problemId, language, userCode, dbPool);

  let passed = 0;
  let failedCase = null;
  let failureStatus = null;
  let errorMessage = null;
  let errorLine = null;
  let runtimeMs = 0;
  let memoryKb = 0;
  let actualOutput = '';
  let compileOutput = null;

  for (const tc of testCases) {
    const run = await runAgainstTestCase(fullCode, language, '*', tc.input);

    const compileFailed =
      (run.compile_code !== undefined && run.compile_code !== null && run.compile_code !== 0) ||
      (run.compile_status && run.compile_status !== 'OK');

    if (compileFailed) {
      failureStatus = 'Compile Error';
      compileOutput = run.compile_stderr || run.compile_stdout || run.compile_message || 'Compilation failed';
      errorMessage = compileOutput;
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

  const total = testCases.length;
  const status = failureStatus || (passed === total ? 'Accepted' : 'Wrong Answer');

  let scoreAwarded = 0;
  let firstSolve = false;

  if (status === 'Accepted') {
    const solveKey = teamId
      ? 'WHERE contest_id=$1 AND problem_id=$2 AND team_id=$3'
      : 'WHERE contest_id=$1 AND problem_id=$2 AND user_id=$3 AND team_id IS NULL';
    const solveParam = teamId ? teamId : userId;

    const existingResult = await dbPool.query(
      `SELECT 1 FROM contest_problem_solves ${solveKey}`,
      [contestId, problemId, solveParam]
    );

    if (existingResult.rows.length === 0) {
      const cpResult = await dbPool.query(
        'SELECT points FROM contest_problems WHERE contest_id=$1 AND problem_id=$2',
        [contestId, problemId]
      );
      scoreAwarded = cpResult.rows[0]?.points || 0;
      firstSolve = true;

      await dbPool.query(
        `INSERT INTO contest_problem_solves
         (contest_id, problem_id, team_id, user_id, score_awarded)
         VALUES ($1, $2, $3, $4, $5)`,
        [contestId, problemId, teamId || null, userId, scoreAwarded]
      );

      if (teamId) {
        await dbPool.query(`
          INSERT INTO contest_leaderboard
            (contest_id, team_id, total_score, problems_solved, last_accepted_at)
          VALUES ($1, $2, $3, 1, NOW())
          ON CONFLICT (contest_id, team_id) WHERE user_id IS NULL DO UPDATE SET
            total_score = contest_leaderboard.total_score + $3,
            problems_solved = contest_leaderboard.problems_solved + 1,
            last_accepted_at = NOW()`,
          [contestId, teamId, scoreAwarded]
        );
      } else {
        await dbPool.query(`
          INSERT INTO contest_leaderboard
            (contest_id, user_id, total_score, problems_solved, last_accepted_at)
          VALUES ($1, $2, $3, 1, NOW())
          ON CONFLICT (contest_id, user_id) WHERE team_id IS NULL DO UPDATE SET
            total_score = contest_leaderboard.total_score + $3,
            problems_solved = contest_leaderboard.problems_solved + 1,
            last_accepted_at = NOW()`,
          [contestId, userId, scoreAwarded]
        );
      }

      if (io) {
        const leaderboard = await getLeaderboard(contestId);
        io.to(`contest:${contestId}`).emit('leaderboard_update', leaderboard);
      }
    }
  }

  const insertResult = await dbPool.query(`
    INSERT INTO contest_submissions
      (contest_id, problem_id, user_id, username,
       team_id, team_name, language, code,
       verdict, stdout, stderr, compile_output,
       time_ms, score_awarded, first_solve)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
    RETURNING id`,
    [contestId, problemId, userId, user.username,
     teamId || null, teamName,
     language, userCode,
     status,
     status === 'Wrong Answer' ? actualOutput : null,
     errorMessage,
     compileOutput,
     runtimeMs,
     scoreAwarded,
     firstSolve]
  );

  return { 
    verdict: status, 
    scoreAwarded, 
    firstSolve, 
    submissionId: insertResult.rows[0].id 
  };
}

export async function runContestSample(problemId, language, userCode) {
  const fullCode = await buildExecutableCode(problemId, language, userCode, dbPool);
  const tcResult = await dbPool.query(
    'SELECT input, expected_output FROM test_cases WHERE problem_id=$1 AND is_hidden=false',
    [problemId]
  );
  const testCases = tcResult.rows;
  
  const results = [];
  for (const tc of testCases) {
    const run = await runAgainstTestCase(fullCode, language, '*', tc.input);
    const compileFailed =
      (run.compile_code !== undefined && run.compile_code !== null && run.compile_code !== 0) ||
      (run.compile_status && run.compile_status !== 'OK');

    if (compileFailed) {
      results.push({
        input: tc.input,
        expected_output: tc.expected_output,
        actual_output: '',
        stderr: '',
        compile_output: run.compile_stderr || run.compile_stdout || run.compile_message || 'Compilation failed',
        passed: false,
        verdict: 'Compile Error'
      });
      continue;
    }

    if (run.code !== 0 || run.run_status === 'TO') {
      const failureStatus = mapRunFailureStatus(run);
      results.push({
        input: tc.input,
        expected_output: tc.expected_output,
        actual_output: normalizeOutput(run.stdout || ''),
        stderr: run.stderr || run.run_message || 'Runtime error',
        compile_output: '',
        passed: false,
        verdict: failureStatus
      });
      continue;
    }

    const actual = normalizeOutput(run.stdout || '');
    const expected = normalizeOutput(tc.expected_output || '');
    const passed = normalizeCompare(actual) === normalizeCompare(expected);
    
    results.push({
      input: tc.input,
      expected_output: tc.expected_output,
      actual_output: actual,
      stderr: '',
      compile_output: '',
      passed: passed,
      verdict: passed ? 'Accepted' : 'Wrong Answer'
    });
  }
  return results;
}
