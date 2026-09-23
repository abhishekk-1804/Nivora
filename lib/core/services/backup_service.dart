import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/preference_keys.dart';
import '../database/app_database.dart';

class BackupService {
  /// Generates the serialized and encrypted backup payload string for all persisted database tables.
  static Future<String> generateEncryptedPayload(AppDatabase db, String passphrase) async {
    // 1. Query all tables (Runs asynchronously via Drift)
    final cycleEvents = await db.select(db.cycleEvents).get();
    final routines = await db.select(db.routines).get();
    final routineLogs = await db.select(db.routineLogs).get();
    final interventions = await db.select(db.treatmentInterventions).get();
    final labResults = await db.select(db.labResults).get();
    final clinicalProfile = await db.select(db.clinicalProfile).get();
    final metabolicLogs = await db.select(db.metabolicLogs).get();

    // Map to simple primitive Maps on the main thread (very fast)
    final dataMaps = {
      'cycleEvents': cycleEvents.map((e) => e.toJson()).toList(),
      'routines': routines.map((e) => e.toJson()).toList(),
      'routineLogs': routineLogs.map((e) => e.toJson()).toList(),
      'interventions': interventions.map((e) => e.toJson()).toList(),
      'labResults': labResults.map((e) => e.toJson()).toList(),
      'clinicalProfile': clinicalProfile.map((e) => e.toJson()).toList(),
      'metabolicLogs': metabolicLogs.map((e) => e.toJson()).toList(),
    };

    // 2. Offload heavy serialization and encryption to a background Isolate
    return compute(performHeavyEncryption, {
      'data': dataMaps,
      'passphrase': passphrase,
    });
  }

  static Future<void> exportEncryptedBackup(AppDatabase db, String passphrase) async {
    final finalPayload = await generateEncryptedPayload(db, passphrase);

    // 3. Write to temporary file with timestamp so repeated exports don't overwrite each other
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-').substring(0, 19);
    final file = File('${tempDir.path}/nivoradata_$stamp.nivorabackup');
    await file.writeAsString(finalPayload);

    // 4. Native Share
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], subject: 'Nivora Encrypted Backup');
  }

  static Future<void> restoreEncryptedBackup(AppDatabase db, PlatformFile file, String passphrase) async {
    final lowerName = file.name.toLowerCase();
    if (!lowerName.endsWith('.nivorabackup') && !lowerName.endsWith('.imyrabackup')) {
      throw const FormatException('Invalid file type. Please select a .nivorabackup or .imyrabackup file.');
    }

    // S-04 fix: file.path can be null on Android when the file is picked from
    // cloud storage (Google Drive, OneDrive). Force-unwrapping would crash.
    if (file.path == null) {
      throw const FormatException(
        'Could not read the selected file. Please save the backup to your local device storage and try again.',
      );
    }

    String fileContents = await File(file.path!).readAsString();


    // 1. Offload heavy decryption and JSON parsing to a background Isolate
    final parsedData = await compute(performHeavyDecryption, {
      'content': fileContents,
      'passphrase': passphrase,
    });

    // If we reach here, decryption succeeded.
    // 2. Atomic database overwrite
    await db.transaction(() async {
      // Clear existing data
      await db.delete(db.cycleEvents).go();
      await db.delete(db.routines).go();
      await db.delete(db.routineLogs).go();
      await db.delete(db.treatmentInterventions).go();
      await db.delete(db.labResults).go();
      await db.delete(db.clinicalProfile).go();
      await db.delete(db.metabolicLogs).go();

      // Insert new data
      final cycleEventsRaw = parsedData['cycleEvents'] as List? ?? [];
      for (final raw in cycleEventsRaw) {
        await db.into(db.cycleEvents).insert(CycleEvent.fromJson(raw as Map<String, dynamic>));
      }

      final routinesRaw = parsedData['routines'] as List? ?? [];
      for (final raw in routinesRaw) {
        await db.into(db.routines).insert(Routine.fromJson(raw as Map<String, dynamic>));
      }

      final routineLogsRaw = parsedData['routineLogs'] as List? ?? [];
      for (final raw in routineLogsRaw) {
        await db.into(db.routineLogs).insert(RoutineLog.fromJson(raw as Map<String, dynamic>));
      }

      final interventionsRaw = parsedData['interventions'] as List? ?? [];
      for (final raw in interventionsRaw) {
        await db.into(db.treatmentInterventions).insert(TreatmentIntervention.fromJson(raw as Map<String, dynamic>));
      }

      final labResultsRaw = parsedData['labResults'] as List? ?? [];
      for (final raw in labResultsRaw) {
        await db.into(db.labResults).insert(LabResult.fromJson(raw as Map<String, dynamic>));
      }

      final clinicalProfileRaw = parsedData['clinicalProfile'] as List? ?? [];
      for (final raw in clinicalProfileRaw) {
        await db.into(db.clinicalProfile).insert(ClinicalProfileData.fromJson(raw as Map<String, dynamic>));
      }

      final metabolicLogsRaw = parsedData['metabolicLogs'] as List? ?? [];
      for (final raw in metabolicLogsRaw) {
        await db.into(db.metabolicLogs).insert(MetabolicLog.fromJson(raw as Map<String, dynamic>));
      }
    });

    // 3. Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.hasOnboarded, true);
  }
}

