# 🎯 CodeMania Quick Reference

## Essential Commands

### 🐋 Docker Management
```bash
# Start all services (PostgreSQL, Redis, Piston)
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart postgres    # postgres, redis, or piston
```

### 🗄️ Database Operations
```bash
# Connect to PostgreSQL
psql -U codemania -h localhost -d codemania

# Initialize database
psql -U codemania -h localhost -d codemania -f schema.sql

# View tables
\dt

# Make user admin
UPDATE users SET role='admin' WHERE email='your-email@gmail.com';

# Clear all data (reset)
DROP SCHEMA public CASCADE; CREATE SCHEMA public;
psql -U codemania -h localhost -d codemania -f schema.sql
```

### 🟩 Backend (Node.js)
```bash
cd backend

# First time setup
npm install

# Start server
node index.js

# With nodemon (auto-reload on changes)
npx nodemon index.js

# Production start
NODE_ENV=production node index.js
```

### 📱 Frontend (Flutter)
```bash
cd flutter_app

# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android device
flutter run

# Build for release
flutter build web --release
flutter build apk --release
```

### 🧪 Testing
```bash
# Test an endpoint (requires backend running)
curl http://localhost:3000/health

# Get all problems
curl http://localhost:3000/problems

# Get token from Google Sign-In and test auth
curl -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  http://localhost:3000/auth/sync
```

---

## 🏗️ Project Structure

```
codemania/
├── backend/                 # Node.js Express server
│  ├── index.js             # Main entry point
│  ├── package.json         # Dependencies
│  ├── .env                 # Environment variables (PostgreSQL password, etc.)
│  ├── config/              # Configuration
│  ├── middleware/          # Auth, admin gates
│  ├── routes/              # API endpoints
│  ├── services/            # Business logic (judging, leaderboard)
│  └── socket/              # Real-time events
│
├── flutter_app/            # Flutter frontend
│  ├── lib/
│  │  ├── main.dart        # App entry point
│  │  ├── config.dart      # API URL config
│  │  ├── models/          # Data models
│  │  ├── providers/       # Riverpod state
│  │  ├── services/        # API & Socket.IO
│  │  └── screens/         # UI screens
│  ├── pubspec.yaml        # Dependencies
│  └── web/                # Web build output
│
├── schema.sql             # Database schema
├── docker-compose.yml     # Infrastructure setup
├── README.md              # Setup guide
├── ARCHITECTURE.md        # System design
├── DEPLOYMENT.md          # Production guide
└── PROJECT_SUMMARY.md     # This overview
```

---

## 🔑 Environment Variables

**Create `backend/.env`:**

```bash
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=codemania
DB_USER=codemania
DB_PASSWORD=change_this_in_prod  # Change from docker-compose!

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Firebase
FIREBASE_SERVICE_ACCOUNT_KEY_PATH=./serviceAccountKey.json

# Piston (Code Judge)
PISTON_API_URL=http://localhost:2000

# Server Port
PORT=3000
NODE_ENV=development
```

**Firebase (`serviceAccountKey.json`):**
1. Go to Firebase Console → Project Settings
2. Service Accounts tab
3. Click "Generate New Private Key"
4. Save as `backend/serviceAccountKey.json`

---

## 🔗 API Endpoints Reference

| Method | Endpoint | Auth | Role | Purpose |
|--------|----------|------|------|---------|
| POST | `/auth/sync` | Firebase | User | Sync/register user |
| GET | `/problems` | - | - | List problems (filterable) |
| GET | `/problems/:id` | - | - | Get problem detail |
| POST | `/problems` | Firebase | Admin | Create problem |
| PUT | `/problems/:id` | Firebase | Admin | Update problem |
| POST | `/problems/:id/testcases` | Firebase | Admin | Add test cases |
| POST | `/submit` | Firebase | User | Submit code for judging |
| POST | `/submit/run` | Firebase | User | Run against samples only |
| GET | `/submit` | Firebase | User | Get submissions history |
| GET | `/contests` | - | - | List contests |
| GET | `/contests/:id` | - | - | Get contest detail |
| POST | `/contests` | Firebase | Admin | Create contest |
| POST | `/contests/:id/teams` | Firebase | Admin | Create team |
| POST | `/contests/:id/join` | Firebase | User | Join contest with code |
| GET | `/contests/:id/leaderboard` | - | - | Get leaderboard |

---

## 🔌 Socket.IO Events Reference

**Client Sends:**
- `join_contest` → Request access to contest room
- `leave_contest` → Exit contest

**Server Sends:**
- `submission_result` → Verdict of code submission
- `leaderboard_update` → Team scores changed
- `team_feed_update` → New submission in team feed

---

## 🗂️ File Modifications Guide

### Want to change API URL?
```dart
// flutter_app/lib/config.dart
const String API_BASE_URL = 'http://localhost:3000';  // Change here
const String SOCKET_URL = 'http://localhost:3000';
```

