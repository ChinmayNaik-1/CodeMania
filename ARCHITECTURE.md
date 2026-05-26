# CodeMania Architecture Overview

## System Design

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Web & Android Frontend              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Riverpod State Management (auth, problems, contests)        │ │
│  │ - AuthProvider: JWT token + SharedPreferences persistence  │ │
│  │ - ProblemProvider: Problem fetch & filtering              │ │
│  │ - ContestProvider: Real-time leaderboards                │ │
│  │ - SubmissionProvider: Code execution & judging           │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                    │                          │                    │
└────────────────────┼──────────────────────────┼────────────────────┘
                     │ Dio HTTP Client           │ Socket.IO Client
                     │ (with JWT Auth)           │ (with WebSocket)
                     ▼                           ▼
    ┌────────────────────────────────────────────────┐
    │    Node.js Express Server (Port 3000)         │
    │  ┌──────────────────────────────────────────┐ │
    │  │ Middleware Layer                         │ │
    │  │ - authMiddleware: JWT verification      │ │
    │  │ - requestLogger: API logging             │ │
    │  └──────────────────────────────────────────┘ │
    │  ┌──────────────────────────────────────────┐ │
    │  │ Routes (REST API)                        │ │
    │  │ POST /auth/register, /auth/login         │ │
    │  │ GET  /auth/me, /problems, /contests      │ │
    │  │ POST /problems, /submissions             │ │
    │  └──────────────────────────────────────────┘ │
    │  ┌──────────────────────────────────────────┐ │
    │  │ Services                                  │ │
    │  │ ├─ judgeService: Piston code execution │ │
    │  │ └─ leaderboardService: Redis updates    │ │
    │  └──────────────────────────────────────────┘ │
    │  ┌──────────────────────────────────────────┐ │
    │  │ Socket.IO (Real-time events)            │ │
    │  │ Contest rooms: join/leave/submit        │ │
    │  │ Events: submission_result, leaderboard  │ │
    │  └──────────────────────────────────────────┘ │
    └────┬─────────┬────────────┬──────────┬────────┘
         │         │            │          │
         ▼         ▼            ▼          ▼
    ┌─────────┐ ┌──────┐ ┌─────────┐ ┌──────────┐
    │PostgreSQL│ │Redis │ │Postgres │ │ Piston   │
    │   15     │ │  7   │ │   15    │ │ API      │
    │ Accounts │ │Cache │ │Problems │ │(Compile  │
    │ Password │ │lease │ │ Contest │ │ & Run)   │
    │  Hashes  │ │board │ │Submissio│ │Languages │
    │  Roles   │ │UID   │ │Test Case│ │          │
    └─────────┘ └──────┘ └─────────┘ └──────────┘
```

## Data Flow: Code Submission

### 1. User Submits Code
```
Frontend User Input
       │
       ▼
Submission Provider (Riverpod)
       │
       ├─ POST /submit with:
       │  - problemId
       │  - contestId (optional)
       │  - teamId (optional)
       │  - language, version, code
       │
       ▼
Backend /submit Route
       │
       ├─ Verify JWT token (authMiddleware)
       ├─ Call judgeService.judgeSubmission()
       │  │
       │  ├─ Fetch test cases from DB
       │  ├─ Loop each test case:
       │  │  ├─ POST to Piston API
       │  │  ├─ Check verdict (timeout/error/output)
       │  │  └─ Increment passed count
       │  │
       │  └─ Return { verdict, passed, total }
       │
       ├─ INSERT submission into DB
       │
       ├─ If verdict == 'accepted' AND contestId:
       │  │
       │  ├─ UPDATE leaderboard:{contestId} in Redis (ZADD)
       │  ├─ Emit 'submission_result' to Socket.IO room
       │  └─ Emit 'leaderboard_update' to all team
       │
       └─ Return { submissionId, verdict, ... }
              │
              ▼
        Frontend shows verdict
        Real-time leaderboard updates via Socket.IO
