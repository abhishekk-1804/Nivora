# Nivora Device Validation Protocol

**Application:** Nivora
**Application ID:** `com.nivora.health`
**Bundle ID:** `com.nivora.health.NivoraApp`
**Status:** `[NOT EXECUTED - DEVICE REQUIRED]`
**Target Hardware:** Minimum 1 stock Android device (Google Pixel) and 1 OEM custom OS device (Samsung Galaxy OneUI / Xiaomi MIUI).

---

## 1. Android Real Hardware Manual Test Matrix

| Case ID | Feature / Flow | Step-by-Step Procedure | Expected Result | Status |
|---|---|---|---|:---:|
| **TC-D01** | Fresh APK Install | Run `adb install -r build/app/outputs/flutter-apk/app-release.apk` on clean test device. | Installs without system error or signature conflicts. | `[DEVICE REQUIRED]` |
| **TC-D02** | First Launch | Tap Nivora launcher icon. | Splash screen displays `NivoraLogo` and smoothly transitions to Onboarding Page 1. | `[DEVICE REQUIRED]` |
| **TC-D03** | Onboarding Flow | Step through pages 1–4 of onboarding; complete initial symptom setup. | Flow completes without UI stutter; sets `has_onboarded = true`. | `[DEVICE REQUIRED]` |
| **TC-D04** | Notification Permission | Reach notification setup screen in onboarding; tap Enable. | System dialog requests `POST_NOTIFICATIONS` (Android 13+). | `[DEVICE REQUIRED]` |
| **TC-D05** | App Lock Setup | Open Settings > Security; toggle "Enable App Lock". | Prompts system biometric enrollment check; toggles enabled state. | `[DEVICE REQUIRED]` |
| **TC-D06** | Biometric Unlock | Minimize app, reopen app after >10 seconds. | Device fingerprint or Face Unlock prompt appears; successful scan opens Today screen. | `[DEVICE REQUIRED]` |
| **TC-D07** | Background App Masking | With app open on Today screen with active cycle data, press device Home or Overview button. | App window immediately overlays privacy mask before snapshotting. | `[DEVICE REQUIRED]` |
| **TC-D08** | Recent-Apps Privacy | View Android recent applications carousel (task switcher). | Nivora task card shows `NivoraLogo` privacy shield, hiding sensitive clinical data. | `[DEVICE REQUIRED]` |
| **TC-D09** | Menstrual Cycle Logging | On Today screen, tap "Log Period". Log Flow: Medium, Pain: 4, Symptoms: Pelvic Cramps. | Event saves immediately and appears on Today timeline and CycleGraph. | `[DEVICE REQUIRED]` |
| **TC-D10** | Same-Day Event Merge | Open "Log Period" again for the same date; add Clots: Small and Flooding: Yes. | Re-inspect database/UI: previous Medium flow is preserved; clots/flooding merged safely. | `[DEVICE REQUIRED]` |
| **TC-D11** | Routine Creation | Tap "+ Add Routine"; create Daily "Inositol 2000mg" at reminder time 09:00. | Routine saves to SQLite; displays on Today checklist. | `[DEVICE REQUIRED]` |
| **TC-D12** | Notification Scheduling | Set reminder time to Current Time + 3 minutes. Lock device. | Inexact reminder fires within window; displays neutral text: "Time for your scheduled routine." | `[DEVICE REQUIRED]` |
| **TC-D13** | Screen-Off Notification | Leave device in deep sleep (Doze mode) for >1 hour with active cyclic reminder. | Notification delivers when device maintenance window triggers. | `[DEVICE REQUIRED]` |
| **TC-D14** | Encrypted Backup Export | Settings > Backup & Restore > Export Encrypted Backup. Enter passphrase: `TestPass123!`. | Generates `.nivorabackup` file and opens native OS Share Sheet. | `[DEVICE REQUIRED]` |
| **TC-D15** | Wrong-Password Restore | Tap "Restore Data", select exported backup, enter incorrect passphrase: `WrongPassword`. | Displays error "Incorrect passphrase or corrupted backup file"; existing DB records unmodified. | `[DEVICE REQUIRED]` |
| **TC-D16** | Correct-Password Restore | Tap "Restore Data", select backup, enter `TestPass123!`. | Successfully decrypts and restores all cycle events, routines, logs, and clinical profile. | `[DEVICE REQUIRED]` |
| **TC-D17** | Corrupted Backup Restore | Edit `.nivorabackup` file in text editor, modify single character in ciphertext, attempt restore. | Rejects with authentication tag mismatch; leaves database untouched. | `[DEVICE REQUIRED]` |
| **TC-D18** | Offline PDF Generation | Navigate to Report screen; tap "Export PDF". | Generates multi-page PDF in memory without network access; fonts render cleanly. | `[DEVICE REQUIRED]` |
| **TC-D19** | PDF Sharing / Printing | In PDF preview, tap system Share / Print icon. | Native Android share sheet / Android PrintManager opens with compiled document. | `[DEVICE REQUIRED]` |
| **TC-D20** | Erase All Data | Settings > "Erase All Data". Type "DELETE" and confirm. | SQLite database tables wiped, `VACUUM` executed, app resets to Onboarding screen. | `[DEVICE REQUIRED]` |
| **TC-D21** | Re-Launch After Erase | Kill app process and relaunch after data erase. | App starts cleanly in fresh Onboarding state; zero remnant data. | `[DEVICE REQUIRED]` |
| **TC-D22** | Zero-Network Isolation | Ensure device has active Wi-Fi and 5G cellular data connected. Use app normally. | Inspect network traffic via Android Studio Network Profiler: 0 bytes transmitted/received. | `[DEVICE REQUIRED]` |
| **TC-D23** | Orientation Changes | Rotate device between Portrait and Landscape across all 4 primary screens. | Layout adapts smoothly without `RenderFlex` overflow errors. | `[DEVICE REQUIRED]` |
| **TC-D24** | Android Back Navigation | Navigate into Clinical Log Sheet, press hardware/gesture Back. | Sheet dismisses cleanly without exiting app or leaving phantom focus. | `[DEVICE REQUIRED]` |
| **TC-D25** | Process Death & Rehydrate | Log data, force-stop app from Android Settings (`am force-stop`), reopen app. | All logged cycles, routines, and clinical parameters persist intact. | `[DEVICE REQUIRED]` |

---

## 2. iOS Real Hardware Manual Test Matrix

| Case ID | Feature / Flow | Step-by-Step Procedure | Expected Result | Status |
|---|---|---|---|:---:|
| **TC-I01** | iOS Build & Install | Build from macOS via Xcode targeting an iPhone 14/15/16 device. | Compiles and installs `com.nivora.health.NivoraApp`. | `[DEVICE REQUIRED]` |
| **TC-I02** | FaceID Permission | Enable App Lock; trigger authentication. | System dialog displays `NSFaceIDUsageDescription` ("We use FaceID to secure your private health data."). | `[DEVICE REQUIRED]` |
| **TC-I03** | iOS App Switcher Mask | Swipe up to view iOS multitasking switcher. | Privacy shield obscures screen content immediately. | `[DEVICE REQUIRED]` |
| **TC-I04** | AirPrint & Document Sharing | Export PDF report; tap iOS Share. | AirPrint dialog opens; Save to Files operates smoothly via `LSSupportsOpeningDocumentsInPlace`. | `[DEVICE REQUIRED]` |
| **TC-I05** | iOS File Picker Restore | In Onboarding or Settings, tap "Restore Data"; select iCloud/Local `.nivorabackup`. | Decrypts and restores all tables cleanly. | `[DEVICE REQUIRED]` |