### Want to change database?
```sql
-- schema.sql - Add new column
ALTER TABLE problems ADD COLUMN new_column VARCHAR(255);

-- Then export & reimport
pg_dump -U codemania codemania > backup.sql
psql -U codemania -d codemania -f schema.sql
```

### Want to add new API route?
```javascript
// backend/routes/problemRoutes.js
router.get('/myroute', auth, async (req, res) => {
  try {
    // Your code
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Then in backend/index.js
app.use('/problems', require('./routes/problemRoutes'));
```

### Want to add new Flutter screen?
```dart
// flutter_app/lib/screens/user/new_screen.dart
import 'package:flutter/material.dart';

class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Screen')),
      body: Center(child: Text('Your content here')),
    );
  }
}
```

---

## 🐛 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| `psql: error: connection refused` | Run `docker-compose up -d` first |
| `Firebase: invalid token` | Download new `serviceAccountKey.json` |
| `Flutter: package not found` | Run `flutter pub get` |
| `Port 3000 already in use` | `lsof -i :3000` → `kill <PID>` |
| `Redis connection failed` | Check `docker logs codemania-redis` |
| `Piston not responding` | Check Docker networking: `docker network ls` |
| `CORS errors` | Add CORS to Express (already done in index.js) |
| `Socket.IO not connecting` | Check firewall for port 3000 |

---

## 📊 Performance Tips

### Backend
- Keep queries under 100ms
- Use indexes for WHERE clauses
- Connection pooling: 20 max
- Cache contest data in Redis 30 days

### Frontend  
- Use `const` where possible (Riverpod caching)
- Lazy-load screens
- Cache images with `cached_network_image`
- Pagination on lists (10 items per page)

### Database
- Regular backups every day
- Monitor slow queries: `SET log_min_duration_statement = 1000;`
- Vacuum regularly: `VACUUM ANALYZE;`

---

## 🚀 Deployment Checklist

Before going live:

- [ ] Change PostgreSQL password in docker-compose.yml
- [ ] Generate new Firebase service account key
- [ ] Setup HTTPS with Let's Encrypt
- [ ] Point domain to your server
- [ ] Update Flutter config.dart with production URL
- [ ] Update backend .env with production database
- [ ] Setup monitoring (Sentry, Datadog)
- [ ] Setup automated backups
- [ ] Load test with 100+ concurrent users
- [ ] Setup CI/CD pipeline

---

## 💡 Architecture Quick View

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Web/Mobile                   │
│  (User Interface, Riverpod State Management)         │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP/WebSocket
┌──────────────────▼──────────────────────────────────┐
│             Express.js Server:3000                    │
│  (Auth, Routes, Business Logic, Socket.IO)          │
└──┬─────────────────┬──────────────────┬────────────┘
   │                 │                  │
   ▼                 ▼                  ▼
┌──────────┐  ┌────────────┐  ┌────────────────┐
│PostgreSQL│  │   Redis    │  │  Piston:2000   │
│   :5432  │  │   :6379    │  │  (Code Judge)  │
└──────────┘  └────────────┘  └────────────────┘
```

---

## 📚 Key Design Patterns Used

1. **Middleware Pattern** - Auth, error handling
2. **Singleton Pattern** - Database pool, Redis client, Dio
3. **Repository Pattern** - SQL queries isolated in services
4. **State Notifier Pattern** - Riverpod for reactive UI
5. **Pub/Sub Pattern** - Redis for distributed events
6. **Circuit Breaker** - Piston timeout handling

---

## ✅ Status Check

Before starting, verify:

```bash
# PostgreSQL
docker-compose exec postgres psql -U codemania -c "SELECT 1"

# Redis
docker-compose exec redis redis-cli ping

# Piston
curl http://localhost:2000/api/v2/runtimes

# Backend
curl http://localhost:3000/health

# Flutter
flutter doctor
```

---

## 🔗 Useful Links

- Firebase Console: https://console.firebase.google.com
- Piston API Docs: https://piston.readthedocs.io
- Socket.IO Docs: https://socket.io/docs
- PostgreSQL Docs: https://www.postgresql.org/docs
- Flutter Docs: https://flutter.dev
- Riverpod Docs: https://riverpod.dev

---

## 🎓 Learning Paths

**If you're new to:**

- **Flutter**: Start with screens/ directory, then models/, then providers/
- **Node.js**: Start with index.js, then routes/, then services/
- **PostgreSQL**: Use the schema.sql as reference, play in psql console
- **Socket.IO**: Check contestSocket.js for event patterns
- **Firebase**: Login/registration is auto-handled, just sync user data

---

## 🆘 Getting Help

1. Check error messages in terminal/console
2. Look at logs: `docker-compose logs -f`
3. Read DEPLOYMENT.md troubleshooting section
4. Check Firebase Console for auth errors
5. Monitor Piston API directly: `curl http://localhost:2000`

---

**Last Updated:** Today  
**Status:** Production Ready  
**Version:** 1.0.0
