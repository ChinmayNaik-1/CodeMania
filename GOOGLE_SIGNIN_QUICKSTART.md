# Google Sign-In — Quick Start Commands

Copy-paste these commands in order to get Google Sign-In running.

---

## ⚠️ PREREQUISITES

Before running commands:
1. ✅ Have your Google Web Client ID ready (from GOOGLE_CLOUD_SETUP.md)
2. ✅ Update `flutter_app/web/index.html` with your Client ID
3. ✅ Update `backend/.env` with your Client ID

---

## 🚀 QUICK START

### Terminal 1: Apply Database Migration

```powershell
cd d:\MAD\codemania
Get-Content migration_001_google_signin.sql | docker-compose exec -T postgres psql -U codemania -d codemania
```

**Verify it worked:**
```powershell
docker-compose exec -T postgres psql -U codemania -d codemania -c "SELECT column_name FROM information_schema.columns WHERE table_name='users' ORDER BY column_name;"
```

You should see `google_uid` in the list of columns.

---

### Terminal 2: Update Flutter & Start Backend

```powershell
cd d:\MAD\codemania\flutter_app
flutter pub get
flutter clean
```

Then wait for it to finish, then:

```powershell
# Go back to backend
cd d:\MAD\codemania\backend

# Start backend
node index.js
```

**You should see:**
```
✓ Database connected
✓ Redis connected
✓ Server running on http://localhost:3000
```

Leave this terminal running.

---

### Terminal 3: Start Flutter Web

```powershell
cd d:\MAD\codemania\flutter_app
flutter run -d chrome --web-port 5000
```

**You should see:**
```
✓ Flutter Web Server is available at: http://localhost:5000
```

Chrome should open automatically. If not, open http://localhost:5000 manually.

---

## 🧪 QUICK TESTS

### Test 1: Visual Check
1. On the login screen, scroll down
2. Look for: "or continue with" divider
3. Look for: White button with "Continue with Google"
4. ✅ Button should be clickable

### Test 2: Click Google Button
1. Click "Continue with Google"
2. Google account picker should appear
3. Select your Google account
4. Loading spinner should appear briefly
5. Should redirect to dashboard

### Test 3: Verify Backend Got Token
1. Look at the Terminal 2 (backend) console
2. You should see: `🔐 [GOOGLE-AUTH] Verifying Google ID token`
3. Followed by: `🔐 [GOOGLE-AUTH] Token verified for: your-email@gmail.com`
4. Followed by: `🔐 [GOOGLE-AUTH-SUCCESS] User: ...`

### Test 4: Verify Database
```powershell
docker-compose exec -T postgres psql -U codemania -d codemania -c "SELECT username, email, google_uid FROM users WHERE google_uid IS NOT NULL LIMIT 1;"
```

Should show your Google account's email and a google_uid.

### Test 5: Logout & Re-Login
1. Click logout button (top right)
2. Should go back to login page
3. Click Google button again
4. Should login successfully again

---

## 🔄 RESTART EVERYTHING

If something breaks or you need a fresh start:

```powershell
# Terminal 1: Kill all
docker-compose down
docker-compose up -d

# Terminal 2: Kill backend (Ctrl+C in terminal), then:
cd d:\MAD\codemania\backend
node index.js

# Terminal 3: Kill Flutter (Ctrl+C in terminal), then:
cd d:\MAD\codemania\flutter_app
flutter run -d chrome --web-port 5000
```

---

## 🐛 TROUBLESHOOTING QUICK FIXES

### "Client ID mismatch" error
```powershell
# Check GOOGLE_WEB_CLIENT_ID in .env
type d:\MAD\codemania\backend\.env | findstr GOOGLE_WEB_CLIENT_ID

# Should show your real Client ID
```

### "Cannot get ID token" error
```powershell
# Clear Flutter cache
cd d:\MAD\codemania\flutter_app
flutter clean
flutter pub get
flutter run -d chrome --web-port 5000
```

### "Database migration didn't run"
```powershell
# Verify migration
docker-compose exec -T postgres psql -U codemania -d codemania -c "\d users"

# Should show google_uid column in the output
```

### "Backend port 3000 already in use"
```powershell
# Kill process on port 3000
Get-NetTCPConnection -LocalPort 3000 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# Try again
cd d:\MAD\codemania\backend
node index.js
```

### "Flutter port 5000 already in use"
```powershell
# Kill process on port 5000
Get-NetTCPConnection -LocalPort 5000 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# Try again
cd d:\MAD\codemania\flutter_app
flutter run -d chrome --web-port 5000
```

---

## 📋 VERIFICATION CHECKLIST

After running above commands:

- [ ] Database migration ran without errors
- [ ] Backend shows "Server running on http://localhost:3000"
- [ ] Flutter shows "Flutter Web Server is available at: http://localhost:5000"
- [ ] Chrome opened with login screen
- [ ] Google button visible on login screen
- [ ] Clicking Google button opens account picker
- [ ] After selecting account, redirected to dashboard
- [ ] Backend console shows "🔐 [GOOGLE-AUTH] Token verified"
- [ ] Database has new user with google_uid

---

## 📊 DEBUG COMMANDS

Check if services are running:

```powershell
# Check backend
netstat -ano | findstr :3000

# Check Flutter web
netstat -ano | findstr :5000

# Check Docker containers
docker-compose ps

# Check PostgreSQL users table
docker-compose exec -T postgres psql -U codemania -d codemania -c "SELECT COUNT(*) as total_users FROM users;"
```

---

## 📝 COMMON NEXT STEPS

After confirming everything works:

1. **Test with multiple Google accounts**
   - Logout
   - Login with different Google account
   - Should create/update separate user

2. **Test email sign-in still works**
   - Logout
   - Use email/password login
   - Should work as before

3. **Test register flow**
   - Use email sign-up (existing)
   - Use Google sign-up (new)
   - Both should work

4. **Check user profiles**
   - After Google login, view profile
   - Should show avatar_url from Google

---

**Status:** Ready to execute  
**Time to complete:** ~10 minutes  
**Next:** Follow commands in order!
