# 🚀 CodeMania MVP Startup Guide

## Quick Start (5 minutes)

### Prerequisites
- ✅ Docker installed (for PostgreSQL, Redis, Piston)
- ✅ Node.js 18+ installed
- ✅ Flutter SDK installed
- ✅ Chrome browser (for Flutter web)

---

## Step 1: Start Infrastructure (Docker)

```powershell
cd d:\MAD\codemania
docker-compose up -d
```

**Verify all services started:**
```powershell
docker-compose ps
```

Should show:
- ✅ postgres (port 5432)
- ✅ redis (port 6379)
- ✅ piston (port 2000)

---

## Step 2: Initialize Database

```powershell
# Reset database schema
Get-Content schema.sql | docker-compose exec -T postgres psql -U codemania -d codemania

# Create test user (admin)
docker-compose exec -T postgres psql -U codemania -d codemania -c "UPDATE users SET role='admin' WHERE email='admin@test.com';"
```

**Test credentials created:**
- Email: `admin@test.com`
- Password: `admin123`
- Role: `admin`

---

## Step 3: Start Backend Server

**Open a NEW PowerShell terminal:**

```powershell
cd d:\MAD\codemania\backend
node index.js
```

**You should see:**
```
✓ Database connected
✓ Redis connected
✓ Server running on http://localhost:3000
✓ Socket.IO server ready for real-time events
✓ Piston Judge API: http://localhost:2000/api/v2/execute
```

**Verify backend health:**
```powershell
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

---

## Step 4: Build and Serve Flutter Web via Express (Default)

**Open a NEW PowerShell terminal:**

```powershell
cd d:\MAD\codemania
.\build_and_deploy.bat
```

This command builds Flutter in release mode and copies the output to `backend/public`.

Now open the app from Express:

```
http://localhost:3000
```

### Optional: Hot Reload Development Mode

Use this only when actively iterating on UI:

```powershell
# One-line (recommended)
Set-Location D:\MAD\codemania\flutter_app; flutter run -d chrome --web-port 5000
```

```powershell
# Two-line (equivalent)
cd D:\MAD\codemania\flutter_app
flutter run -d chrome --web-port 5001
```

If port 5000 is busy, run this first and then start again:

```powershell
Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object { Stop-Process -Id $_ -Force }
```

Common mistakes:
- Use `cd`, not `d`.
- In PowerShell, local scripts must use `.\` (for example `.\build_and_deploy.bat`).
- Run Flutter commands from `D:\MAD\codemania\flutter_app` (folder that contains `pubspec.yaml`).

When done, run `build_and_deploy.bat` again to test production behavior.

---

## Step 5: Test Login

On the Flutter app that opened in Chrome:

1. **Email field:** `admin@test.com`
2. **Password field:** `admin123`
3. **Click "Login"**

**Expected behavior:**
- ✅ Loading spinner appears briefly
- ✅ Redirects to **AdminDashboard** (you're admin)
- ✅ Can see "CodeMania" header with your username

---

## Step 6: Test Registration (Optional)

1. **Return to login screen** (click logout in top-right)
2. **Click "Register" tab**
3. Fill in:
   - Username: `newuser123`
   - Email: `newuser@example.com`
   - Password: `password123`
4. **Click Register**

**Expected behavior:**
- ✅ New user created
- ✅ Auto-logged in to regular **HomeScreen**

---

## Troubleshooting

### Backend won't start
```powershell
# Check if port 3000 is in use
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

# Kill process using port 3000
Get-NetTCPConnection -LocalPort 3000 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# Try again
node index.js
```

### Flutter build or copy failed
```powershell
cd d:\MAD\codemania\flutter_app
flutter clean
flutter pub get
cd ..
.\build_and_deploy.bat
```

### Database connection failed
```powershell
# Check if containers running
docker-compose ps

# If not, restart
docker-compose down
docker-compose up -d

# Reinitialize schema
Get-Content schema.sql | docker-compose exec -T postgres psql -U codemania -d codemania
```

### Login spinner hangs forever
1. **Open Chrome DevTools** (F12)
2. **Go to Console tab**
3. Look for red errors starting with `📡`
4. Check Network tab for failed requests
5. Verify backend is running on port 3000

---

## Architecture Overview

```
┌──────────────────────────────────────────┐
│   Flutter Web Release (served by Express)│
│   - Login/Register UI                    │
│   - Riverpod state management            │
│   - SharedPreferences for tokens         │
└────────────────┬─────────────────────────┘
                 │ HTTP/WebSocket
