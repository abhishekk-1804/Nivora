# Nivora Release Readiness & Certification Report

**Application:** Nivora  
**Package / Application ID:** `com.nivora.health`  
**iOS Bundle Identifier:** `com.nivora.health.NivoraApp`  
**Repository:** `D:\imyra_health`  
**Git Remote:** `https://github.com/abhishekk-1804/Nivora.git`  
**Head Commit:** `dce6e70`  
**Baseline Tag:** `nivora-baseline` (`8e1a716`)  
**Certification Date:** 2026-09-23  

---

## 1. Executive Summary

Nivora is an offline, privacy-first hormonal and metabolic health notebook engineered for individuals managing doctor-directed regimens, PCOS, irregular cycles, and PMDD. This document serves as the official Release Certification and Software Readiness Report.

The application has completed all software-verifiable release hardening cycles. It operates without remote cloud backends, network tracking, or analytics SDKs. All operational data is stored on-device in a platform-sandboxed SQLite database, with authenticated AES-256-GCM encryption for user-initiated offline backups.

### Release Classification Summary
- **Software & Static Analysis:** `[VERIFIED]` (0 issues, 100% clean)
- **Automated Test Suite:** `[VERIFIED]` (114/114 tests passing across 31 test files)
- **Zero-Network / Air-Gap Isolation:** `[VERIFIED]` (No INTERNET permission in release manifest; runtime font downloads disabled)
- **Cryptographic Backup Security:** `[VERIFIED]` (AES-256-GCM + PBKDF2 100k iterations with tamper & truncation rejection)
- **Android Release Compilation:** `[VERIFIED]` (Release APK & AAB clean build)
- **Production Keystore Signing:** `[PARTIALLY VERIFIED]` (Gradle release configuration verified with debug fallback when developer `key.properties` is absent)
- **Physical Device Biometrics & Platform Push:** `[DEVICE/PLATFORM REQUIRED]` (Requires physical biometric sensor and OS vendor battery cycle verification)

---

## 2. Architecture

Nivora follows a clean, reactive architecture with strict layer separation:

