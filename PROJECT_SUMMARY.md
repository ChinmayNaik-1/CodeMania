# CodeMania - Project Summary (Current State)

Last updated: April 12, 2026

## Status

CodeMania is functional as a full-stack coding platform with:
- Express + PostgreSQL + Redis + Piston backend
- Flutter web frontend with Riverpod state management
- JWT-based auth flow with optional Google sign-in onboarding
- Problem solving workflow (run + submit + polling)
- GoRouter-based navigation and URL paths

This document reflects the present repository state, not the original generated template claims.

---

## Architecture Snapshot

- Frontend: Flutter Web
- Backend: Node.js + Express
- Database: PostgreSQL
- Cache/leaderboard infra: Redis
- Judge execution: Piston API
- Realtime: Socket.IO
- Auth transport: JWT bearer tokens

---

## Backend Status

### Implemented
- Auth routes for email/password register + login
- JWT session issuance and verification
- Google sign-in start/complete-signup endpoints
- Problem CRUD/listing routes
- Submission routes for run and submit
- Contest/team/leaderboard route set and socket events
- Piston execution wrapper with compile/run diagnostics

### Recent correctness updates
- Two Sum C++ wrapper support for class/function style submissions
- Two Sum output matcher now accepts answer indices in any order
  - Example: expected `[0,1]` also accepts `[1,0]`

### Notes
- `backend/config/firebase.js` exists in repository but active request auth middleware is JWT-based (`backend/middleware/auth.js`).

---

## Frontend Status

### Implemented
- GoRouter app routing (`MaterialApp.router`)
- Landing page route restored as default (`/`)
- Auth screens: login, register, google signup completion
- User/admin screens and problem list/detail flows
- Problem detail page with split-pane layout and drag resizing
- Monaco editor restored as active code editor in problem page
- Testcase panel and run/submit controls integrated

### Problem page implementation details
- Left panel uses tabs:
  - Description: implemented
  - Solutions: placeholder
  - Submissions: placeholder
- Right panel:
  - Monaco editor
  - Testcase panel with run/submit interaction

### Provider model (current)
- `problemListProvider`: global/list usage
- `problemProvider(id)`: family provider for per-problem detail state
- Compatibility alias: `problemPageProvider = problemProvider`

### Routing/navigation state
- Initial route is `/` (landing)
- Problem list route exists at `/problems`
- Problem detail route exists at `/problems/:id`
- Problems list screen now includes a top app bar for navigation

---

## Authentication Model (Current)

- Primary active backend auth is JWT (HS256) with bearer tokens.
- Email/password auth is supported and persistent on client.
- Google sign-in path is supported via Google token verification endpoint.
- Legacy Firebase option files exist in frontend/backend but are not the active auth middleware path.

---

## Deployment/Run Modes

### Production-style (served by Express)
1. Build Flutter web bundle
2. Copy to `backend/public`
3. Serve via backend at `http://localhost:3000`

PowerShell note: use `./` for local scripts:
- `./build_and_deploy.bat`

### Hot reload frontend mode
- Run from `D:\MAD\codemania\flutter_app`
- Fixed port convention in this project: `5000`
- Command: `flutter run -d chrome --web-port 5000`

---

## Current Gaps / Incomplete Areas

- Solutions tab content: not implemented yet
- Submissions tab content in problem left panel: placeholder state
- Some legacy documentation still references old/generated architecture details and should be reconciled over time

---

## Practical Known Gotchas

- In PowerShell, local `.bat` scripts require `./` prefix
- Running Flutter from the wrong folder causes missing `pubspec.yaml` errors
- Port `5000` conflicts can block frontend launch; kill existing listener before restarting

---

## Recommended Next Updates

1. Implement real data for Solutions tab
2. Implement per-problem submission history tab content
3. Remove or archive unused legacy auth/config artifacts after final auth strategy freeze
4. Harmonize all markdown docs to this current architecture summary
