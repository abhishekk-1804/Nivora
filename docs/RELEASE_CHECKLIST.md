# Nivora Release Checklist & Store Submission Guide

**Application Name:** Nivora  
**Application ID:** `com.nivora.health`  
**Target Release Version:** `1.0.0-beta.2` (Build `2`)  
**Repository:** `D:\imyra_health`  

---

## 1. Automated Software Gates (Completed & Certified)

- [x] **Static Analysis:** `dart analyze` — 0 issues found.
- [x] **Automated Tests:** `flutter test --reporter=compact` — 114/114 passing across 31 test files.
- [x] **Air-Gap Verification:** `android.permission.INTERNET` absent in release manifest.
- [x] **Font Network Isolation:** `GoogleFonts.config.allowRuntimeFetching = false;` in `main()`.
- [x] **Backup Cryptography:** Authenticated AES-256-GCM + PBKDF2 (100k iterations) with tamper rejection.
- [x] **Database Integrity:** Schema V6 migration, same-day upsert merge, zero data loss, safe `.bak` file creation.
- [x] **Exact Alarm Permissions:** Prohibited `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM` removed.
- [x] **Localization Invariants:** 43 keys verified identical across English, Spanish, and Hindi.
- [x] **Release APK Build:** Successfully compiled with R8 code shrinking (`app-release.apk`).
- [x] **Release AAB Build:** Successfully compiled (`app-release.aab`).
- [x] **Forensic APK Inspection:** `aapt dump badging` verified zero prohibited permissions and non-debuggable state.

---

## 2. Developer Production Keystore Setup (Required Before Store Submission)

The release compilation currently falls back to the Android debug keystore because `android/key.properties` is omitted (ensuring no private credentials are ever checked into source control).

To generate and attach the production keystore:

1. **Generate the Keystore (Store securely off-repo):**
   ```bash
   keytool -genkey -v -keystore nivora-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nivora
   ```
2. **Configure `android/key.properties`:**
   Copy `android/key.properties.example` to `android/key.properties`:
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=nivora
   storeFile=C:/path/to/nivora-release-key.jks
   ```
3. **Verify Git Ignores Keystore:**
   Run `git status` to ensure `android/key.properties` is NOT tracked.
4. **Compile Production Signed AAB:**
   ```powershell
   $env:TEMP = "D:\temp"; $env:TMP = "D:\temp"; flutter build appbundle --release
   ```

---

## 3. Google Play Console Submission Checklist

- [ ] **Create Application:**
  - Name: **Nivora**
  - Default Language: English (United States)
  - App or Game: App
  - Free or Paid: Free
- [ ] **Data Safety Declaration:**
  - Data collection: **No user data collected or shared.**
  - Third-party tracking: **No SDKs or analytics tools used.**
  - Encryption: **All data stored locally on-device.**
  - Account requirement: **No account needed.**
- [ ] **App Content & Permissions:**
  - Target Audience: 18+
  - Medical / Health app declaration: Select "Health & Fitness / Women's Health". Note that Nivora is a self-reported journal and observational tracking notebook, not an automated medical diagnostic tool.
  - Ads: Declare "No, my app does not contain ads".
  - Foreground Services: Declare None.
  - Alarms & Reminders: Declare Inexact Alarms (no exact alarm declaration required).
- [ ] **Store Listing Assets:**
  - App Icon: `512x512` PNG (source from `assets/branding/nivora_icon.png`).
  - Feature Graphic: `1024x500` PNG.
  - Screenshots: Phone (minimum 4 portrait screenshots) and 7-inch/10-inch Tablet screenshots.
- [ ] **Upload Artifact:**
  - Upload `build/app/outputs/bundle/release/app-release.aab` to **Internal Testing Track**.
- [ ] **Execute Real Device Smoke Test:**
  - Follow the 25-step protocol in [`docs/DEVICE_VALIDATION.md`](file:///D:/imyra_health/docs/DEVICE_VALIDATION.md).
- [ ] **Promote to Closed Testing / Production Track.**
