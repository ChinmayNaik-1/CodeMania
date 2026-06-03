import axios from 'axios';
import https from 'https';
import { processContestSubmission } from './icpcService.js';

let PISTON_URL = process.env.PISTON_URL || 'http://localhost:2000/api/v2/execute';
if (PISTON_URL.includes('/api/v2/execute/api/v2/execute')) {
  PISTON_URL = PISTON_URL.replace('/api/v2/execute/api/v2/execute', '/api/v2/execute');
}
const RUNTIME_CACHE_TTL_MS = 5 * 60 * 1000;
const DEFAULT_RUNTIME_FALLBACK = {
  python: '3.10.0',
  cpp: '10.2.0',
  java: '15.0.2',
  javascript: '18.15.0',
};

let runtimeCache = {
  fetchedAt: 0,
  runtimes: [],
};

function getPistonRuntimesUrl() {
  return PISTON_URL.replace(/\/execute\/?$/, '/runtimes');
}

function normalizeLanguageName(language = '') {
  const normalized = language.toLowerCase().trim();
  if (normalized === 'c++') return 'cpp';
  if (normalized === 'py') return 'python';
  if (normalized === 'node' || normalized === 'js') return 'javascript';
  return normalized;
}

function versionSegments(value = '') {
  return String(value)
    .split(/[^0-9]+/g)
    .filter((segment) => segment.length > 0)
    .map((segment) => parseInt(segment, 10));
}

function compareVersions(a = '', b = '') {
  const left = versionSegments(a);
  const right = versionSegments(b);
  const maxLen = Math.max(left.length, right.length);

  for (let i = 0; i < maxLen; i += 1) {
    const leftValue = left[i] ?? 0;
    const rightValue = right[i] ?? 0;
    if (leftValue > rightValue) return 1;
    if (leftValue < rightValue) return -1;
  }

  return 0;
}

function runtimeMatchesLanguage(runtime, normalizedLanguage) {
  if (!runtime) return false;
  const runtimeLanguage = String(runtime.language || '').toLowerCase();
  if (runtimeLanguage === normalizedLanguage) return true;
  if (normalizedLanguage === 'cpp' && runtimeLanguage === 'c++') return true;
  if (normalizedLanguage === 'javascript' && runtimeLanguage === 'node') return true;

  const aliases = Array.isArray(runtime.aliases)
    ? runtime.aliases.map((alias) => String(alias).toLowerCase())
    : [];

  return aliases.includes(normalizedLanguage);
}

export async function fetchPistonRuntimes({ forceRefresh = false } = {}) {
  const now = Date.now();
  if (!forceRefresh && runtimeCache.runtimes.length > 0 && now - runtimeCache.fetchedAt < RUNTIME_CACHE_TTL_MS) {
    return runtimeCache.runtimes;
  }

  try {
    const response = await axios.get(getPistonRuntimesUrl(), { 
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    });
    const runtimes = Array.isArray(response.data) ? response.data : [];
    runtimeCache = {
      fetchedAt: now,
      runtimes,
    };
    return runtimes;
  } catch (_) {
    return runtimeCache.runtimes;
  }
}

function pickBestRuntime(runtimes, normalizedLanguage, requestedVersion) {
  const candidates = (runtimes || []).filter((runtime) =>
    runtimeMatchesLanguage(runtime, normalizedLanguage)
  );

  if (candidates.length === 0) {
    return {
      language: normalizedLanguage,
      version: requestedVersion || DEFAULT_RUNTIME_FALLBACK[normalizedLanguage] || requestedVersion || '',
      usedFallback: false,
      resolvedFrom: 'default',
    };
  }

  if (requestedVersion) {
    const exact = candidates.find((runtime) => String(runtime.version) === String(requestedVersion));
    if (exact) {
      return {
        language: String(exact.language || normalizedLanguage),
        version: String(exact.version || requestedVersion),
        usedFallback: false,
        resolvedFrom: 'requested',
      };
    }
  }

  const sorted = [...candidates].sort((a, b) =>
    compareVersions(String(b.version || ''), String(a.version || ''))
  );
  const best = sorted[0];

  return {
    language: String(best.language || normalizedLanguage),
    version: String(best.version || requestedVersion || ''),
    usedFallback: true,
    resolvedFrom: 'fallback',
  };
}

