# NIVORA 🌸
**A private, local-first clinical health notebook for women.**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Database](https://img.shields.io/badge/Database-Drift_SQLite-green.svg)](https://drift.simonbinder.eu/)
[![Privacy](https://img.shields.io/badge/Privacy-100%25_Local-F43F5E.svg)](#-privacy-architecture--security-model)
[![Tests](https://img.shields.io/badge/Tests-88%20Passed-brightgreen.svg)](#-testing--quality-assurance)

Nivora is not just another period tracker. Most commercial FemTech applications monetize through invasive data brokers, opaque cloud storage, and predictive vanity metrics. **Nivora** is engineered for **clinical utility, longitudinal compliance, and diagnostic recall relief** — purpose-built for individuals managing doctor-directed regimens, PCOS, irregular cycles, and PMDD.

It generates an authentic, standardized clinical report for consultation with healthcare providers while ensuring intimate health data **never leaves the physical device**.

---

## ✨ Core Pillars & Features

* **100% Local-First & Zero-Cloud:** No account creation, no cloud sync, no tracking beacons, no analytics SDKs. All data resides in an isolated on-device SQLite database via Drift.
* **Automatic, Safe Database Migration:** Upgraded from legacy schemas seamlessly with physical backup preservation, maintaining historical logs without data loss.
* **Biometric Authentication & App Masking:** Local biometric lock (FaceID/Fingerprint) with an instant privacy shield overlay when backgrounded, preventing screenshots or unauthorized app-switcher snooping.
* **Encrypted Backups (AES-256-GCM + PBKDF2):** Export and restore full encrypted backups (`.nivorabackup`) protected by user passphrases, with strict backwards compatibility for legacy backup files.
* **Evidence-Based Health Engine (Rotterdam Consensus):** Clinically sound PCOS evaluation implementing consensus guidelines:
  - Requires a minimum of 2 tracked cycles before evaluating cycle-length variance.
  - Oligo/amenorrhea (>35 days or <21 days) and cycle variance (>9 days) evaluated against true historical data.
  - Phenotype classification (Phenotype A, D, etc.) with transparent criteria.
* **Deterministic Event Merging:** Logging symptoms or flow multiple times on the same date safely merges attributes instead of overwriting, preventing lost bleeding or pain records.
* **Offline Unicode Clinical PDF Generator:** Generates comprehensive multi-page clinical consultation summaries completely offline without network calls. Bundled TrueType typography eliminates missing glyph warnings and guarantees 100% air-gapped generation.
* **In-Clinic Consultation Glance:** Authentic bedside clinical view displaying key metrics, heavy bleeding/flooding indicators, and protocol adherence at a glance for in-person doctor visits.
* **Cryptographic Data Destruction:** "Erase All Data" triggers `PRAGMA secure_delete = ON` (overwriting deleted records with zeros), purges all operational tables in a single transaction, and executes `VACUUM` to rebuild the SQLite database file and eliminate unallocated disk space.
* **Accessible & High-Contrast Design:** WCAG AAA-compliant text contrasts (`#525252` on `#FAFAFA` and `#FFFFFF`), high-contrast dark mode, and responsive layout across phones and tablets.

---

## 🔒 Privacy Architecture & Security Model

```
+-------------------------------------------------------------+
|                      NIVORA CLIENT                          |
|                                                             |
|  +------------------+             +----------------------+  |
|  | Presentation UI  | <---------> | Riverpod Controllers |  |
|  +------------------+             +----------------------+  |
|           |                                  |              |
|           v                                  v              |
|  +------------------+             +----------------------+  |
|  | Local Biometrics |             |   Drift SQLite DB    |  |
|  |   & App Mask     |             |  (nivora_health.db)  |  |
|  +------------------+             +----------------------+  |
|                                              |              |
|                                              v              |
|                                   +----------------------+  |
|                                   |  AES-256-GCM Backup  |  |
|                                   | (PBKDF2 Key Deriv.)  |  |
|                                   +----------------------+  |
+-------------------------------------------------------------+
                              |
                              X  NO NETWORK / NO CLOUD
                              |
                     [ AIR-GAPPED DEVICE ]
```

1. **Local Sandbox Isolation:**
   - Android cloud backup disabled (`android:allowBackup="false"`, `android:fullBackupContent="false"` in `AndroidManifest.xml`).
   - Operating system app switcher preview masked with a secure overlay.
2. **Deterministic Data Merging:**
   - Same-day cycle events (flow intensity, spotting, pelvic pain, clots, flooding) are merged via upsert transactions to prevent accidental data loss.
3. **No Network Telemetry:**
   - The app operates under strict offline assumptions. No external HTTP requests, analytics endpoints, or cloud synchronizers exist in the codebase.
4. **Permanent Shredding:**
   - Erasing data zeroes out pages physically via SQLite secure delete and vacuuming.

---

## 🎨 Design System

* **Canvas:** Stark Linen White (`#FAFAFA`) & Deep Slate (`#121212`)
* **Surfaces:** Pure White (`#FFFFFF`) & Midnight Card Surface (`#1E1E1E`)
* **Primary Accent:** **Nivora Rose (`#F43F5E`)** — an assertive, accessible rose-red
* **Typography:** Clean sans-serif with WCAG AAA contrast compliance (`#111111` titles, `#525252` body/captions)
* **Visual Polish:** Spring curves and micro-animations via `flutter_animate`

---

## 🏗 Technology Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter 3.x](https://flutter.dev) (Dart SDK >= 3.0.0) |
| Local Database | [Drift](https://drift.simonbinder.eu/) + SQLite |
| State Management | [Riverpod](https://riverpod.dev/) 3.x (`riverpod_annotation`, code-gen) |
| Offline PDF Engine | `pdf` + `printing` + bundled TrueType fonts |
| Encryption | `pointycastle` / `encrypt` (PBKDF2 + AES-256-GCM) |
| Biometric Security | `local_auth` (FaceID, Fingerprint, Biometric Prompt) |
| Platform Targets | Android (`com.nivora.health`), iOS (`com.nivora.health.NivoraApp`) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.24+ recommended)
- Dart SDK (v3.5+)
- Android Studio / Xcode

### 1. Install Dependencies
```powershell
flutter pub get
```

### 2. Run Code Generation (Drift & Riverpod)
```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run Static Analysis & Verification
```powershell
dart analyze
```

### 4. Execute Full Test Suite
```powershell
flutter test
```

---

## 🧪 Testing & Quality Assurance

Nivora features a rigorous test suite covering database transactions, migration resilience, clinical engine calculations, UI widgets, and offline security:

* **Offline Resilience:** `test/offline_verification_test.dart` ensures PDF generation executes with an enforced global `HttpOverrides` that throws if any network call is attempted.
* **Rotterdam Consensus:** `test/core/database/report_dao_test.dart` verifies that 0 or 1 logged cycles do not produce false positive ovulatory dysfunction flags.
* **Menstrual Overwrite Prevention:** `test/features/cycle/cycle_controller_test.dart` confirms symptom updates on the same date merge cleanly without dropping flow attributes.
* **Encrypted Backup & Restore:** `test/features/settings/backup_restore_test.dart` verifies AES-256 key derivation, payload integrity, and backward compatibility with `.imyrabackup` archives.
* **Biometric App Masking:** `test/features/security/app_mask_test.dart` tests privacy overlay activation on lifecycle pauses.

---

## 📦 Building for Production

### Android Release APK:
```powershell
$env:TEMP = "D:\temp"; $env:TMP = "D:\temp"; flutter build apk --release
```

### Android App Bundle (AAB):
```powershell
$env:TEMP = "D:\temp"; $env:TMP = "D:\temp"; flutter build appbundle --release
```

---

<p align="center">
  <strong>NIVORA</strong> &bull; Private. Clinical. Local-First.
</p>