# Nivora repository quality report

## Scope

This audit reviewed the repository structure, Flutter manifest, source tree, Drift schema, Riverpod providers, authentication, notifications, backup service, Android manifest, tests, CI workflows, license, existing documentation, and available image assets. It also compared the information design against public README patterns used by open-source cycle-tracking projects.

## What changed

The repository now has an evidence-based README with a product explanation, target users, feature status table, product flow, architecture diagram, domain model, setup instructions, privacy limits, medical disclaimer, project status, roadmap, contribution links, and references. The previous fixed test-count badge and release-certification language were removed because they were too easy to misread as current, independently verified guarantees.

`SECURITY.md` was added with private disclosure guidance, sensitive-data handling rules, and a bounded description of the current security posture. `CONTRIBUTING.md` was rewritten to match the Flutter project and to correct the previous contribution and testing guidance. `assets/screenshots/README.md` records the expected screenshot layout and explicitly documents that the supplied screenshot pack is missing from this checkout.

## Verified from code

- The application is Flutter and Dart, with Android and iOS project files.
- Persistence uses Drift over SQLite with schema version 6 and multiple DAOs.
- Riverpod providers coordinate the database and feature controllers.
- The reviewed production application source contains no HTTP client, analytics endpoint, or cloud synchronizer.
- Android release configuration disables Android cloud backup. The debug manifest retains Flutter's development INTERNET permission.
- `local_auth` is used for platform authentication and lifecycle masking is present in the app code.
- `flutter_local_notifications` schedules local routine reminders. Android scheduling is inexact.
- Backup V2 uses PBKDF2 with HMAC-SHA-256, 100,000 iterations, a random 16-byte salt, and AES-256-GCM with a random 12-byte nonce and a 128-bit tag.
- Restore validates the decrypted payload before replacing tables inside a transaction.
- Tests cover database behavior, migrations, reports, notifications, backups, widgets, state, and offline PDF generation.
- The repository is licensed under Business Source License 1.1.

## Unverified or still limited

- The screenshot pack was not present in the checkout, so no README screenshots were added.
- Physical-device behavior for biometrics, app-switcher masking, notification delivery, file import, printing, and iOS compilation remains a release-readiness task.
- The database is standard SQLite and is not SQLCipher-encrypted.
- No independent security audit, regulatory certification, HIPAA or GDPR compliance, or clinical validation was found.
- A fixed test count and coverage percentage were not published because the current command output was not used as a release badge.
- CI workflows exist for release-oriented builds, but a general analysis-and-test workflow was not found.

## Recommended next improvements

1. Add the real screenshot pack and capture it from a controlled build with synthetic data.
2. Add a pull-request workflow that runs formatting checks, `dart analyze`, generated-code consistency checks, and `flutter test`.
3. Complete the physical-device validation matrix on supported Android and iOS versions.
4. Decide whether the standard SQLite at-rest model is sufficient for the intended threat model or whether a maintained database-encryption strategy is required.
5. Review clinical and health terminology with an appropriate subject-matter reviewer before making store or clinical-context claims.
6. Add a documented backup recovery test that covers wrong passphrases, corrupted files, legacy V1 imports, and interrupted restore operations.

## Audit conclusion

Nivora contains meaningful implementation work and a credible local-first architecture. The repository is strongest when it describes concrete code paths, data boundaries, and known limits. It should continue to present itself as a beta application under active development rather than as a clinically validated or fully audited health product.