@visibleForTesting
/// Runs in a background Isolate to prevent UI freezing
String performHeavyEncryption(Map<String, dynamic> args) {
  final dataMaps = args['data'] as Map<String, dynamic>;
  final passphrase = args['passphrase'] as String;

  final payload = {
    'version': 2,
    'timestamp': DateTime.now().toIso8601String(),
    'data': dataMaps,
  };

  // Heavy operation 1: JSON Encoding
  final jsonString = jsonEncode(payload);

  // Heavy operation 2: Cryptographic Key Derivation (PBKDF2)
  // Generates a mathematically secure 32-byte key from the passphrase
  // using 100,000 iterations of SHA-256 to prevent brute-force attacks.
  final salt = enc.IV.fromSecureRandom(16).bytes;
  final nonce = enc.IV.fromSecureRandom(12).bytes; // 96-bit standard nonce for GCM

  final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
  final derivedKeyBytes = derivator.process(passphraseBytes);
  // Zero the passphrase bytes immediately after key derivation.
  passphraseBytes.fillRange(0, passphraseBytes.length, 0);

  // Heavy operation 3: AES-256-GCM Authenticated Encryption
  final cipher = pc.GCMBlockCipher(pc.AESEngine());
  final params = pc.AEADParameters(
    pc.KeyParameter(derivedKeyBytes),
    128, // 128-bit authentication tag
    nonce,
    Uint8List(0), // no AAD
  );
  cipher.init(true, params);
  final plaintextBytes = Uint8List.fromList(utf8.encode(jsonString));
  final ciphertextWithTag = cipher.process(plaintextBytes);

  // Serialize versioned envelope:
  // NIVORA-BACKUP-V2:<salt_base64>:<nonce_base64>:<ciphertext_with_tag_base64>
  return 'NIVORA-BACKUP-V2:${base64Encode(salt)}:${base64Encode(nonce)}:${base64Encode(ciphertextWithTag)}';
}

@visibleForTesting
/// Runs in a background Isolate
Map<String, dynamic> performHeavyDecryption(Map<String, dynamic> args) {
  final content = args['content'] as String;
  final passphrase = args['passphrase'] as String;

  String decryptedString;

  if (content.startsWith('NIVORA-BACKUP-V2:')) {
    final parts = content.split(':');
    if (parts.length < 4) {
      throw const FormatException('Invalid V2 backup envelope format.');
    }
    final salt = base64Decode(parts[1]);
    final nonce = base64Decode(parts[2]);
    final ciphertextWithTag = base64Decode(parts.sublist(3).join(':'));

    if (salt.length != 16 || nonce.length != 12 || ciphertextWithTag.length < 16) {
      throw const FormatException('Invalid V2 backup cryptographic header or truncated payload.');
    }

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
      ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
    final derivedKeyBytes = derivator.process(passphraseBytes);
    passphraseBytes.fillRange(0, passphraseBytes.length, 0);

    final cipher = pc.GCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(
      pc.KeyParameter(derivedKeyBytes),
      128,
      nonce,
      Uint8List(0),
    );
    cipher.init(false, params);
    try {
      final decryptedBytes = cipher.process(ciphertextWithTag);
      decryptedString = utf8.decode(decryptedBytes);
    } catch (e) {
      throw const FormatException('Incorrect passphrase or corrupted backup file (authentication tag mismatch).');
    }
  } else {
    // Legacy V1 backup format backward compatibility (.imyrabackup or v1 .nivorabackup)
    final parts = content.split(':');
    if (parts.length < 3) {
      throw const FormatException('Invalid backup file format.');
    }
    final salt = base64Decode(parts[0]);
    final iv = enc.IV.fromBase64(parts[1]);
    final encryptedBase64 = parts.sublist(2).join(':');

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
      ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
    final derivedKeyBytes = derivator.process(passphraseBytes);
    passphraseBytes.fillRange(0, passphraseBytes.length, 0);

    final key = enc.Key(derivedKeyBytes);
    final encrypter = enc.Encrypter(enc.AES(key));
    try {
      decryptedString = encrypter.decrypt64(encryptedBase64, iv: iv);
    } catch (e) {
      throw const FormatException('Incorrect passphrase or corrupted legacy backup file.');
    }
  }

  final payload = jsonDecode(decryptedString) as Map<String, dynamic>;

  final version = payload['version'] as int?;
  if (version != 1 && version != 2) {
    throw const FormatException('Unsupported backup version or corrupted file.');
  }

  if (!payload.containsKey('data')) {
    throw const FormatException('Backup file is missing required data.');
  }

  final data = payload['data'] as Map<String, dynamic>;

  // Validate expected arrays exist
  final expectedKeys = [
    'cycleEvents',
    'routines',
    'routineLogs',
    'interventions',
    'labResults',
    'clinicalProfile',
    'metabolicLogs',
  ];
  for (final key in expectedKeys) {
    if (!data.containsKey(key) || data[key] is! List) {
      throw const FormatException('Backup file has invalid or missing table data.');
    }
  }

  return data;
}