┌────────────────▼─────────────────────────┐
│   Express Backend (localhost:3000)       │
│   - JWT authentication                   │
│   - REST API endpoints                   │
│   - Socket.IO real-time events           │
└────────────────┬─────────────────────────┘
                 │
      ┌──────────┼──────────────┬─────────┐
      │          │              │         │
      ▼          ▼              ▼         ▼
  PostgreSQL   Redis        Piston    Socket
  :5432        :6379        :2000     .IO
  (Users,      (Leaderboard(Code
  Problems)    Cache)      Judge)
```

---

## API Endpoints

### Authentication
- `POST /auth/register` - Create new user
- `POST /auth/login` - Login with credentials
- `GET /auth/me` - Get current user (protected)

### Example Login Request
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"admin123"}'
```

**Response:**
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@test.com",
    "role": "admin",
    "rating": 1200
  }
}
```

---

## File Structure

```
codemania/
├── backend/                    # Node.js Express server
│  ├── index.js                # Main entry point
│  ├── package.json            # Dependencies
│  ├── .env                    # Environment (JWT_SECRET, DB credentials)
│  ├── middleware/auth.js      # JWT verification
│  ├── routes/authRoutes.js    # Login/Register endpoints
│  └── services/               # Business logic
│
├── flutter_app/               # Flutter web frontend
│  ├── lib/
│  │  ├── main.dart           # App entry point
│  │  ├── config.dart         # API configuration
│  │  ├── providers/          # Riverpod state
│  │  ├── services/           # API & Socket.IO
│  │  ├── models/             # Data models
│  │  └── screens/            # UI screens
│  ├── web/
│  │  └── index.html          # Web entry point (no Firebase!)
│  └── pubspec.yaml           # Flutter dependencies
│
├── schema.sql                 # PostgreSQL database schema
├── docker-compose.yml        # Infrastructure setup
└── README.md                 # Full documentation
```

---

## Environment Variables

**backend/.env** (local dev example):
```
PORT=3000
NODE_ENV=development
JWT_SECRET=codemania_dev_secret_change_in_prod
DATABASE_URL=postgresql://codemania:codemania@localhost:5432/codemania
REDIS_URL=redis://localhost:6379
PISTON_URL=http://localhost:2000/api/v2/execute
```

**Render environment variables** (set in Render dashboard):
```
NODE_ENV=production
JWT_SECRET=<strong-random-secret>
DATABASE_URL=<your-neon-postgres-connection-string>
REDIS_URL=<your-upstash-redis-connection-string>
PISTON_URL=<your-piston-base-url>/api/v2/execute
```

Notes:
- `PISTON_URL` must include `/api/v2/execute`.
- Use `rediss://` for Upstash.

---

## Technology Stack

| Component | Technology | Port |
|-----------|-----------|------|
| Frontend | Flutter Web (Release via Express) | 3000 |
| Backend | Express.js | 3000 |
| Database | PostgreSQL 15 | 5432 |
| Cache | Redis 7 | 6379 |
| Code Judge | Piston | 2000 |
| Auth | JWT (HS256) | - |

---

## Next Steps (After MVP Works)

1. **Add more problems** - Use admin dashboard
2. **Create contests** - Admin feature
3. **Test code submission** - Run code against test cases
4. **Real-time submissions** - View leaderboard updates
5. **Deploy** - See DEPLOYMENT.md

---

## Support & Debugging

**Backend logs real-time:**
```powershell
# While backend is running, watch for connection messages
```

**Flutter console logs:**
```
Open Chrome DevTools (F12) → Console tab
Look for 📡 [REQUEST], 🔐 [LOGIN], 📝 [REGISTER] messages
```

**Check all services running:**
```powershell
# Backend
netstat -ano | findstr :3000

# Database
docker-compose ps

# Flutter
Browser DevTools (F12)
```

---

## Success Checklist

- [ ] Docker containers running (`docker-compose ps`)
- [ ] Database initialized with schema and test user
- [ ] Backend started and health endpoint returns 200
- [ ] Flutter release app loads from `http://localhost:3000`
- [ ] Can login with `admin@test.com / admin123`
- [ ] Admin sees AdminDashboard after login
- [ ] Can register new user and login with new credentials
- [ ] User logout works
- [ ] No red errors in browser console

---

## Command Quick Reference

```powershell
# Start all infrastructure
docker-compose up -d

# Start backend
cd backend && node index.js

# Build and deploy Flutter web release to Express
.\build_and_deploy.bat

# Optional hot reload development mode
Set-Location D:\MAD\codemania\flutter_app; flutter run -d chrome --web-port 5000

# Stop everything
docker-compose down

# View logs
docker-compose logs -f

# Reset database
docker-compose exec -T postgres psql -U codemania -d codemania
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

# Test health
curl http://localhost:3000/health
```

---

**Status:** ✅ MVP Ready  
**Last Updated:** March 30, 2026  
**Auth:** JWT (no Firebase)  
**Database:** PostgreSQL with 8 tables  
**Real-time:** Socket.IO configured  
