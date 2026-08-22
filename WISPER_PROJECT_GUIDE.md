# Wisper App — Complete Project Guide

## Project Overview
- **App Name:** Wisper
- **Bundle ID (Android):** `com.wisperapplication.app`
- **Bundle ID (iOS):** `com.wispermedia.app`
- **Version:** 1.2.0+4
- **Flutter Version:** 3.x
- **Backend:** Node.js + Express + Prisma + PostgreSQL + Socket.io
- **Live API:** `https://api.wisperonline.com/api/v1`
- **Dashboard:** `https://admin.wisperonline.com`

---

## Repository

- **Flutter App:** `https://github.com/Wisper-corp/Wisper-app.git` (branch: `main`)
- **Backend Server:** `https://github.com/Wisper-corp/wisper-server.git` (branch: `main`)

---

## Project Structure

```
wisper-app/
├── wisper/                          # Flutter app
│   ├── android/                     # Android config
│   ├── ios/                         # iOS config
│   ├── lib/                         # Dart source code
│   ├── assets/                      # Images, icons
│   ├── pubspec.yaml                 # Dependencies
│   └── android/key.properties       # Release signing config
├── wisper-server/                   # Node.js backend
│   ├── src/                         # TypeScript source
│   ├── dist/                        # Compiled JS (tracked in git)
│   ├── prisma/schema.prisma         # Database schema
│   └── .env                         # Environment variables
├── upload_certificate.pem           # Play Store upload key certificate
└── WISPER_PROJECT_GUIDE.md          # This file
```

---

## Android Signing (Release Keystore)

| Field | Value |
|---|---|
| Keystore file | `wisper/android/app/wisper-release.jks` |
| Store password | `Wisper@2024` |
| Key alias | `wisper-release` |
| Key password | `Wisper@2024` |
| SHA1 | `53:06:1C:8C:71:41:CA:9A:87:8B:F9:76:1F:7C:8B:F1:88:E4:AC:23` |
| SHA256 | `24:89:34:9D:33:16:C4:78:17:67:64:10:02:6D:BD:B4:84:E2:1D:04:2D:D2:DF:08:0B:6B:4C:B4:33:68:ED:20` |

**`wisper/android/key.properties`:**
```
storePassword=Wisper@2024
keyPassword=Wisper@2024
keyAlias=wisper-release
storeFile=wisper-release.jks
```

---

## Build Commands

### Prerequisites
```bash
export PATH="/Users/apple/flutter/bin:$PATH"
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export ANDROID_HOME=/Users/apple/Android/sdk
```

### Build APK (for testing/sideloading)
```bash
cd /Users/apple/Documents/project/wisper-app/wisper
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk (332MB)
```

### Build AAB (for Play Store)
```bash
cd /Users/apple/Documents/project/wisper-app/wisper
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab (196MB)
```

### Build Split APKs (smaller size)
```bash
flutter build apk --split-per-abi --release
# Output: build/app/outputs/flutter-apk/
#   app-arm64-v8a-release.apk
#   app-armeabi-v7a-release.apk
#   app-x86_64-release.apk
```

### Bump Version Before Building
Edit `wisper/pubspec.yaml`:
```yaml
version: 1.2.0+4   # format: versionName+versionCode
# versionCode must be higher than previous Play Store upload
```

---

## Wireless Debugging (ADB) — Test on Android Phone

### Step 1 — Enable on Phone
- Settings → Developer Options → Wireless Debugging → Enable

### Step 2 — Pair
```bash
export ANDROID_HOME=/Users/apple/Android/sdk
export PATH="$ANDROID_HOME/platform-tools:$PATH"
adb pair <PHONE_IP>:<PAIR_PORT> <6_DIGIT_CODE>
# Example: adb pair 192.168.100.5:43203 571421
```

### Step 3 — Connect
```bash
adb connect <PHONE_IP>:<MAIN_PORT>
# Main port shown on Wireless Debugging main screen (different from pair port)
# Example: adb connect 192.168.100.5:40053
```

### Step 4 — Verify
```bash
adb devices
# Should show: 192.168.100.5:40053  device
```

### Step 5 — Install APK directly
```bash
adb -s <PHONE_IP>:<PORT> install -r build/app/outputs/flutter-apk/app-release.apk
```

### Step 6 — View live logs
```bash
adb -s <PHONE_IP>:<PORT> logcat 2>&1 | grep "I flutter"
```

### Step 7 — Test deep link directly
```bash
adb -s <PHONE_IP>:<PORT> shell am start \
  -a android.intent.action.VIEW \
  -d "wisper://groups/<GROUP_ID>" \
  com.wisperapplication.app
```

---

## Backend Deployment (AWS EC2)

| Field | Value |
|---|---|
| Server | AWS EC2 |
| IP | `54.205.198.31` |
| User | `wisper` |
| Password | `=yZb9T-Tfw1IGDoMS` |
| Process Manager | PM2 |
| Backend port | `5000` |
| Dashboard port | `3000` |

### SSH into server
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31
```

### Deploy backend update
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31 \
  "cd /home/wisper/apps/wisper-server && git reset --hard origin/main && pm2 restart server && echo DONE"
```