```

## Authentication Flow

### First-Time User (Auto-Registration)
```
1. User taps "Sign in with Google"
   └─ Flutter: google_sign_in → GoogleAuthProvider
   
2. Backend /auth/google endpoint receives googleIdToken
   └─ Backend: Verifies with Google API
   └─ Returns JWT token (httpOnly cookie)

3. Frontend stores JWT token (from cookie)

4. POST /auth/sync with JWT in Authorization header
   └─ Backend authMiddleware:
      · verifyJWT(token) → google_uid, email
      · Query users table
      · If NOT exists → INSERT users (auto-register)
      · RETURN user record with role, rating
   
5. Frontend Riverpod authProvider updates state
   └─ IF role == 'admin' → AdminDashboard
   └─ IF role == 'user' → HomeScreen
```

### Subsequent Logins
```
1. User signs in again (JWT persisted in httpOnly cookie)
2. Frontend automatically includes JWT in requests
3. Riverpod authProvider fetches appUser data from DB
4. Role determines routing
```

## Real-Time Updates (Socket.IO)

### Contest Room Connection
```
User joins contest_room_screen.dart
       │
       ├─ SocketService.connect()
       │  └─ Handshake with Socket.IO server (with Bearer token)
       │
       └─ SocketService.joinContest(contestId, teamId, userId)
          └─ Server emits 'contest_joined'

Socket.IO Room Architecture:
├─ contest:{contestId}              (all users in this contest)
└─ contest:{contestId}:team:{teamId} (team-specific events)
```

### Submission Result Broadcasting
```
User submits code
       │
       ▼
judgeService completes → verdict = 'accepted'
       │
       ├─ Redis: ZADD leaderboard:{contestId} score teamId
       ├─ DB: INSERT into submissions
       │
       └─ Socket emit to room 'contest:{contestId}'
          ├─ Event: 'submission_result'
          │  └─ { userId, username, problemId, verdict, ... }
          └─ Event: 'leaderboard_update'
             └─ { teams: [{ teamId, score, solvedCount }, ...] }
                  (sorted by score DESC)
```

### Leaderboard Scoring
```
Redis ZSET: leaderboard:{contestId}
├─ Member: teamId (string)
└─ Score: accumulated points

When team solves problem:
├─ Fetch points from contest_problems table
├─ ZADD leaderboard:{contestId} points teamId
├─ ZREVRANGE to get top 100 sorted by score DESC
└─ Emit to Socket.IO room

Benefits:
├─ O(1) score update (ZADD)
├─ O(log N) sorted retrieval (ZREVRANGE)
└─ Auto-expires after 30 days
```

## Code Judging (Piston Integration)

### Piston API Call
```
POST http://localhost:2000/api/v2/execute

Request:
{
  "language": "python",
  "version": "3.10.0",
  "files": [
    {
      "name": "solution",
      "content": "user code here"
    }
  ],
  "stdin": "test input",
  "run_timeout": 3000,
  "compile_timeout": 10000,
  "run_memory_limit": 128000
}

Response:
{
  "run": {
    "stdout": "output",
    "stderr": "errors (if any)",
    "code": 0,
    "signal": null,
    "memory": 1024,
    "wall": 0.05
  },
  "language": "python",
  "version": "3.10.0"
}

Verdict Logic:
├─ signal === 'SIGKILL' → 'time_limit_exceeded'
├─ code !== 0 → 'runtime_error'
├─ stdout !== expected → 'wrong_answer'
└─ all match → 'accepted'
```

## Database Transactions

### Create Problem (Multi-step)
```
BEGIN;
├─ INSERT INTO problems (title, description, ...)
│  └─ RETURNING id → problemId
├─ FOR EACH test case:
│  └─ INSERT INTO test_cases (problem_id, input, expected_output, ...)
└─ COMMIT;

ON ERROR: ROLLBACK;
```

Result: Atomic operation — either all succeed or none do.

## Caching Strategies

### Redis Keys
```
leaderboard:{contestId}
├─ Type: ZSET
├─ Members: teamId
├─ Scores: accumulated points
└─ TTL: 30 days

