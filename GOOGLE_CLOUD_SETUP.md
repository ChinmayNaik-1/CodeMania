# Google Cloud Console Setup — Step-by-Step Instructions

## 📋 Prerequisites
- Google account
- Access to [Google Cloud Console](https://console.cloud.google.com/)

---

## 🔧 Step 1: Create or Access Google Cloud Project

### Option A: Create New Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the **project dropdown** at the very top (showing current project name)
3. Click **NEW PROJECT**
4. Enter:
   - **Project name:** `CodeMania`
   - **Organization:** (leave default or select own)
5. Click **CREATE**
6. Wait 1-2 minutes for initialization
7. Select the new project from the dropdown

### Option B: Use Existing Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click project dropdown at top
3. Select your existing project

---

## 📡 Step 2: Enable Google People API

1. In left sidebar, click **APIs & Services** → **Library**
2. In search box, type: `Google People API`
3. Click on the result
4. Click **ENABLE** (blue button)
5. Wait for it to show "API enabled" (bottom right)

---

## 🔐 Step 3: Create OAuth 2.0 Web Client Credentials

### Step 3a: Configure OAuth Consent Screen (First Time Only)

If you see "You'll need to configure your OAuth consent screen":
1. Click **CONFIGURE CONSENT SCREEN**
2. Choose **External** (unless you have Google Workspace)
3. Click **CREATE**
4. Fill in the form:
   - **App name:** `CodeMania`
   - **User support email:** Your email
   - **Developer contact information:** Your email
5. Click **SAVE AND CONTINUE**
6. Skip scopes (click **SAVE AND CONTINUE** again)
7. Add test users:
   - Click **ADD USERS**
   - Add your Gmail address
   - Click **ADD**
8. Review and click **BACK TO DASHBOARD**

### Step 3b: Create Web Client Credential

1. In left sidebar: **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** at the top
3. Select **OAuth client ID**
4. Choose **Web application**
5. Enter name: `Web Client - CodeMania`
6. Under **Authorized JavaScript origins**, click **ADD URI** and add:
   - `http://localhost:5000`
   - `http://localhost:3000`
7. **Authorized redirect URIs:** (Leave empty — not needed for this flow)
8. Click **CREATE**

### ⭐ IMPORTANT: Copy Your Web Client ID

A modal will popup showing your credentials:
```
Client ID: XXX-XXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com
Client secret: XXXXXXXXXXXXXXXXXXXX
```

**Copy the Client ID** (only the Client ID, not secret) — you'll need it in 2 places:
- `flutter_app/web/index.html`
- `backend/.env`

Save it somewhere safe. Click the copy icon next to Client ID.

---

## 📱 Step 4: Create Android Client Credentials (Optional for Flutter Web)

### Step 4a: Get Your App's SHA-1 Fingerprint (Windows)

Open PowerShell and run:

```powershell
# Navigate to your Flutter app
cd d:\MAD\codemania\flutter_app

# Get debug SHA-1 fingerprint
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Look for the line starting with `SHA1:` in the output:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

**Copy the entire SHA-1 value** (with colons).

### Step 4b: Create Android Credential

1. In [Google Cloud Console](https://console.cloud.google.com/): **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS**
3. Select **OAuth client ID**
4. Choose **Android**
5. Fill in:
   - **Package name:** `com.example.codemania` (or your package name from AndroidManifest.xml)
   - **SHA-1 certificate fingerprint:** Paste the SHA-1 you copied
6. Click **CREATE**
7. Copy the **Client ID** shown

**Note:** The Android Client ID is different from the Web Client ID. Store it separately for later.

---

## ✅ Complete — You Now Have

| Item | Location | Use |
|------|----------|-----|
| **Web Client ID** | From Step 3b | Flutter web + Backend |
| **Android Client ID** | From Step 4b | Flutter Android (optional) |
| **OAuth Consent Screen** | Configured | Needed for sign-in flow |
| **Authorized Origins** | http://localhost:5000, http://localhost:3000 | Prevents CORS errors |

---

## 📝 Where to Use These Credentials

### Web Client ID: 2 Places

**1. Flutter Web (`flutter_app/web/index.html`)**
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```

**2. Backend Express (`backend/.env`)**
```
GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
```

### Android Client ID: 1 Place

**`flutter_app/android/app/src/main/res/values/strings.xml`** (create if doesn't exist)
```xml
<string name="default_web_client_id">YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com</string>
```

---

## 🔍 Troubleshooting Google Cloud Setup

### Issue: Can't find "Google People API" in library
- **Solution:** Make sure you've enabled the API. Search for `People API` instead.

### Issue: "OAuth consent screen not configured"
- **Solution:** Complete Step 2a above. You must add app name and test users.

### Issue: Getting "redirect_uri_mismatch" error
- **Solution:** Make sure you've added `http://localhost:5000` and `http://localhost:3000` to authorized origins (Step 3b).

### Issue: Android fingerprint doesn't match
- **Solution:** 
  - The fingerprint comes from the debug keystore on YOUR machine
  - If you copied wrong, re-run the keytool command
  - Debug keystore is at: `~/.android/debug.keystore`
  - If fingerprint doesn't generate, make sure you have Java/keytool installed with Flutter

### Issue: Can't find my Client ID later
- **Solution:** Go to **APIs & Services** → **Credentials** → look for "Web application" type → click it → copy from popup

---

## 🎯 Testing Your Setup (Optional)

After creating credentials, you can test the OAuth flow:

1. Go to [Google OAuth 2.0 Playground](https://developers.google.com/oauthplayground)
2. Click ⚙️ (gear icon) top right
3. Enable "Use your own OAuth credentials"
4. Enter your **Web Client ID** and **Client Secret**
5. In left panel, expand "Google People API v1"
6. Select any scope (e.g., `profile`)
7. Click **Authorize APIs**
8. Follow the flow — should open Google account picker
9. If successful, you can see the idToken in the response

This confirms your credentials are valid.

---

## ✨ Done!

You now have credentials ready to integrate with CodeMania. Proceed to:
1. Update `flutter_app/web/index.html` with Web Client ID
2. Update `backend/.env` with Web Client ID
3. Run database migration
4. Test login with Google account

**Reference File:** `GOOGLE_SIGNIN_SETUP.md` for next steps.

---

**Last Updated:** March 30, 2026
