# Contributing to Imyra Health

Thank you for your interest in contributing to the Imyra Health Application! 

## Licensing & Business Source License 1.1

Imyra Health is licensed under the **Business Source License 1.1 (BSL)**. 
Please read the `LICENSE` file carefully before contributing or forking this repository.

### What this means for you:
1. **Personal / Educational Use**: You are fully permitted to clone, modify, and run this application strictly for personal health tracking, testing, and educational purposes.
2. **Non-Commercial**: You cannot use this source code (or derivative works) in a commercial or production capacity without purchasing a commercial license from the Licensor, Susmita Dey.
3. **Change Date**: On the Change Date (August 16, 2030), this license will automatically convert to the permissive **MIT License**.

### Submitting Pull Requests
If you wish to contribute bug fixes, translations, or new features back to the main repository:
1. **Fork the repository** (keeping in mind the BSL terms).
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`).
3. **Commit your changes** (`git commit -m 'Add amazing feature'`).
4. **Push to the branch** (`git push origin feature/amazing-feature`).
5. **Open a Pull Request**.

*Note: By submitting a Pull Request, you agree to license your contribution under the same BSL 1.1 terms as the main project.*

## Development Setup

1. **Flutter Version**: Ensure you are running Flutter SDK 3.13.0 or higher (Dart 3.0+).
2. **Code Generation**: We use `drift` and `riverpod`. If you modify database schemas or providers, you must run the code generator:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Testing**: Before submitting a PR, ensure all 21+ unit, database, and integration tests pass:
   ```bash
   flutter test
   ```

## Architectural Guidelines
- **No Cloud Data**: Imyra is strictly a local-first application. Do not submit PRs that add third-party analytics (e.g., Firebase Analytics, Mixpanel) or external database syncing unless explicitly built as an end-to-end encrypted backup feature managed by the user.
- **State Management**: Use `flutter_riverpod`. Avoid `setState` for global logic.
- **Clinical Accuracy**: Any changes to cycle tracking or symptom clustering must adhere to DSM-5 criteria and be verified in `test/core/database/report_dao_test.dart`.