async function resolvePistonRuntime(language, version, { forceRefresh = false } = {}) {
  const normalizedLanguage = normalizeLanguageName(language);
  const runtimes = await fetchPistonRuntimes({ forceRefresh });
  const runtime = pickBestRuntime(runtimes, normalizedLanguage, version);

  if (!runtime.version) {
    return {
      language: normalizedLanguage,
      version: DEFAULT_RUNTIME_FALLBACK[normalizedLanguage] || version || '',
      usedFallback: true,
      resolvedFrom: 'default',
    };
  }

  return runtime;
}

function describePistonError(error) {
  const status = error?.response?.status;
  const data = error?.response?.data;
  const message = data?.message || data?.error || data?.details || error?.message || 'Unknown error';

  if (status) {
    return `Piston ${status}: ${message}`;
  }

  return message;
}

function getSourceFileName(language = '') {
  const normalized = language.toLowerCase();
  if (normalized === 'cpp' || normalized === 'c++') return 'solution.cpp';
  if (normalized === 'python' || normalized === 'py') return 'solution.py';
  if (normalized === 'java') return 'Main.java';
  if (normalized === 'javascript' || normalized === 'node') return 'solution.js';
  return 'solution.txt';
}

function getRunTimeoutMs(language = '') {
  const envValue = parseInt(process.env.PISTON_RUN_TIMEOUT || '', 10);
  if (!Number.isNaN(envValue) && envValue > 0) {
    return envValue;
  }

  const normalized = language.toLowerCase();
  if (normalized === 'cpp' || normalized === 'c++') {
    return 5000;
  }

  return 3000;
}

function getCompileTimeoutMs(language = '') {
  const envValue = parseInt(process.env.PISTON_COMPILE_TIMEOUT || '', 10);
  if (!Number.isNaN(envValue) && envValue > 0) {
    return envValue;
  }

  const normalized = language.toLowerCase();
  if (normalized === 'cpp' || normalized === 'c++') {
    return 30000;
  }

  return 10000;
}

function parsePistonMemoryLimit(value, fallbackBytes) {
  const parsed = parseInt(value || '', 10);
  if (Number.isNaN(parsed) || parsed <= 0) {
    return fallbackBytes;
  }

  // Backward compatibility: older config used KB-like values such as 128000.
  if (parsed < 1024 * 1024) {
    return parsed * 1024;
  }

  return parsed;
}

function normalizeOutput(output = '') {
  return output
    .replace(/\r\n/g, '\n')
    .split('\n')
    .map((line) => line.trimEnd())
    .join('\n')
    .trim();
}

function isTwoSumProblem(title = '') {
  const normalizedTitle = title.toLowerCase();
  return normalizedTitle.includes('two sum') || normalizedTitle.includes('twosum');
}

function parseIntegerList(output = '') {
  const matches = (output || '').match(/-?\d+/g);
  if (!matches) return [];
  return matches.map((value) => parseInt(value, 10)).filter((value) => !Number.isNaN(value));
}

function outputsMatch(problemTitle, expectedOutput, actualOutput) {
  if (isTwoSumProblem(problemTitle)) {
    const expectedNums = parseIntegerList(expectedOutput);
    const actualNums = parseIntegerList(actualOutput);

    if (expectedNums.length === 2 && actualNums.length === 2) {
      const sortedExpected = [...expectedNums].sort((a, b) => a - b);
      const sortedActual = [...actualNums].sort((a, b) => a - b);
      return (
        sortedExpected[0] === sortedActual[0] &&
        sortedExpected[1] === sortedActual[1]
      );
    }
  }

  return actualOutput === expectedOutput;
}

