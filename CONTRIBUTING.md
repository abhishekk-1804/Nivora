# Contributing to Nivora

Thank you for taking the time to improve Nivora. Contributions are welcome when they preserve the project's local-first design, treat health information carefully, and make implementation status clear.

## Before you start

Read [`LICENSE`](LICENSE) before cloning, modifying, or redistributing the project. Nivora is licensed under the Business Source License 1.1, not a permissive open-source license. Follow the terms in the license file and do not assume that a public repository grants commercial-use rights.

For security issues, use the process in [`SECURITY.md`](SECURITY.md) instead of opening a public issue with sensitive details.

## Development setup

Use a Flutter SDK compatible with the constraint in [`pubspec.yaml`](pubspec.yaml). Install dependencies with:

```bash
flutter pub get
```

If you change Drift tables, DAOs, or annotated Riverpod providers, regenerate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run analysis and tests before submitting a change:

```bash
dart analyze
flutter test
```

Run integration tests separately on a configured emulator or device:

```bash
flutter test integration_test
```

## Making a change

1. Create a focused branch from the current default branch.
2. Keep each change small enough to review.
3. Add or update tests for behavior changes.
4. Update documentation when a public flow, data model, permission, backup format, or security property changes.
5. Use synthetic data only. Do not add real health records, exported backups, device identifiers, or credentials.
6. Open a pull request using the repository template and describe limitations or unverified behavior.

## Engineering expectations

Use Flutter and Riverpod conventions already present in the codebase. Keep persistence behind Drift DAOs and preserve migration compatibility. When changing cycle calculations or report aggregation, explain the rule in code and add fixtures that cover edge cases. Do not describe a calculation as a diagnosis or clinical validation unless independent evidence supports that claim.

Preserve the offline product boundary. Do not add analytics, advertising, remote synchronization, or a new external service without a documented design review and an explicit change to the project's privacy model.

Notification changes must account for platform permissions, time zones, inexact Android scheduling, and lifecycle rehydration. Authentication and privacy-overlay changes require platform-aware tests and should be checked on physical devices before release claims are made.

## Pull request checklist

- [ ] The change has a clear user or engineering purpose.
- [ ] `dart analyze` passes.
- [ ] Relevant `flutter test` tests pass.
- [ ] Generated files are updated when required.
- [ ] New behavior has focused tests.
- [ ] Documentation distinguishes implemented, partial, planned, and unverified behavior.
- [ ] No sensitive data, credentials, or generated backups are included.
- [ ] License and privacy implications are understood.
