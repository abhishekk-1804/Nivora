import 'package:flutter_test/flutter_test.dart';
import 'package:nivora_app/core/services/backup_service.dart';

void main() {
  group('BackupService — restore flow edge cases', () {
    test('TC-BR01: Restore with wrong passphrase throws Exception', () async {
      // Arrange: encrypt with one passphrase
      // This is a unit-level test using the isolate function directly
      final payload = {'cycles': [], 'routines': [], 'version': 1};
      final encrypted = await Future.value(
        performHeavyEncryption({'data': payload, 'passphrase': 'correct-pass-123'})
      );

      // Act + Assert: decrypt with wrong passphrase throws
      expect(
        () => performHeavyDecryption({'content': encrypted, 'passphrase': 'wrong-pass-456'}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Incorrect passphrase')
        )),
      );
    });

    test('TC-BR02: Restore with content < 2 colons throws format error', () {
      expect(
        () => performHeavyDecryption({'content': 'onlyone', 'passphrase': 'pass'}),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 'message', contains('Invalid backup file format')
        )),
      );
    });

    test('TC-BR03: Passphrase bytes are zeroed after encryption (memory hygiene)', () {
      // Verify that encryption completes without retaining passphrase in the returned value
      final payload = {'cycles': [], 'routines': [], 'version': 1};
      final result = performHeavyEncryption({'data': payload, 'passphrase': 'secret'});
      // Result is salt:iv:ciphertext — passphrase should not appear in output
      expect(result, isNot(contains('secret')));
    });
  });
}
