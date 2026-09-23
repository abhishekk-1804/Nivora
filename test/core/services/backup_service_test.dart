import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nivora_app/core/services/backup_service.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

void main() {
  group('BackupService Cryptography Tests (Phase 2 Hardening)', () {
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

    // Helper to generate a genuine legacy V1 backup string (salt:iv:ciphertext)
    String generateLegacyV1Backup(Map<String, dynamic> data, String passphrase) {
      final payload = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      final jsonString = jsonEncode(payload);
      final salt = enc.IV.fromSecureRandom(16);
      final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
      final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
        ..init(pc.Pbkdf2Parameters(salt.bytes, 100000, 32));
      final derivedKeyBytes = derivator.process(passphraseBytes);
      final key = enc.Key(derivedKeyBytes);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      return '${salt.base64}:${iv.base64}:${encrypted.base64}';
    }

    test('V2 Authenticated Encryption and Decryption are lossless and properly versioned', () {
      final encryptionArgs = {
        'data': dummyData,
        'passphrase': testPassphrase,
      };

      final encryptedString = performHeavyEncryption(encryptionArgs);

      // Verify V2 envelope structure: NIVORA-BACKUP-V2:salt:nonce:ciphertext_with_tag
      expect(encryptedString.startsWith('NIVORA-BACKUP-V2:'), isTrue);
      final parts = encryptedString.split(':');
      expect(parts.length, greaterThanOrEqualTo(4));
      expect(parts[0], equals('NIVORA-BACKUP-V2'));

      final salt = base64Decode(parts[1]);
      final nonce = base64Decode(parts[2]);
      final ciphertextWithTag = base64Decode(parts.sublist(3).join(':'));

      expect(salt.length, equals(16)); // 128-bit salt
      expect(nonce.length, equals(12)); // 96-bit GCM nonce
      expect(ciphertextWithTag.length, greaterThan(16)); // ciphertext + 128-bit tag

      // Decrypt
      final decryptedData = performHeavyDecryption({
        'content': encryptedString,
        'passphrase': testPassphrase,
      });

      expect(decryptedData['labResults'], isNotEmpty);
      expect(decryptedData['labResults'][0]['testName'], equals('HbA1c'));
      expect(decryptedData['clinicalProfile'][0]['phenotype'], equals('PCOS_A'));
    });

    test('Decryption fails with incorrect passphrase', () {
      final encryptedString = performHeavyEncryption({
        'data': dummyData,
        'passphrase': testPassphrase,
      });

      expect(
        () => performHeavyDecryption({
          'content': encryptedString,
          'passphrase': 'wrong_password',
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Incorrect passphrase or corrupted backup file'),
        )),
      );
    });

    test('Cryptographic Tamper Detection: Single-byte ciphertext modification fails authentication', () {
      final encryptedString = performHeavyEncryption({
        'data': dummyData,
        'passphrase': testPassphrase,
      });

      final parts = encryptedString.split(':');
      final rawCt = base64Decode(parts.sublist(3).join(':'));
      rawCt[0] ^= 0x01; // flip 1 bit in ciphertext

      final tampered = '${parts[0]}:${parts[1]}:${parts[2]}:${base64Encode(rawCt)}';

      expect(
        () => performHeavyDecryption({
          'content': tampered,
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('authentication tag mismatch'),
        )),
      );
    });

    test('Cryptographic Tamper Detection: Nonce modification fails authentication', () {
      final encryptedString = performHeavyEncryption({
        'data': dummyData,
        'passphrase': testPassphrase,
      });

      final parts = encryptedString.split(':');
      final rawNonce = base64Decode(parts[2]);
      rawNonce[0] ^= 0x01; // flip 1 bit in nonce

      final tampered = '${parts[0]}:${parts[1]}:${base64Encode(rawNonce)}:${parts.sublist(3).join(':')}';

      expect(
        () => performHeavyDecryption({
          'content': tampered,
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('authentication tag mismatch'),
        )),
      );
    });

    test('Cryptographic Tamper Detection: Authentication tag modification fails authentication', () {
      final encryptedString = performHeavyEncryption({
        'data': dummyData,
        'passphrase': testPassphrase,
      });

      final parts = encryptedString.split(':');
      final rawCt = base64Decode(parts.sublist(3).join(':'));
      // The last 16 bytes contain the GCM authentication tag
      rawCt[rawCt.length - 1] ^= 0x01;

      final tampered = '${parts[0]}:${parts[1]}:${parts[2]}:${base64Encode(rawCt)}';

      expect(
        () => performHeavyDecryption({
          'content': tampered,
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('authentication tag mismatch'),
        )),
      );
    });

    test('Cryptographic Tamper Detection: Truncated ciphertext fails safely', () {
      final encryptedString = performHeavyEncryption({
        'data': dummyData,
        'passphrase': testPassphrase,
      });

      final parts = encryptedString.split(':');
      final rawCt = base64Decode(parts.sublist(3).join(':'));
      // Truncate by 10 bytes
      final truncatedCt = rawCt.sublist(0, rawCt.length - 10);
      final tampered = '${parts[0]}:${parts[1]}:${parts[2]}:${base64Encode(truncatedCt)}';

      expect(
        () => performHeavyDecryption({
          'content': tampered,
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('authentication tag mismatch'),
        )),
      );
    });

    test('Envelope Validation: Malformed header and empty payload fail safely', () {
      expect(
        () => performHeavyDecryption({
          'content': 'NIVORA-BACKUP-V2:invalid',
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => performHeavyDecryption({
          'content': 'random_invalid_string',
          'passphrase': testPassphrase,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('Random Cryptographic Material: Successive backups produce distinct salts and nonces', () {
      final enc1 = performHeavyEncryption({'data': dummyData, 'passphrase': testPassphrase});
      final enc2 = performHeavyEncryption({'data': dummyData, 'passphrase': testPassphrase});

      final parts1 = enc1.split(':');
      final parts2 = enc2.split(':');

      // Salts must differ
      expect(parts1[1], isNot(equals(parts2[1])));
      // Nonces must differ
      expect(parts1[2], isNot(equals(parts2[2])));
      // Ciphertexts must differ
      expect(parts1[3], isNot(equals(parts2[3])));
    });

    test('Backward Compatibility: Legacy V1 unauthenticated backups remain fully importable', () {
      final legacyV1Payload = generateLegacyV1Backup(dummyData, testPassphrase);

      // Verify V1 has no V2 prefix
      expect(legacyV1Payload.startsWith('NIVORA-BACKUP-V2:'), isFalse);

      final decrypted = performHeavyDecryption({
        'content': legacyV1Payload,
        'passphrase': testPassphrase,
      });

      expect(decrypted['labResults'], isNotEmpty);
      expect(decrypted['labResults'][0]['testName'], equals('HbA1c'));
      expect(decrypted['clinicalProfile'][0]['phenotype'], equals('PCOS_A'));
    });
  });
}
