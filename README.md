# CodeMania — LeetCode-Style Competitive Coding Platform

A real-time team-based competitive coding platform with instant code judging, live leaderboards, and multi-language support. Built with Flutter (web & Android), Node.js/Express, PostgreSQL, Redis, Socket.IO, and Piston API.

## 🚀 Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Frontend | Flutter (web + Android) | 3.13+ |
| Backend | Node.js + Express | 18+ |
| Database | PostgreSQL | 15 |
| Cache | Redis | 7 |
| Realtime | Socket.IO | 4 |
| Code Judge | Piston API (Docker) | Latest |
| Authentication | JWT (HS256) + bcrypt | v4+ |

## 📋 Prerequisites

- **Docker Desktop** (Windows/Mac/Linux)
- **Node.js 18+** with npm
- **Flutter 3.13+** SDK
- **PostgreSQL 15+** (runs in Docker)
- **Redis 7+** (runs in Docker)
- **Git** (optional, for cloning)

## 📁 Project Structure

```
codemania/
├── docker-compose.yml          # Infrastructure setup
├── schema.sql                  # Database schema
├── README.md                   # This file
│
├── backend/
│   ├── package.json            # Node dependencies
│   ├── .env.example            # Environment template
│   ├── index.js                # Express server entry
│   ├── config/
│   │   └── firebase.js         # Firebase initialization
│   ├── middleware/
│   │   ├── auth.js             # Token verification & auto-registration
│   │   └── requireAdmin.js     # Admin access control
│   ├── routes/
│   │   ├── authRoutes.js       # Authentication endpoints
│   │   ├── problemRoutes.js    # Problem CRUD
│   │   ├── contestRoutes.js    # Contest management
│   │   └── submissionRoutes.js # Code submission & judging
│   ├── services/
│   │   ├── judgeService.js     # Piston API integration
│   │   └── leaderboardService.js # Redis leaderboard
│   └── socket/
│       └── contestSocket.js    # Socket.IO real-time events
│
└── flutter_app/
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart           # App entry & auth routing
    │   ├── config.dart         # API & socket URLs
    │   ├── app_theme.dart      # Design system
    │   ├── firebase_options.dart
    │   │
    │   ├── models/
    │   │   ├── user_model.dart
    │   │   ├── problem_model.dart
    │   │   ├── contest_model.dart
    │   │   └── submission_model.dart
    │   │
    │   ├── providers/
    │   │   ├── auth_provider.dart
    │   │   ├── problem_provider.dart
    │   │   ├── submission_provider.dart
    │   │   └── contest_provider.dart
    │   │
    │   ├── services/
    │   │   ├── api_service.dart
    │   │   └── socket_service.dart
    │   │
    │   └── screens/
    │       ├── auth/
    │       │   └── login_screen.dart
    │       ├── user/
    │       │   ├── home_screen.dart
    │       │   ├── problem_list_screen.dart
    │       │   ├── problem_detail_screen.dart
    │       │   └── profile_screen.dart
    │       ├── admin/
    │       │   ├── admin_dashboard.dart
    │       │   ├── create_problem_screen.dart
    │       │   └── create_contest_screen.dart
    │       └── contest/
    │           └── contest_room_screen.dart
```

## 🔧 Installation & Setup

### Step 1: Start Infrastructure (PostgreSQL, Redis, Piston)

```bash
docker-compose up -d
```

Verify all containers are running:
```bash
docker-compose ps
```

**Expected:**
- `codemania-postgres` (port 5432)
- `codemania-redis` (port 6379)
- `codemania-piston` (port 2000)

### Step 2: Install Piston Language Runtimes

Run these once to install supported languages:

```bash
# Python 3.10.0
curl -X POST http://localhost:2000/api/v2/packages \
  -H "Content-Type: application/json" \
  -d '{"language":"python","version":"3.10.0"}'

# C++ 10.2.0
curl -X POST http://localhost:2000/api/v2/packages \
  -H "Content-Type: application/json" \
  -d '{"language":"cpp","version":"10.2.0"}'

# Java 15.0.2
curl -X POST http://localhost:2000/api/v2/packages \
  -H "Content-Type: application/json" \
  -d '{"language":"java","version":"15.0.2"}'

# JavaScript 18.15.0
curl -X POST http://localhost:2000/api/v2/packages \
  -H "Content-Type: application/json" \
  -d '{"language":"javascript","version":"18.15.0"}'

# Verify installation
curl http://localhost:2000/api/v2/runtimes
```

### Step 3: Initialize Database

```bash
psql -U codemania -h localhost -d codemania -f schema.sql
```

**Connection details:**
- Host: `localhost`
- Port: `5432`
- User: `codemania`
- Password: `codemania`
- Database: `codemania`

### Step 4: Configure Backend Environment

1. **Set up environment variables:**
   ```bash
   cd backend
   cp .env.example .env
   ```
   
   Edit `backend/.env`:
   ```env
   PORT=3000
   NODE_ENV=development
   DATABASE_URL=postgresql://codemania:codemania@localhost:5432/codemania
   REDIS_URL=redis://localhost:6379
   JWT_SECRET=codemania_dev_secret_change_in_prod
   PISTON_URL=http://localhost:2000/api/v2/execute
   CLIENT_URL=http://localhost:5000
   SOCKET_CORS_ORIGIN=http://localhost:5000
   ```

2. **Install & start backend:**
   ```bash
   npm install
   node index.js
   ```

   **Expected output:**
   ```
   ✓ Database connected
   ✓ Redis connected
   ✓ Server running on http://localhost:3000
   ✓ Socket.IO server ready for real-time events
   ```