### Deploy dist files (if compiled locally)
```bash
# Copy specific dist file
sshpass -p '=yZb9T-Tfw1IGDoMS' scp -o StrictHostKeyChecking=no \
  wisper-server/dist/app/modules/job/job.service.js \
  wisper@54.205.198.31:/home/wisper/apps/wisper-server/dist/app/modules/job/

# Restart server
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31 \
  "pm2 restart server && echo DONE"
```

### Check server status
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31 "pm2 list"
```

### Check server logs
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31 \
  "pm2 logs server --lines 50 --nostream"
```

### Free up disk space (if server full)
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh -o StrictHostKeyChecking=no wisper@54.205.198.31 \
  "npm cache clean --force && pm2 flush && sudo apt-get clean && sudo journalctl --vacuum-size=50M"
```

---

## Google Play Store Upload Key Reset

The original keystore was lost. We created a new one and need Google to approve the key reset.

### upload_certificate.pem
- **File location:** `/Users/apple/Documents/project/wisper-app/upload_certificate.pem`
- **SHA1:** `53:06:1C:8C:71:41:CA:9A:87:8B:F9:76:1F:7C:8B:F1:88:E4:AC:23`
- **Valid until:** December 2053

### Steps for key reset
1. Send `upload_certificate.pem` to the Play Console team
2. They submit an Upload Key Reset Request to Google
3. Google approves in 1-3 business days
4. Then upload `app-release.aab` to Play Store

### Message to send to other team
> We are going with Option B. The original keystore is lost.
> Please find the `upload_certificate.pem` attached.
> Submit the Upload Key Reset Request to Google Play Console.
> New SHA1: `53:06:1C:8C:71:41:CA:9A:87:8B:F9:76:1F:7C:8B:F1:88:E4:AC:23`
> Once approved, we will upload the new AAB immediately.

---

## iOS Configuration

| Field | Value |
|---|---|
| Bundle ID | `com.wispermedia.app` |
| Min iOS version | 15.0 |
| GoogleService-Info.plist | `wisper/ios/GoogleService-Info.plist` |
| APNs environment | `production` |
| Associated Domains | `applinks:wisperonline.com`, `applinks:admin.wisperonline.com` |

### iOS Build (requires Mac + Xcode)
```bash
cd /Users/apple/Documents/project/wisper-app/wisper
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

### iOS testing options
- **Simulator (free):** `flutter run -d "iPhone 15"`
- **Real device:** Requires paid Apple Developer account ($99/year)
- **TestFlight:** iOS team uploads, you install via TestFlight app

---

## Deep Links

### Custom scheme (Android + iOS)
- `wisper://groups/<GROUP_ID>` → opens group chat
- `wisper://persons/<USER_ID>` → opens person profile
- `wisper://businesses/<USER_ID>` → opens business profile

### Web invite page
- `https://admin.wisperonline.com/groups/<GROUP_ID>` → shows "Open in Wisper" page

### Share link format (generated by app)
```
Join "GROUP_NAME" on Wisper: https://admin.wisperonline.com/groups/<GROUP_ID>
```

---

## Key Files Reference

| File | Purpose |
|---|---|
| `wisper/pubspec.yaml` | App version, dependencies |
| `wisper/android/app/build.gradle.kts` | Android build config, signing |
| `wisper/android/key.properties` | Keystore credentials |
| `wisper/android/app/wisper-release.jks` | Release keystore |
| `wisper/ios/Runner/Info.plist` | iOS permissions, URL schemes |
| `wisper/ios/Runner/Runner.entitlements` | iOS capabilities (APNs, Associated Domains) |
| `wisper/ios/GoogleService-Info.plist` | Firebase iOS config |
| `wisper/lib/app/urls.dart` | All API endpoint URLs |
| `wisper/lib/app/core/services/others/deeplink_services.dart` | Deep link handler |
| `wisper-server/src/app/modules/` | Backend route handlers |
| `wisper-server/prisma/schema.prisma` | Database schema |
| `upload_certificate.pem` | Play Store upload key certificate |

---

## Test Credentials

| Account | Email | Password |
|---|---|---|
| Test user | `farazali7530@gmail.com` | `Ssapmms5@123` |

---

## Common Issues & Fixes

### "Version code already used" on Play Store
Bump `versionCode` in `pubspec.yaml` (the number after `+`)

### Server disk full
```bash
sshpass -p '=yZb9T-Tfw1IGDoMS' ssh wisper@54.205.198.31 \
  "npm cache clean --force && pm2 flush && sudo apt-get clean"
```

### Chat list not updating after message
Flutter fix: use `Map<String, dynamic>.from()` for reactive updates in `all_chats_controller.dart`

### Deep link opens app but not the group
Check `wisper://` scheme registered in `AndroidManifest.xml` with correct `android:host`

### Job posting "currency does not exist" error
The `currency` field must be stripped from payload before Prisma create — handled in `dist/app/modules/job/job.service.js`

### Server code not updating after `git reset --hard`
Copy patched dist files directly via `scp` then `pm2 restart server`