function toDisplayStatus(verdict = '') {
  switch (verdict) {
    case 'accepted':
      return 'Accepted';
    case 'wrong_answer':
      return 'Wrong Answer';
    case 'compilation_error':
      return 'Compile Error';
    case 'runtime_error':
      return 'Runtime Error';
    case 'time_limit_exceeded':
      return 'Time Limit Exceeded';
    default:
      return 'Pending';
  }
}

function extractErrorLine(message = '') {
  if (!message) return null;
  const patterns = [
    /line\s+(\d+)/i,
    /:(\d+):(\d+)/,
    /\((\d+)\)/,
  ];

  for (const pattern of patterns) {
    const match = message.match(pattern);
    if (!match) continue;
    const parsed = parseInt(match[1], 10);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }

  return null;
}

export async function buildExecutableCode(problemId, language, userCode, dbPool) {
  if (!dbPool || !problemId || !language) {
    return userCode;
  }

  try {
    const result = await dbPool.query(
      `SELECT driver_prefix, driver_suffix
       FROM driver_code
       WHERE problem_id = $1 AND language = $2
       LIMIT 1`,
      [problemId, language]
    );

    if (result.rows.length === 0) {
      return userCode;
    }

    const { driver_prefix: driverPrefix, driver_suffix: driverSuffix } = result.rows[0] || {};
    const parts = [];

    if (driverPrefix && driverPrefix.trim()) {
      parts.push(driverPrefix);
    }

    parts.push(userCode);

    if (driverSuffix && driverSuffix.trim()) {
      parts.push(driverSuffix);
    }

    return parts.join('\n');
  } catch (_) {
    return userCode;
  }
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

export async function runAgainstTestCase(code, language, version, stdin) {
  try {
    const runMemoryLimit = parsePistonMemoryLimit(
      process.env.PISTON_MEMORY_LIMIT,
      128 * 1024 * 1024
    );
    const compileMemoryLimit = parsePistonMemoryLimit(
      process.env.PISTON_COMPILE_MEMORY_LIMIT,
      256 * 1024 * 1024
    );

    const primaryRuntime = await resolvePistonRuntime(language, version);
    if (!primaryRuntime.version) {
      throw new Error(`Unsupported runtime for language: ${language}`);
    }
    const requestBody = (runtime) => {
      const normLang = normalizeLang(runtime.language || language);
      return {
        language: normLang,
        version: runtime.version || '*',
        files: [
          {
            name: normLang === 'c++' ? 'main.cpp' : getSourceFileName(runtime.language),
            content: code,
          },
        ],
        stdin,
        run_timeout: getRunTimeoutMs(runtime.language),
        compile_timeout: getCompileTimeoutMs(runtime.language),
        run_memory_limit: runMemoryLimit,
        compile_memory_limit: compileMemoryLimit,
      };
    };

    const axiosOptions = {
      timeout: 15000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
      },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    };

    let response;

    try {
      response = await axios.post(PISTON_URL, requestBody(primaryRuntime), axiosOptions);
    } catch (error) {
      const shouldRetry =
        error?.response?.status === 400 &&
        (!primaryRuntime.usedFallback || primaryRuntime.resolvedFrom === 'requested');

      if (shouldRetry) {
        const fallbackRuntime = await resolvePistonRuntime(language, null, { forceRefresh: true });
        const isDifferent =
          fallbackRuntime.language !== primaryRuntime.language ||
          fallbackRuntime.version !== primaryRuntime.version;

        if (fallbackRuntime.version && isDifferent) {
          try {
            response = await axios.post(PISTON_URL, requestBody(fallbackRuntime), axiosOptions);
          } catch (fallbackError) {
            console.error('=== PISTON ERROR (Fallback) ===');
            console.error('URL called:', PISTON_URL);
            console.error('Payload sent:', JSON.stringify(requestBody(fallbackRuntime), null, 2));
            console.error('Status:', fallbackError.response?.status);
            console.error('Response body:', JSON.stringify(fallbackError.response?.data, null, 2));
            console.error('Message:', fallbackError.message);
            throw fallbackError;
          }
        } else {
          console.error('=== PISTON ERROR ===');
          console.error('URL called:', PISTON_URL);
          console.error('Payload sent:', JSON.stringify(requestBody(primaryRuntime), null, 2));
          console.error('Status:', error.response?.status);
          console.error('Response body:', JSON.stringify(error.response?.data, null, 2));
          console.error('Message:', error.message);
          throw error;
        }
      } else {
        console.error('=== PISTON ERROR ===');
        console.error('URL called:', PISTON_URL);
        console.error('Payload sent:', JSON.stringify(requestBody(primaryRuntime), null, 2));
        console.error('Status:', error.response?.status);
        console.error('Response body:', JSON.stringify(error.response?.data, null, 2));
        console.error('Message:', error.message);
        throw error;
      }
    }

    const { run, compile } = response.data;
    return {
      stdout: run.stdout || '',
      stderr: run.stderr || '',
      signal: run.signal,
      code: run.code,
      compile_stdout: compile?.stdout || '',
      compile_stderr: compile?.stderr || '',
      compile_code: compile?.code,
      compile_status: compile?.status || null,
      compile_message: compile?.message || null,
      time_ms: Math.round((run.wall * 1000) || 0),
      memory_kb: run.memory || 0,
      run_status: run?.status || null,
      run_message: run?.message || null,
    };
  } catch (error) {
    const message = describePistonError(error);
    console.error('Piston execution error:', message);
    throw new Error(`Code execution failed: ${message}`);
  }
}