team:{contestId}:{teamId}:solved
├─ Type: STRING (integer counter)
├─ Value: number of problems solved
└─ TTL: 30 days
```

### Why Redis?
```
1. Leaderboard updates per submission (high write)
   └─ PostgreSQL: would be bottleneck
   └─ Redis ZADD: O(log N) with in-memory speed

2. Real-time rank queries
   └─ ZREVRANGE O(log N + M) vs TABLE SORT O(N log N)

3. Auto-expiry
   └─ Contest leaderboards auto-cleanup
```

## API Security

### Token Flow
```
1. Frontend: Get JWT from httpOnly cookie (auto-attached by browser)
   └─ Expires: 3 hours (configurable)

2. Dio Interceptor: Attach to every request
   └─ Authorization: Bearer <JWT>

3. Backend authMiddleware:
   └─ Extract token from header
   └─ Call verifyJWT(token) with secret key
   └─ Get google_uid, email, role
   └─ Attach to req.user

4. Routes access req.user data
   └─ No SQL injection (parameterized queries $1, $2)
   └─ No privilege escalation (requireAdmin checks role)
```

### Error Handling
```
All routes wrapped in try/catch:
├─ 400: Invalid input
├─ 401: Missing/invalid token
├─ 403: Admin access required
├─ 404: Resource not found
└─ 500: Server error

Response format:
{
  "error": "Human readable message",
  "code": "MACHINE_ERROR_CODE"
}
```

## Scalability Considerations

### Current Architecture (Single Instance)
```
✓ Supports ~10-50 concurrent users
✓ Single Node.js process
✓ PostgreSQL connection pool (20 max)
✓ Redis single instance
✓ Piston single instance
```

### Future Scaling (Cloud Ready)
```
1. Node.js Clustering
   ├─ npm package: cluster or PM2
   └─ Horizontal load balancer (nginx)

2. Session Sharing
   ├─ Store sessions in Redis (not memory)
   └─ Socket.IO adapters: redis adapter

3. Database
   ├─ PostgreSQL replication
   ├─ Read replicas for queries
   └─ Write primary for submissions

4. Code Judge
   ├─ Multiple Piston instances
   ├─ Queue system (Bull.js with Redis)
   └─ Load balancing across workers

5. CDN
   ├─ Serve Flutter web from CDN
   ├─ API calls → CloudFlare Workers
   └─ Static assets cached globally
```

## File Size & Performance

### Backend Code (without node_modules)
```
index.js:                   ~50 KB
routes/                     ~60 KB
services/                   ~40 KB
middleware/                 ~10 KB
config/                     ~5 KB
Total Backend:             ~165 KB
```

### Flutter Code
```
main.dart:                  ~10 KB
models/                     ~25 KB
providers/                  ~45 KB
services/                   ~20 KB
screens/                    ~150 KB
Total Flutter:             ~250 KB
```

### Build Artifacts
```
Node: node_modules/        ~500 MB (npm dependencies)
Flutter: build/             ~100 MB (web build)
         .dart_tool/        ~300 MB (build cache)
```

## Time Complexity Reference

| Operation | Backend | Time | Notes |
|-----------|---------|------|-------|
| Fetch problems | Query + filter | O(N) | Index on difficulty, tags |
| Get problem detail | Query by ID | O(1) | PK index |
| Save submission | DB insert | O(1) | Single row |
| Judge code | Piston API + loop | O(M) | M = test cases |
| Update leaderboard | Redis ZADD | O(log N) | N = teams |
| Get leaderboard | Redis ZREVRANGE | O(log N + K) | K = top 100 |
| Sync user | Query + insert | O(1) | PK/unique index |

---

**Architecture designed for:**
- ✓ Learning competitive programming
- ✓ Team-based contests
- ✓ Real-time collaboration
- ✓ Fair code judging
- ✓ Fast feedback loops
