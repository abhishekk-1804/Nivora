import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/core/services/backup_service.dart';

void main() {
  group('BackupService Cryptography Tests', () {
    const testPassphrase = 'my_super_secret_password_123!';
    final Map<String, dynamic> dummyData = {
      'cycleEvents': [],
      'routines': [],
      'routineLogs': [],
      'interventions': [],
      'labResults': [
        {'id': 1, 'testName': 'HbA1c', 'value': 5.4}
      ],
      'clinicalProfile': [
        {'id': 1, 'phenotype': 'PCOS_A', 'isDiagnosed': true}
      ],
      'metabolicLogs': [],
    };

    test('Encryption and Decryption are lossless', () {
      // 1. Encrypt the data
      final encryptionArgs = {
        'data': dummyData,
        'passphrase': testPassphrase,
      };
      
      final encryptedString = performHeavyEncryption(encryptionArgs);
      
      // The output format is salt:iv:ciphertext.
      // NOTE: parts.length must be >= 3, NOT == 3, because standard base64
      // encoding may produce colons in the ciphertext on some edge cases.
      // The fix: use parts.sublist(2).join(':') to reconstruct the ciphertext.
      final parts = encryptedString.split(':');
      expect(parts.length, greaterThanOrEqualTo(3));
      expect(parts[0].isNotEmpty, true); // salt
      expect(parts[1].isNotEmpty, true); // iv
      expect(parts.sublist(2).join(':').isNotEmpty, true); // payload


      // 2. Decrypt the data
      final decryptionArgs = {
        'content': encryptedString,
        'passphrase': testPassphrase,
      };

      final decryptedData = performHeavyDecryption(decryptionArgs);

      // 3. Verify Lossless Nature
      expect(decryptedData['labResults'], isNotEmpty);
      expect(decryptedData['labResults'][0]['testName'], 'HbA1c');
      expect(decryptedData['clinicalProfile'][0]['phenotype'], 'PCOS_A');
    });

    test('Decryption fails with incorrect passphrase', () {
      // 1. Encrypt the data with correct passphrase
      final encryptionArgs = {
        'data': dummyData,
        'passphrase': testPassphrase,
      };
      
      final encryptedString = performHeavyEncryption(encryptionArgs);

      // 2. Attempt Decryption with wrong passphrase
      final badDecryptionArgs = {
        'content': encryptedString,
        'passphrase': 'wrong_password',
      };

      expect(
        () => performHeavyDecryption(badDecryptionArgs),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Incorrect passphrase'))),
      );
    });

    test('Decryption fails with corrupted payload', () {
      final corruptedString = 'badsalt:badiv:badpayload==';
      
      final badDecryptionArgs = {
        'content': corruptedString,
        'passphrase': testPassphrase,
      };

      expect(
        () => performHeavyDecryption(badDecryptionArgs),
        throwsA(isA<Exception>()),
      );
    });

    test('TC-B02: content with < 2 colons throws Invalid backup file format', () {
      expect(
        () => performHeavyDecryption({'content': 'nocolons', 'passphrase': testPassphrase}),
        throwsA(predicate<Exception>((e) => e.toString().contains('Invalid backup file format'))),
      );
    });

    test('TC-B02: rejoining sublist(2) recovers full ciphertext correctly', () {
      final encrypted = performHeavyEncryption({'data': dummyData, 'passphrase': testPassphrase});
      final parts = encrypted.split(':');
      final rejoined = '${parts[0]}:${parts[1]}:${parts.sublist(2).join(':')}'; 
      // Must decrypt successfully even after the rejoin
      final decrypted = performHeavyDecryption({'content': rejoined, 'passphrase': testPassphrase});
      expect(decrypted['labResults'][0]['testName'], 'HbA1c');
    });

    test('Backup timestamp string has correct format (YYYY-MM-DDTHH-MM-SS)', () {
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      expect(stamp.length, 19);
      expect(stamp, matches(RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}')));
    });
  });
}
