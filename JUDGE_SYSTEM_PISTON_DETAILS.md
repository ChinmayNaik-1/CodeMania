# CodeMania Judge System (Piston API) - Full Technical Detail

## 1. Scope
This document covers only the online judge subsystem that executes user code through Piston and returns verdicts.

In scope:
- Code execution via Piston
- Submission judging flow
- Sample test run flow
- Verdict and failure classification
- Data persisted for submissions
- Real-time contest side effects triggered by accepted submissions
- Runtime limits and environment controls

Out of scope:
- Authentication implementation details (except where needed for judge routes)
- Problem authoring/admin UI
- Google auth UI flow

## 2. Where Judge Logic Lives
Backend files involved:
- backend/services/judgeService.js
- backend/routes/submissionRoutes.js
- backend/index.js
- backend/middleware/auth.js
- backend/socket/contestSocket.js
- schema.sql
- backend/.env.example

## 3. High-Level Architecture
1. Client sends code to backend route.
2. Backend validates payload and auth.
3. Judge service fetches test cases from PostgreSQL.
4. For each test case, backend calls Piston execute API.
5. Backend classifies result into verdict.
6. Backend stores submission row.
7. If accepted inside contest context, leaderboard/team feed events are emitted.

Core external dependency:
- Piston execute endpoint from env: PISTON_URL (default http://localhost:2000/api/v2/execute)

## 4. API Endpoints Used by Judge
Both routes are protected by auth middleware.

### 4.1 POST /submit
File: backend/routes/submissionRoutes.js

Purpose:
- Full judging against all test cases
- Persists submission record
- Triggers contest scoring/events when accepted

Expected body fields:
- problemId
- contestId (optional)
- teamId (optional)
- language
- version
- code

Validation:
- Missing required fields returns HTTP 400 with code INVALID_INPUT

Response on success (201):
- submissionId
- verdict
- passed
- total
- errorMessage
- failedCase

### 4.2 POST /submit/run
File: backend/routes/submissionRoutes.js

Purpose:
- Run only sample test cases (is_sample = true)
- Intended for quick feedback before final submit

Expected body fields:
- problemId
- language
- version
- code

Response on success (200):
- results array (per-sample output)
- run_error (first surfaced error)
- run_error_type

## 5. Piston Request Contract in This Project
File: backend/services/judgeService.js
Function: runAgainstTestCase(code, language, version, stdin)

Backend sends this payload to Piston:
- language
- version
- files:
  - name: solution
  - content: submitted code
- stdin: test case input
- run_timeout: from PISTON_RUN_TIMEOUT (default 3000 ms)
- compile_timeout: from PISTON_COMPILE_TIMEOUT (default 10000 ms)
- run_memory_limit: from PISTON_MEMORY_LIMIT (default 128000 KB)

Backend reads these fields from Piston response:
- run.stdout
- run.stderr
- run.signal
- run.code
- run.wall (converted to time_ms)
- run.memory (as memory_kb)
- compile.stdout
- compile.stderr
- compile.code

Normalized result object returned inside backend:
- stdout
- stderr
- signal
- code
- compile_stdout
- compile_stderr
- compile_code
- time_ms
- memory_kb

## 6. Full Judge Algorithm (Final Submit)
File: backend/services/judgeService.js
Function: judgeSubmission(code, language, version, problemId, dbPool)

Sequence:
1. Query all test cases for problem:
   SELECT id, input, expected_output
   FROM test_cases
   WHERE problem_id = $1
   ORDER BY is_sample DESC, id ASC

2. Initialize counters and state:
   - passed = 0
   - totalTime = 0
   - maxMemory = 0
   - verdict = accepted

3. Loop through test cases one by one and execute in Piston.

4. Decision rules (first failing rule stops loop):
   - If compile_code exists and compile_code != 0:
     verdict = compilation_error
   - Else if signal is SIGKILL or SIGSEGV:
     verdict = time_limit_exceeded
   - Else if run exit code != 0:
     verdict = runtime_error
   - Else compare output with exact trimmed string equality:
     expected_output.trim() == stdout.trim()
     if not equal -> verdict = wrong_answer
   - Else test case passed, aggregate time and memory.

5. Return aggregate result:
   - verdict
   - passed
   - total
   - time_ms (sum of passed test run times)
   - memory_kb (max across passed tests)
   - errorMessage
   - failedCase (input, expected, actual when wrong_answer)

No-test-case behavior:
- If problem has zero test cases, function returns accepted with zero counts.

## 7. Sample Run Algorithm (Run Button)
File: backend/services/judgeService.js
Function: runAgainstSampleTestCases(...)

Sequence:
1. Query only sample cases:
   SELECT input, expected_output
   FROM test_cases
   WHERE problem_id = $1 AND is_sample = true
   ORDER BY id ASC

2. Execute each sample case via Piston.

3. For each case, append:
   - input
   - expected
   - actual
   - passed
   - errorType
   - error
   - time_ms

4. If compilation fails in a sample case, push compilation_error result and stop further sample execution.

## 8. Verdict Mapping in Current Implementation
Possible verdict values produced by judge service:
- accepted
- wrong_answer
- runtime_error
- compilation_error
- time_limit_exceeded

How they are detected:
- compilation_error: compile.code non-zero
- time_limit_exceeded: signal SIGKILL or SIGSEGV
- runtime_error: run.code non-zero, or internal execution exception
- wrong_answer: trimmed stdout != trimmed expected_output
- accepted: all tested cases pass

## 9. Persistence Model
File: schema.sql
Table: submissions

Stored columns relevant to judge:
- user_id
- problem_id
- contest_id
- team_id
- language
- language_version
- code
- verdict
- passed_cases
- total_cases
- time_ms
- memory_kb
- created_at

Current route writes:
- verdict, passed_cases, total_cases in POST /submit
- time_ms and memory_kb exist in schema but are not currently inserted by submission route

Test case source table:
- test_cases(problem_id, input, expected_output, is_sample)

Contest scoring source table:
- contest_problems(contest_id, problem_id, points)

## 10. Contest Side Effects on Accepted Submissions
File: backend/routes/submissionRoutes.js

When verdict is accepted and both contestId + teamId are present:
1. Read points from contest_problems, default 100.
2. Update team score in leaderboard service.
3. Increment solved count in leaderboard service.
4. Emit websocket events:
   - submission_result
   - leaderboard_update
   - team_feed_update
5. Publish contest event via Redis/event layer.

This does not happen for non-accepted verdicts.

## 11. Runtime and Capacity Controls
File: backend/.env.example

Judge tunables:
- PISTON_URL
- PISTON_RUN_TIMEOUT
- PISTON_COMPILE_TIMEOUT
- PISTON_MEMORY_LIMIT

Default values in project template:
- PISTON_URL = http://localhost:2000/api/v2/execute
- PISTON_RUN_TIMEOUT = 3000
- PISTON_COMPILE_TIMEOUT = 10000
- PISTON_MEMORY_LIMIT = 128000

## 12. Error Handling Behavior
Piston call layer:
- Network/API errors are caught in runAgainstTestCase and re-thrown as Code execution failed: <message>

Judge loop:
- Execution exceptions become runtime_error unless explicitly detected as compilation-related

Route layer:
- POST /submit failures return HTTP 500 with SUBMIT_ERROR
- POST /submit/run failures return HTTP 500 with RUN_ERROR

## 13. Security and Isolation Notes
- Execution is delegated to Piston service, which isolates code execution externally from main app process.
- Backend never runs user code directly.
- Judge routes require Bearer token auth.
- Inputs are DB-driven test case strings; outputs compared server-side.

## 14. Operational Dependencies Required for Judge to Work
Required services:
- PostgreSQL (problem/test case/submission data)
- Redis (contest event and leaderboard related side effects)
- Piston API service
- Backend API server

Health checks to run:
- GET /health on backend
- Piston endpoint reachable at configured PISTON_URL
- test_cases exist for selected problem_id

## 15. Current Implementation Notes to Keep in Mind
1. Output matching is exact after trim (no tolerant numeric or whitespace strategy beyond edge trim).
2. time_ms and memory_kb are calculated by judge service but not persisted in current insert statement.
3. The submit route uses req.user.firebase_uid for user_id insertion, while auth middleware populates req.user.id. This should be verified for consistency with submissions.user_id type and your auth data model.
4. Leaderboard member query in socket layer joins team_members.user_id to users.firebase_uid; this should be validated against schema fields in use.

## 16. End-to-End Trace Example
Final submit path:
1. Client calls POST /submit with code + language + version + problemId.
2. Auth middleware validates token and loads user.
3. judgeSubmission fetches all test cases.
4. Each case executed through Piston.
5. First failure determines verdict; otherwise accepted.
6. Submission row inserted.
7. If contest accepted, score and sockets are updated.
8. JSON verdict payload returned to client.

Sample run path:
1. Client calls POST /submit/run.
2. Auth validated.
3. Only sample cases are executed via Piston.
4. Per-case results returned without creating final judged contest result.

## 17. Quick Troubleshooting (Judge Only)
If all submissions fail immediately:
- Verify PISTON_URL and Piston container availability.
- Check backend logs for Piston execution error messages.

If compile errors appear unexpectedly:
- Validate language and version requested from frontend match supported Piston runtime values.

If accepted code marked wrong_answer:
- Inspect expected_output formatting in test_cases table.
- Remember comparison uses trimmed exact string equality.

If contest accepted submissions do not update leaderboard:
- Confirm contestId and teamId are present in submit payload.
- Verify Redis and socket setup are healthy.