export async function judgeSubmission(code, language, version, problemId, dbPool) {
  try {
    const problemResult = await dbPool.query('SELECT title FROM problems WHERE id = $1', [problemId]);
    const problemTitle = problemResult.rows[0]?.title || '';
    const executableCode = await buildExecutableCode(problemId, language, code, dbPool);

    const testCasesResult = await dbPool.query(
      'SELECT id, input, expected_output FROM test_cases WHERE problem_id = $1 ORDER BY id ASC',
      [problemId]
    );

    const testCases = testCasesResult.rows;
    if (testCases.length === 0) {
      return {
        verdict: 'accepted',
        passed: 0,
        total: 0,
        time_ms: 0,
        memory_kb: 0,
      };
    }

    let passed = 0;
    let totalTime = 0;
    let maxMemory = 0;
    let verdict = 'accepted';
    let errorMessage = null;
    let stderr = null;
    let errorLine = null;
    let failedCase = null;

    for (const testCase of testCases) {
      try {
        const result = await runAgainstTestCase(executableCode, language, version, testCase.input);

        const compileFailed =
          (result.compile_code !== undefined && result.compile_code !== null && result.compile_code !== 0) ||
          (result.compile_status && result.compile_status !== 'OK');

        if (compileFailed) {
          verdict = 'compilation_error';
          errorMessage =
            result.compile_stderr ||
            result.compile_stdout ||
            result.compile_message ||
            'Compilation failed';
          stderr = result.compile_stderr || result.stderr || null;
          errorLine = extractErrorLine(errorMessage);
          break;
        }

        if (
          result.signal === 'SIGKILL' ||
          result.signal === 'SIGSEGV' ||
          result.run_status === 'TO'
        ) {
          verdict = 'time_limit_exceeded';
          errorMessage = result.run_message || 'Time limit exceeded';
          stderr = result.stderr || result.run_message || null;
          errorLine = extractErrorLine(stderr || errorMessage);
          break;
        }

        if (result.code !== 0) {
          verdict = 'runtime_error';
          errorMessage = result.stderr || 'Runtime error';
          stderr = result.stderr || null;
          errorLine = extractErrorLine(stderr || errorMessage);
          break;
        }

        const actualOutput = normalizeOutput(result.stdout || '');
        const expectedOutput = normalizeOutput(testCase.expected_output || '');

        if (!outputsMatch(problemTitle, expectedOutput, actualOutput)) {
          verdict = 'wrong_answer';
          failedCase = {
            input: testCase.input,
            expected: expectedOutput,
            actual: actualOutput,
          };
          break;
        }

        passed++;
        totalTime += result.time_ms;
        maxMemory = Math.max(maxMemory, result.memory_kb);
      } catch (error) {
        if (error.message.includes('compilation')) {
          verdict = 'compilation_error';
          errorMessage = error.message;
          stderr = error.message;
          errorLine = extractErrorLine(errorMessage);
        } else {
          verdict = 'runtime_error';
          errorMessage = error.message;
          stderr = error.message;
          errorLine = extractErrorLine(errorMessage);
        }
        break;
      }
    }

    return {
      verdict,
      status: toDisplayStatus(verdict),
      passed,
      total: testCases.length,
      time_ms: totalTime,
      memory_kb: maxMemory,
      errorMessage,
      stderr,
      errorLine,
      failedCase,
    };
  } catch (error) {
    console.error('Judge submission error:', error);
    return {
      verdict: 'runtime_error',
      status: toDisplayStatus('runtime_error'),
      passed: 0,
      total: 0,
      time_ms: 0,
      memory_kb: 0,
      errorMessage: error.message,
      stderr: error.message,
      errorLine: extractErrorLine(error.message || ''),
      failedCase: null,
    };
  }
}

