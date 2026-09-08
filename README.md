# Imyra 🌸
**A private, local-first clinical compliance notebook for women.**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Database](https://img.shields.io/badge/Database-Drift_SQLite-green.svg)](https://drift.simonbinder.eu/)
[![Privacy](https://img.shields.io/badge/Privacy-100%25_Local-F43F5E.svg)](#privacy-manifesto)

Imyra is not "just another period tracker." Most FemTech apps monetize through fear, predictive vanity, and data extraction. Imyra is built for **clinical utility and recall relief**, specifically designed for women managing doctor-directed routines, irregular cycles, and PMDD. 

It generates a standardized clinical PDF for a 7-minute doctor consultation while ensuring the user's intimate health data never leaves her physical device.

---

## ✨ Core Features (V2 Beta)

*   **100% Local-First Architecture:** Zero cloud sync. Zero accounts. Data is stored strictly on the device. *(Note: The local Drift database is currently unencrypted at rest natively; SQLCipher integration is planned for V3).*
*   **Biometric Security & Encrypted Backups:** Protected by FaceID/Fingerprint locks and fully exportable via AES-256 encrypted payloads (hardened by PBKDF2 key derivation).
*   **Clinical Report Generator:** A 1-tap engine that condenses 6 months of adherence, symptom alignments (e.g. Luteal Pattern), and treatment benchmarks into a standardized, 1-page A4 PDF. Utilizes compassionate, phenotype-centric framing rather than rigid alerting.
*   **PCOS & Extreme Cycle Guardrails:** Beautiful, responsive cycle graphs that dynamically handle and visually cap highly irregular cycles (45-120 days).
*   **Smart Disambiguation:** Differentiates between true cycle starts (Day 1) and pre-period spotting for accurate baseline data.
*   **21/7 Routine Engine:** Custom medication reminders tailored for birth control or cyclical hormone treatments, complete with local push notifications. Includes a "Catch Up" drawer with retroactive time-picker logging for clinical adherence accuracy.
*   **Premium Animations:** Micro-animations provide buttery smooth transitions that create a venture-backed, native-feeling aesthetic.

---

## 🎨 Visual Identity & UI

Imyra's UI/UX takes inspiration from top-tier productivity utilities (like Cal.com and Todoist) rather than traditional health apps.
*   **The Canvas:** Stark, crisp Linen White (`#FAFAFA`) and Absolute Onyx (`#111111`).
*   **The Signature Color:** **Imyra Rose (`#F43F5E`)** — a striking, confident pinkish-rose that drives all primary actions.
*   **The Logo:** A bold geometric 'i' combining the Cycle Dot and the Routine Capsule, providing total lock-screen discretion.

---

## 🏗 Tech Stack

*   **Framework:** [Flutter](https://flutter.dev) (Cross-platform iOS & Android)
*   **Local Storage:** [Drift](https://drift.simonbinder.eu/) (Type-safe SQLite)
*   **State Management:** [Riverpod](https://riverpod.dev/) (Reactive caching and dependency injection)
*   **Security:** `local_auth` (FaceID/Biometrics) and `encrypt` (AES-256)
*   **UI & Polish:** `flutter_animate`
*   **PDF Generation:** `pdf` and `printing` packages
*   **Testing:** `flutter_test` (Unit) and `integration_test` (E2E)
---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.x or higher)
*   Dart SDK
*   Xcode (for iOS builds) / Android Studio (for Android builds)

### 1. Install Dependencies
```bash
flutter pub get

```

### 2. Run Code Generation

Because Imyra uses Drift for SQLite and Riverpod for state management, you must run the build runner to generate the data classes:

```bash
dart run build_runner build --delete-conflicting-outputs

```

### 3. Generate Branding Assets

Generate the high-resolution Imyra Rose icons and native splash screens:

```bash
flutter test lib/core/utils/generate_icon_assets.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create

```

### 4. Run the App

```bash
flutter run

```

---

## 🧪 Quality Assurance & Testing

Before deploying any release build, the QA suite must pass. This guarantees clinical date math (like PMDD luteal clustering) is perfectly accurate.

**Run Unit & Database Integrity Tests:**

```bash
flutter test

```

**Run End-to-End (E2E) Smoke Test:**
(Ensure a physical device or emulator is running)

```bash
flutter test integration_test/app_flow_test.dart

```

---

## 🔒 Privacy Manifesto (The "Imyra Promise")

1. **No Tracking:** No analytics SDKs (no Firebase Analytics, no Mixpanel, no Meta Pixel).
2. **No Ads:** The UI will never push sponsored wellness content.
3. **Instant Purge:** The Settings menu contains a 1-tap "Erase All Data" button that executes a complete SQL `DROP` on all tables instantly.

---
<p align="center">
<em>Built for women, memory, and peace of mind.</em>
</p>