# Flutter Build & Run Guide

This guide contains the most common commands for building and running your Flutter application on connected devices. **Ensure you run all of these commands from inside your `flutter_app` directory.**

## 1. Running the App

### Standard Run
To build and launch the app in debug mode on a USB-connected device (make sure USB Debugging is enabled and the device is unlocked):
```bash
flutter run
```

### Run on a Specific Device
If you have multiple devices connected (like an emulator and a physical phone), you can list them and target a specific one:

1. List available devices:
   ```bash
   flutter devices
   ```
2. Run on a specific device using its ID:
   ```bash
   flutter run -d <device_id>
   ```

### Run in Release Mode
To test the app with full performance optimizations (no debug overhead, no hot reload):
```bash
flutter run --release
```

---

## 2. Building the App

If you just want to generate the installation files without running the app immediately:

### Build an APK (For Direct Sharing/Manual Install)
Builds a standard release APK that you can share with testers or install directly on an Android device.
```bash
flutter build apk
```
*Output location:* `build/app/outputs/flutter-apk/app-release.apk`

### Build an App Bundle (For Google Play Store)
Builds an optimized Android App Bundle (AAB), which is required when uploading your app to the Google Play Console.
```bash
flutter build appbundle
```
*Output location:* `build/app/outputs/bundle/release/app-release.aab`

### Build a Debug APK
If you specifically need a debug APK to share with developers or automated testing tools:
```bash
flutter build apk --debug
```
*Output location:* `build/app/outputs/flutter-apk/app-debug.apk`