export async function runAgainstSampleTestCases(code, language, version, problemId, dbPool) {
  try {
    const problemResult = await dbPool.query('SELECT title FROM problems WHERE id = $1', [problemId]);
    const problemTitle = problemResult.rows[0]?.title || '';
    const executableCode = await buildExecutableCode(problemId, language, code, dbPool);

    const testCasesResult = await dbPool.query(
      'SELECT input, expected_output FROM test_cases WHERE problem_id = $1 AND is_hidden = false ORDER BY id ASC',
      [problemId]
    );

    const testCases = testCasesResult.rows;
    const results = [];

    for (const testCase of testCases) {
      try {
        const runResult = await runAgainstTestCase(executableCode, language, version, testCase.input);

        const compileFailed =
          (runResult.compile_code !== undefined && runResult.compile_code !== null && runResult.compile_code !== 0) ||
          (runResult.compile_status && runResult.compile_status !== 'OK');

        if (compileFailed) {
          results.push({
            input: testCase.input,
            expected: testCase.expected_output,
            actual: '',
            passed: false,
            errorType: 'compilation_error',
            error:
              runResult.compile_stderr ||
              runResult.compile_stdout ||
              runResult.compile_message ||
              'Compilation failed',
            time_ms: 0,
          });
          break;
        }

        const actualOutput = normalizeOutput(runResult.stdout || '');
        const expectedOutput = normalizeOutput(testCase.expected_output || '');
        const passed =
          outputsMatch(problemTitle, expectedOutput, actualOutput) &&
          runResult.code === 0 &&
          runResult.run_status !== 'TO';

        results.push({
          input: testCase.input,
          expected: testCase.expected_output,
          actual: actualOutput,
          passed,
          errorType: runResult.run_status === 'TO' ? 'time_limit_exceeded' : (runResult.code === 0 ? null : 'runtime_error'),
          error: runResult.stderr || runResult.run_message || null,
          time_ms: runResult.time_ms,
        });
      } catch (error) {
        results.push({
          input: testCase.input,
          expected: testCase.expected_output,
          actual: '',
          passed: false,
          errorType: 'runtime_error',
          error: error.message,
          time_ms: 0,
        });
      }
    }

    return results;
  } catch (error) {
    console.error('Sample test case run error:', error);
    throw error;
  }
}

export async function applyContestScoring({ submission, finalVerdict }) {
  if (!submission?.contest_id || !submission?.team_id) {
    return { skipped: true };
  }

  return processContestSubmission({
    submissionId: submission.id,
    userId: submission.user_id,
    problemId: submission.problem_id,
    contestId: submission.contest_id,
    teamId: submission.team_id,
    verdict: finalVerdict,
    submittedAt: submission.created_at,
  });
}
