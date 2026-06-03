# Google Sign-In Fix for Android

## Problem
Google Sign-In is failing on Android because the debug keystore SHA-1 fingerprint is not registered in Google Cloud Console.

## Solution

### 1. SHA-1 Fingerprint Retrieved ✅
```
SHA1: 9A:2F:A8:02:41:17:08:66:04:BA:F9:AD:6C:65:17:F9:CE:0C:C5:92
```

### 2. Steps to Configure in Google Cloud Console

1. **Go to Google Cloud Console**
   - URL: https://console.cloud.google.com/

2. **Navigate to APIs & Services → Credentials**
   - Select your project (CodeMania)

3. **Android OAuth 2.0 Client**
   - Find your existing Android OAuth 2.0 Client ID
   - If you don't have one, create a new one:
     - Click "Create Credentials" → "OAuth client ID"
     - Application type: Android
     - Name: CodeMania Android (Debug)

4. **Add the SHA-1 Fingerprint**
   - Package name: `com.example.codemania`
   - SHA-1 certificate fingerprint: `9A:2F:A8:02:41:17:08:66:04:BA:F9:AD:6C:65:17:F9:CE:0C:C5:92`
   - Click "Save"

### 3. Missing google-services.json ❌

The file `android/app/google-services.json` is **missing**.

**To fix:**
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your CodeMania project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps"
5. Find your Android app (or add one if it doesn't exist)
6. Download `google-services.json`
7. Place it at: `d:\MAD\codemania\flutter_app\android\app\google-services.json`

### 4. Verify Package Name

Ensure the package name in `google-services.json` matches:
```
com.example.codemania
```

This should match the package name in:
- `android/app/build.gradle.kts` (namespace)
- `android/app/src/main/AndroidManifest.xml` (package attribute)

## Testing

After completing the above steps:
1. Clean and rebuild the Flutter app:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Run on Android device/emulator:
   ```bash
   flutter run
   ```

3. Test Google Sign-In:
   - Tap "Sign In" button
   - Tap Google "G" button
   - Should open Google account selector
   - Select account and sign in

## Notes

- This is a **configuration fix only** - no Dart code changes needed
- The SHA-1 fingerprint is for the **debug keystore** - you'll need to add the release keystore SHA-1 before releasing to production
- For release builds, generate the release SHA-1 using:
  ```bash
  keytool -list -v -keystore <path-to-release-keystore> -alias <release-alias>
  ```

## Current Status

✅ Router updated - app opens to /home (Library tab)
✅ Landing screen removed
✅ "You" tab navigates to login if not authenticated
✅ SHA-1 fingerprint retrieved
❌ Need to add SHA-1 to Google Cloud Console
❌ Need to download and place google-services.json

## Quick Checklist

- [ ] Add SHA-1 `9A:2F:A8:02:41:17:08:66:04:BA:F9:AD:6C:65:17:F9:CE:0C:C5:92` to Google Cloud Console
- [ ] Verify package name is `com.example.codemania` in OAuth client
- [ ] Download google-services.json from Firebase Console
- [ ] Place google-services.json at `android/app/google-services.json`
- [ ] Run `flutter clean && flutter pub get`
- [ ] Test Google Sign-In on Android
