import axios from 'axios';
import https from 'https';
import { dbPool } from '../index.js';
import { getLeaderboard } from './contestService.js';

let PISTON_URL = process.env.PISTON_URL || 'http://localhost:2000/api/v2/execute';
if (PISTON_URL.includes('/api/v2/execute/api/v2/execute')) {
  PISTON_URL = PISTON_URL.replace('/api/v2/execute/api/v2/execute', '/api/v2/execute');
}

const LANGUAGE_MAP = {
  'cpp':    { language: 'c++',    version: '*' },
  'python': { language: 'python', version: '*' },
  'java':   { language: 'java',   version: '*' },
};

async function buildExecutableCode(problemId, language, userCode) {
  const result = await dbPool.query(
    'SELECT driver_prefix, driver_suffix FROM driver_code WHERE problem_id = $1 AND language = $2',
    [problemId, language]
  );
  
  let prefix = '';
  let suffix = '';
  
  if (result.rows.length > 0) {
    prefix = result.rows[0].driver_prefix || '';
    suffix = result.rows[0].driver_suffix || '';
  }

  if (!prefix && !suffix) {
    if (language === 'c++' || language === 'cpp') {
      const code = `#include<bits/stdc++.h>\nusing namespace std;\n${userCode}\nint main(){return 0;}`;
      console.log('=== EXECUTABLE CODE SENT TO PISTON ===\n', code);
      return code;
    }
    console.log('=== EXECUTABLE CODE SENT TO PISTON ===\n', userCode);
    return userCode;
  }
  
  const code = `${prefix}\n${userCode}\n${suffix}`;
  console.log('=== EXECUTABLE CODE SENT TO PISTON ===\n', code);
  return code;
}

function normalizeLang(lang) {
  const map = {
    'cpp': 'c++',
    'c++': 'c++',
    'C++': 'c++',
    'python': 'python',
    'python3': 'python',
    'java': 'java',
    'javascript': 'javascript',
    'js': 'javascript',
  };
  return map[lang] ?? lang.toLowerCase();
}

async function runOnPiston(language, fullCode, stdin) {
  const normLang = normalizeLang(language);
  const payload = {
    language: normLang,
    version: '*',
    files: [{ name: normLang === 'c++' ? 'main.cpp' : 'main', content: fullCode }],
    stdin: stdin || '',
    run_timeout: 5000,
    compile_timeout: 10000,
  };

  try {
    const response = await axios.post(PISTON_URL, payload, { 
      timeout: 15000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    });
    return response.data;
  } catch (err) {
    console.error('=== PISTON ERROR ===');
    console.error('URL called:', PISTON_URL);
    console.error('Payload sent:', JSON.stringify(payload, null, 2));
    console.error('Status:', err.response?.status);
    console.error('Response body:', JSON.stringify(err.response?.data, null, 2));
    console.error('Message:', err.message);
    throw err;
  }
}

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

  const fullCode = await buildExecutableCode(problemId, language, userCode);

  const tcResult = await dbPool.query(
    'SELECT input, expected_output FROM test_cases WHERE problem_id = $1',
    [problemId]
  );
  const testCases = tcResult.rows;

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

  let verdict = 'Accepted';
  let firstFailStdout = null;
  let firstFailStderr = null;
  let compileOutput = null;
  let totalTimeMs = 0;

  for (const tc of testCases) {
    const result = await runOnPiston(language, fullCode, tc.input);
    
    if (result.compile && result.compile.code !== 0) {
      verdict = 'Compile Error';
      compileOutput = result.compile.output;
      break;
    }
    
    if (result.run.code !== 0 || result.run.signal) {
      if (result.run.signal === 'SIGKILL') {
        verdict = 'Time Limit Exceeded';
      } else {
        verdict = 'Runtime Error';
        firstFailStderr = result.run.stderr;
      }
      break;
    }
    
    const actual = (result.run.stdout || '').trim();
    const expected = (tc.expected_output || '').trim();
    totalTimeMs += parseInt(result.run.time || 0, 10);
    
    if (actual !== expected) {
      verdict = 'Wrong Answer';
      firstFailStdout = result.run.stdout;
      break;
    }
  }

  let scoreAwarded = 0;
  let firstSolve = false;

  if (verdict === 'Accepted') {
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

  await dbPool.query(`
    INSERT INTO contest_submissions
      (contest_id, problem_id, user_id, username,
       team_id, team_name, language, code,
       verdict, stdout, stderr, compile_output,
       time_ms, score_awarded, first_solve)
    VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`,
    [contestId, problemId, userId, user.username,
     teamId || null, teamName,
     language, userCode,
     verdict,
     firstFailStdout,
     firstFailStderr,
     compileOutput,
     totalTimeMs,
     scoreAwarded,
     firstSolve]
  );

  return { verdict, scoreAwarded, firstSolve };
}

export async function runContestSample(problemId, language, userCode) {
  const fullCode = await buildExecutableCode(problemId, language, userCode);
  const tcResult = await dbPool.query(
    'SELECT input, expected_output FROM test_cases WHERE problem_id=$1 AND is_hidden=false',
    [problemId]
  );
  const testCases = tcResult.rows;
  
  const results = [];
  for (const tc of testCases) {
    const result = await runOnPiston(language, fullCode, tc.input);
    const compileOutput = result.compile?.output || '';
    const stdout = result.run?.stdout?.trim() || '';
    const stderr = result.run?.stderr || '';
    const expected = (tc.expected_output || '').trim();
    
    let verdict = 'Accepted';
    if (result.compile && result.compile.code !== 0) {
      verdict = 'Compile Error';
    } else if (result.run?.signal === 'SIGKILL') {
      verdict = 'Time Limit Exceeded';
    } else if (result.run?.code !== 0 || result.run?.signal) {
      verdict = 'Runtime Error';
    } else if (stdout !== expected) {
      verdict = 'Wrong Answer';
    }

    results.push({
      input: tc.input,
      expected_output: tc.expected_output,
      actual_output: stdout,
      stderr: stderr,
      compile_output: compileOutput,
      passed: stdout === expected,
      verdict: verdict
    });
  }
  return results;
}