- **Presentation Layer:** Flutter Material Design 3 with custom accessible high-contrast design tokens (`AppColors`, WCAG AAA compliance). Micro-animations orchestrated via `flutter_animate`.
- **State Management & Business Logic:** Riverpod 3 (`flutter_riverpod` + code generation via `riverpod_annotation`). Controllers handle business rules, date calculations, and isolate execution without coupling to the widget tree.
- **Data Access Layer:** Type-safe Object-Relational Mapping (ORM) powered by [Drift](https://drift.simonbinder.eu/) with SQLite. Direct table operations are encapsulated within Data Access Objects (`CycleDao`, `RoutineDao`, `ReportDao`, `ClinicalProfileDao`, `MetabolicLogDao`).
- **Engine Layer:** Deterministic domain logic for:
  - Cycle start detection and mid-cycle spotting differentiation (`isTrueCycleStart`).
  - Rotterdam consensus evaluation requiring $\ge 2$ observed cycles before evaluating cycle-length variance.
  - Moving window scheduling for cyclic regimens (21 active / 7 break days) capped at 14 active notification slots to respect platform limits.

---

## 3. Security Model

Nivora enforces a zero-trust, local-first sandbox model:

1. **Operating System App Sandboxing:**
   - On Android, all database and preference files reside in `/data/data/com.nivora.health/`.
   - On iOS, files reside in the sandboxed app container.
   - Operating system cloud backup is explicitly disabled in `android/app/src/main/AndroidManifest.xml` (`android:allowBackup="false"`, `android:fullBackupContent="false"`).
2. **App Masking & Lifecycle Guarding:**
   - When the application transitions to `AppLifecycleState.inactive` or `paused`, `NivoraApp` activates a full-screen masking shield rendering `NivoraLogo`. This prevents sensitive clinical details from being captured in the OS recent-apps task switcher.
3. **Biometric Guard:**
   - Supported via `local_auth` (FaceID, Fingerprint). Bypasses UI rendering until authenticated, with graceful fallback to system device PIN/passcode.
4. **Permanent Data Shredding:**
   - Erase-all-data executes `PRAGMA secure_delete = ON` (overwriting deleted pages with zeros), deletes all operational tables within a single atomic transaction, and executes `VACUUM` to rebuild the SQLite file and clear unallocated disk blocks.

---

## 4. Backup Cryptography (Version 2 Specification)

Exported backups use true authenticated encryption:

- **Cipher:** AES-256-GCM (`pointycastle` `GCMBlockCipher(AESEngine())`).
- **Key Derivation:** PBKDF2 with HMAC-SHA256, 100,000 iterations, yielding a 32-byte (256-bit) key.
- **Salt:** 16 cryptographically secure random bytes generated per backup via `enc.IV.fromSecureRandom(16)`.
- **Nonce / IV:** 12 cryptographically secure random bytes (96 bits) standard for GCM mode.
- **Authentication Tag:** 128-bit MAC tag appended to the ciphertext.
- **Envelope Format:**
  ```
  NIVORA-BACKUP-V2:<salt_base64>:<nonce_base64>:<ciphertext_with_tag_base64>
  ```
- **Cryptographic Tamper Protection:**
  - Modifying any single byte in the ciphertext, nonce, or tag throws a `FormatException` before payload parsing.
  - Truncated archives or payloads missing the 16-byte authentication tag fail safely.
  - Wrong passphrases fail immediately without modifying database contents.
  - Passphrase byte arrays in memory are zeroed (`fillRange(0, length, 0)`) immediately after PBKDF2 derivation.
  - Backward compatibility: Legacy V1 `.imyrabackup` archives (unauthenticated `salt:iv:ciphertext` format) remain fully decryptable.

---

## 5. Database Posture

| Property | Status | Implementation Detail |
|---|---|---|
| **Database Engine** | SQLite 3 via Drift | Native SQLite (`NativeDatabase.createInBackground(...)`) |
| **Current Schema Version** | Version 6 | Tables: `CycleEvents`, `Routines`, `RoutineLogs`, `TreatmentInterventions`, `LabResults`, `ClinicalProfile`, `MetabolicLogs` |
| **Encryption At Rest** | OS Sandboxing + Device FBE | **Not encrypted with SQLCipher.** Stored as standard SQLite file in app-private sandbox. Security relies on hardware File-Based Encryption (FBE) and OS user-space permissions. |
| **Legacy Database Migration** | Verified | Automatic migration from legacy schema V1 (`Ila_health.sqlite`) to V6 (`nivora_health.sqlite`) creates a physical `.bak` file before migration. |
| **Same-Day Menstrual Logging** | Deterministic Upsert | Merges multiple entries on the same date rather than overwriting existing flow or pain metrics. |

---

## 6. Offline & Privacy Posture

- **Network Permission:** `android.permission.INTERNET` is completely absent from `android/app/src/main/AndroidManifest.xml`.
- **Third-Party Telemetry:** Zero analytics SDKs, zero crash reporters (no Firebase, Crashlytics, Sentry, Mixpanel, Datadog).
- **Remote Fonts:** Runtime font fetching over HTTP is explicitly disabled via `GoogleFonts.config.allowRuntimeFetching = false`. All typography relies on local system fonts and bundled TrueType fonts (`Roboto`, `FleurDeLeah`).
- **Offline PDF Generation:** PDF documents are compiled entirely in memory using bundled fonts and shared via native platform share sheets (`share_plus`, `printing`). Verified via `OfflineHttpOverrides` that throws if any network socket is opened.

---

## 7. Android Permissions

Verified in `android/app/src/main/AndroidManifest.xml`:

| Permission | Purpose | Google Play Policy Compliance |
|---|---|---|
| `RECEIVE_BOOT_COMPLETED` | Reschedules active routine notifications on device restart. | Standard / Compliant |
| `POST_NOTIFICATIONS` | Android 13+ runtime notification prompt. | Standard / Compliant |
| `USE_BIOMETRIC` | Biometric prompt API. | Standard / Compliant |
| `USE_FINGERPRINT` | Legacy biometric prompt fallback. | Standard / Compliant |
| `VIBRATE` | Haptic feedback for notifications. | Standard / Compliant |
| `INTERNET` | **ABSENT** | Guarantees zero cloud telemetry. |
| `USE_EXACT_ALARM` | **REMOVED** | Complies with Play Store exact-alarm restriction. |
| `SCHEDULE_EXACT_ALARM` | **REMOVED** | Routine reminders use inexact idle mode (`inexactAllowWhileIdle`). |

---

## 8. Test Matrix (114 Tests / 100% Passed)

Verified via `flutter test`:

| File | Tests | Focus Area | Status |
|---|:---:|---|:---:|
| `test/offline_verification_test.dart` | 1 | Zero-network air-gap enforcement with `OfflineHttpOverrides` | `[VERIFIED]` |
| `test/core/database/app_database_test.dart` | 3 | Core SQLite initialization and transactions | `[VERIFIED]` |
| `test/core/database/critical_data_integrity_test.dart` | 7 | Deep data integrity and schema invariants | `[VERIFIED]` |
| `test/core/database/database_migration_test.dart` | 4 | Legacy V1 to V6 schema migration and `.bak` file creation | `[VERIFIED]` |
| `test/core/database/performance_test.dart` | 1 | Query performance across 10-year simulated cycle history | `[VERIFIED]` |
| `test/core/database/report_dao_test.dart` | 3 | Ovulatory dysfunction criteria and Rotterdam variance | `[VERIFIED]` |
| `test/core/notifications/notification_service_test.dart` | 3 | Inexact scheduling, 21/7 cyclic moving window, lockscreen privacy | `[VERIFIED]` |
| `test/core/services/backup_restore_roundtrip_test.dart` | 6 | Multi-table lossless roundtrip, wrong password, corruption | `[VERIFIED]` |
| `test/core/services/backup_service_null_path_test.dart` | 3 | Cloud storage null-path safety handling | `[VERIFIED]` |
| `test/core/services/backup_service_test.dart` | 9 | AES-256-GCM tamper rejection, nonce/tag validation, V1 compat | `[VERIFIED]` |
| `test/core/state/state_disposal_test.dart` | 1 | Riverpod state disposal hygiene | `[VERIFIED]` |
| `test/core/utils/date_math_test.dart` | 2 | Calendar date calculations and leap years | `[VERIFIED]` |
| `test/features/cycle/cycle_controller_test.dart` | 10 | Same-day menstrual event merging and symptom updates | `[VERIFIED]` |
| `test/features/cycle/cycle_graph_test.dart` | 2 | Cycle length clamping (45-120d) and layout safety | `[VERIFIED]` |
| `test/features/cycle/quick_log_sheet_test.dart` | 5 | Quick log interaction and field validation | `[VERIFIED]` |
| `test/features/onboarding/onboarding_screen_test.dart` | 1 | Onboarding flow and restore entry point | `[VERIFIED]` |
| `test/features/report/doctor_in_clinic_dialog_test.dart` | 3 | In-clinic bedside view, Phenotypes A-D, PDF export trigger | `[VERIFIED]` |
| `test/features/report/doctor_pdf_generator_test.dart` | 1 | Multi-page PDF generation with clinical advisory notice | `[VERIFIED]` |
| `test/features/report/report_aggregation_test.dart` | 4 | Observational window aggregation and treatment benchmarks | `[VERIFIED]` |
| `test/features/routines/phase_state_machine_test.dart` | 6 | Regimen state transitions (daily, cyclic 21/7) | `[VERIFIED]` |
| `test/features/routines/routine_save_test.dart` | 1 | Routine persistence to SQLite | `[VERIFIED]` |
| `test/features/routines/routine_setup_sheet_test.dart` | 6 | Form input validation and regimen selection | `[VERIFIED]` |
| `test/features/security/app_mask_test.dart` | 1 | Privacy overlay activation on app background/inactive | `[VERIFIED]` |
| `test/features/settings/backup_restore_test.dart` | 3 | Edge cases in backup restore and passphrase memory wiping | `[VERIFIED]` |
| `test/features/settings/settings_screen_test.dart` | 1 | Settings screen UI rendering and data destruction prompt | `[VERIFIED]` |
| `test/features/splash/splash_screen_test.dart` | 3 | Navigation routing and onboarding bypass on restore | `[VERIFIED]` |
| `test/features/today/clinical_log_sheet_test.dart` | 5 | Clinical profile updates and lab result entries | `[VERIFIED]` |
| `test/features/today/metabolic_log_sheet_test.dart` | 5 | Metabolic log entries, unit toggling, strict validation | `[VERIFIED]` |
| `test/features/today/today_controller_test.dart` | 8 | Daily checklist state transitions and adherence logging | `[VERIFIED]` |
| `test/features/today/today_screen_test.dart` | 4 | Today screen widgets, energy chips, quick log sheet triggers | `[VERIFIED]` |
| `test/features/today/today_state_test.dart` | 2 | Daily state immutability | `[VERIFIED]` |
| **TOTAL** | **114 Tests** | **31 Test Files — 100% Passed (0 Failures)** | `[VERIFIED]` |

---

## 9. Build Matrix

| Build Target | Command | Result | Artifact Path | Size |
|---|---|---|---|---|
| **Android Release APK** | `flutter build apk --release` | `[VERIFIED]` | `build/app/outputs/flutter-apk/app-release.apk` | ~76.1 MB |
| **Android Release AAB** | `flutter build appbundle --release` | `[VERIFIED]` | `build/app/outputs/bundle/release/app-release.aab` | ~45.8 MB |
| **iOS Release Archive** | `flutter build ipa --release` | `[PLATFORM REQUIRED]` | Requires macOS with Xcode | N/A |

---

## 10. Signing Status

- **Build Configuration:** `android/app/build.gradle.kts` inspects `rootProject.file("key.properties")`.
- **Debug Fallback:** When `key.properties` is absent, the release build automatically uses the debug signing key (`signingConfig = signingConfigs.getByName("debug")`).
- **Production Store Distribution:** `[PARTIALLY VERIFIED]`. To publish on Google Play, the developer must:
  1. Copy `android/key.properties.example` to `android/key.properties`.
  2. Populate `storePassword`, `keyPassword`, `keyAlias`, and `storeFile` pointing to their private `.keystore` or `.jks`.
  3. Ensure `key.properties` and keystores remain ignored by Git (enforced in `.gitignore`).

---

## 11. Device Validation Status (Android)

Marked as `[DEVICE/PLATFORM REQUIRED]`:
- [ ] Fresh installation and first-launch permission prompt (`POST_NOTIFICATIONS`).
- [ ] Hardware biometric enrollment and prompt verification (FaceID / Fingerprint).
- [ ] App task-switcher obscuring on hardware recent-apps transition.
- [ ] Inexact routine reminder receipt across vendor Doze / battery-saver modes (Samsung OneUI, Xiaomi MIUI, Google Pixel).
- [ ] File picker import of `.nivorabackup` across Android SAF (Storage Access Framework).
- [ ] System PrintManager spooling to physical wireless printer.

---

## 12. iOS Validation Status

Marked as `[DEVICE/PLATFORM REQUIRED]`:
- [ ] macOS Xcode compilation of `com.nivora.health.NivoraApp`.
- [ ] FaceID authentication prompt with `NSFaceIDUsageDescription` display.
- [ ] AirPrint PDF spooling from `Printing.layoutPdf`.
- [ ] File sharing and Document Picker integration (`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`).

---

## 13. Known Limitations

1. **Database At Rest:** The local SQLite database is not encrypted via SQLCipher. Data at rest is protected solely by operating system sandbox isolation and device-level hardware encryption (Android File-Based Encryption, iOS Data Protection). Rooted or jailbroken devices have access to internal app storage.
2. **Notification Exactness:** Routine reminders utilize `AndroidScheduleMode.inexactAllowWhileIdle` to comply with Google Play policies. Delivery times may vary by several minutes depending on device power management.

---

## 14. Release Checklist

- [x] Zero static analysis issues (`dart analyze`).
- [x] Full automated test suite passes (114/114).
- [x] Manifest permissions cleaned: no INTERNET, no exact alarm permissions.
- [x] Google Fonts runtime fetching permanently disabled.
- [x] Backup format upgraded to authenticated AES-256-GCM.
- [x] Tamper detection verified for ciphertext, nonce, tag, and truncation.
- [x] Rotterdam criteria incorporates ultrasound PCOM parameter.
- [x] Doctor in-clinic dialog layout overflow resolved.
- [x] Clinical advisory disclaimer included in offline PDF summary.
- [x] Localization keys complete and consistent across English, Spanish, Hindi.
- [x] Release APK and AAB build successfully.
- [ ] Developer signs APK/AAB with private production keystore.
- [ ] Physical device smoke test.

---

## 15. Exact Verification Commands

```powershell
# Set temporary directory for build environment
$env:TEMP = "D:\temp"; $env:TMP = "D:\temp"

# Clean build artifacts
flutter clean

# Retrieve dependencies
flutter pub get

# Run static analysis
dart analyze

# Run complete automated test suite
flutter test --reporter=compact

# Compile release APK
flutter build apk --release

# Compile release App Bundle (AAB)
flutter build appbundle --release
```

---

## 16. Git Commit References

```
dce6e70 fix(repo): restore clean UTF-8 formatting and keystore ignores in .gitignore
6619558 docs: add final release audit, device validation protocol, and store release checklist
d9ee6d3 docs: add RELEASE_READINESS.md certification report and update README badges
50b7fa3 feat(release): enforce zero-network font fetching, add clinical advisory to PDF, and add notification scheduling tests
e4eeff7 fix(android): remove unnecessary SCHEDULE_EXACT_ALARM permission for inexact alarms
abe9ab7 docs: clarify database at-rest sandbox posture and document AES-256-GCM backup encryption
1770a34 feat(security): upgrade backup encryption to AES-256-GCM authenticated encryption (Phase 2)
3a5d829 fix(release): eliminate prohibited USE_EXACT_ALARM, resolve dialog layout overflow, accurate Rotterdam mapping, and add keystore template
aa50d6a test(security): update app_mask_test to reference NivoraApp directly
e02b3d8 test(backup): add end-to-end multi-table encrypted backup and restore validation (Phase E)
0a32d01 test(database): add deterministic database migration and legacy upgrade validation (Phase D)
fe5ccd2 feat(qa): clean accidental branding leftovers and add deep data integrity test suite (Phases A & C)
b5f8500 feat(release): complete Nivora offline PDF, authentic in-clinic view, WCAG AAA polish, and documentation
68388c4 feat: improve ovulatory dysfunction accuracy and clinical cycle variance (Phase 4)
6467c59 feat: secure local-first sandbox and disable OS cloud backup (Phase 3)
506ddd5 feat: stabilize data integrity, fix menstrual overwrite bug, centralize preference keys, and expose DAO providers (Phase 2)
c251d8b feat: complete Nivora rebrand and safe database migration (Phase 1)
8e1a716 feat: initialize Nivora (nivora-baseline)
```