### Step 5: Initialize Admin User

Create an admin account by running:

```bash
cd backend
psql -U codemania -h localhost -d codemania
```

In psql:
```sql
UPDATE users SET role='admin' WHERE email='admin@test.com';
```

Default test credentials: `admin@test.com` / `admin123`

### Step 6: Run Flutter Web (Production-Style Default)

```bash
cd ..
build_and_deploy.bat

# Open in browser
http://localhost:3000

# Optional: Hot reload web development mode
cd flutter_app
flutter run -d chrome --web-port 5000

# Android device
flutter run

# iOS device
flutter run -d framework
```

## 🌐 Expose to External Devices (Optional)

Use [ngrok](https://ngrok.com) to expose your local backend:

```bash
ngrok http 3000
```

Copy the HTTPS URL and run Flutter in hot-reload mode from that host. For release builds served by Express, the app uses the browser origin automatically.

## 📱 Features Implemented

### ✅ User Features
- [x] Google Sign-In with Firebase Auto-Registration
- [x] Browse & filter problems (easy/medium/hard)
- [x] Real-time code editor with syntax highlighting
- [x] Run sample test cases
- [x] Submit solutions for full judgment
- [x] View submission history
- [x] Live contest leaderboards
- [x] Team-based contest participation
- [x] Real-time submission feed

### ✅ Admin Features
- [x] Create problems with multiple test cases
- [x] Create contests with problems
- [x] Generate team join codes
- [x] View all submissions
- [x] Admin dashboard with statistics

### ✅ Backend Features
- [x] Firebase token verification
- [x] PostgreSQL transaction safety
- [x] Piston code judge integration
- [x] Redis leaderboard caching
- [x] Socket.IO real-time events
- [x] Error handling & logging

## 🔌 API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/sync` | Yes | Sync/create user from Firebase |
| GET | `/problems` | Yes | List problems with filters |
| GET | `/problems/:id` | Yes | Get problem + sample cases |
| POST | `/problems` | Admin | Create problem |
| POST | `/submit` | Yes | Submit solution |
| POST | `/submit/run` | Yes | Run sample test cases |
| GET | `/contests` | Yes | List contests |
| GET | `/contests/:id` | Yes | Get contest details |
| POST | `/contests` | Admin | Create contest |
| POST | `/contests/:id/join` | Yes | Join contest team |
| GET | `/contests/:id/leaderboard` | Yes | Get live leaderboard |

## 📊 Database Schema Highlights

### users
- `firebase_uid` (PK): Firebase UID
- `username`: Unique username
- `role`: 'admin' or 'user'
- `rating`: Elo rating (default 1200)

### problems
- Auto-increment ID
- Supports tags array & multiple difficulties
- Test cases linked with ON DELETE CASCADE

### submissions
- Verdict types: `accepted`, `wrong_answer`, `runtime_error`, `time_limit_exceeded`, `compilation_error`
- Tracks time_ms and memory_kb from Piston

### contests
- Status: `upcoming`, `running`, `ended`
- Teams with unique join codes
- Contest-specific leaderboards in Redis (ZSET)

## 🔌 Socket.IO Events

### Client → Server
- `join_contest`: `{ contestId, teamId, userId }`
- `leave_contest`: `{ contestId, teamId }`

### Server → Client
- `submission_result`: Real-time submission verdict
- `leaderboard_update`: Updated team scores
- `team_feed_update`: New submission in team feed

## 📝 Environment Variables

### Backend (.env)
```env
PORT=3000
DATABASE_URL=postgresql://codemania:codemania@localhost:5432/codemania
REDIS_URL=redis://localhost:6379
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
PISTON_URL=http://localhost:2000/api/v2/execute
CLIENT_URL=http://localhost:5000
SOCKET_CORS_ORIGIN=http://localhost:5000
PISTON_RUN_TIMEOUT=3000
PISTON_COMPILE_TIMEOUT=10000
PISTON_MEMORY_LIMIT=128000
```

### Flutter (config.dart)
```dart
const String apiBaseUrl = 'http://localhost:3000';
const String socketUrl  = 'http://localhost:3000';
```

## 🐛 Troubleshooting

### Docker Containers Won't Start
```bash
docker system prune -a
docker-compose up -d --rebuild
```

### Database Connection Error
```bash
# Check PostgreSQL logs
docker logs codemania-postgres

# Verify connection
psql -U codemania -h localhost -d codemania -c "SELECT 1"
```

### Piston Not Responding
```bash
# Check runtimes
curl http://localhost:2000/api/v2/runtimes

# Check logs
docker logs codemania-piston
```

### Firebase Auth Issues
- Verify `serviceAccountKey.json` is properly placed in `backend/`
- Check Firebase Console → Authentication → Sign-in methods
- Ensure Google Sign-In is enabled

### Flutter Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

## 🎯 Next Steps / Future Enhancements

- [ ] User upvotes/downvotes on problems
- [ ] Discussion forum for each problem
- [ ] Automated contest scheduling
- [ ] Global rankings & achievements
- [ ] Code plagiarism detection
- [ ] Problem difficulty calibration
- [ ] Mobile app (native iOS implementation)
- [ ] Collaborative coding sessions
- [ ] Video editorials for problems
- [ ] Docker image registry

## 📄 License

MIT License — Free to use, modify, and distribute.

## 👥 Contributing

Contributions welcome! Submit issues and pull requests on GitHub.

---

**Happy Coding! 🚀**
