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
    'version': 1,
    'timestamp': DateTime.now().toIso8601String(),
    'data': dataMaps,
  };

  // Heavy operation 1: JSON Encoding
  final jsonString = jsonEncode(payload);

  // Heavy operation 2: Cryptographic Key Derivation (PBKDF2)
  // Generates a mathematically secure 32-byte key from the passphrase
  // using 100,000 iterations of SHA-256 to prevent brute-force attacks.
  //
  // S-01 mitigation: Convert passphrase to a mutable byte array, derive the key,
  // then zero the byte array immediately after. Dart String is immutable/GC-managed
  // so the String object itself cannot be zeroed, but zeroing the byte representation
  // reduces the window during which raw passphrase bytes are live on the heap.
  final salt = enc.IV.fromSecureRandom(16);
  final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
  
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(pc.Pbkdf2Parameters(salt.bytes, 100000, 32));
    
  final derivedKeyBytes = derivator.process(passphraseBytes);
  // Zero the passphrase bytes immediately after key derivation.
  passphraseBytes.fillRange(0, passphraseBytes.length, 0);
  
  final key = enc.Key(derivedKeyBytes);
  final iv = enc.IV.fromSecureRandom(16);

  // Heavy operation 3: AES-256 Encryption
  final encrypter = enc.Encrypter(enc.AES(key));
  final encrypted = encrypter.encrypt(jsonString, iv: iv);

  // Prepend salt and IV so we can decrypt later
  return '${salt.base64}:${iv.base64}:${encrypted.base64}';
}

@visibleForTesting
/// Runs in a background Isolate
Map<String, dynamic> performHeavyDecryption(Map<String, dynamic> args) {
  final content = args['content'] as String;
  final passphrase = args['passphrase'] as String;

  final parts = content.split(':');
  if (parts.length < 3) {
    throw Exception('Invalid backup file format.');
  }
  // The first two ':' delimit salt and IV; the remainder is the encrypted base64.
  // base64-standard characters do NOT include ':', so this is safe to join.
  final saltBase64 = parts[0];
  final ivBase64 = parts[1];
  final encryptedBase64 = parts.sublist(2).join(':');

  final saltBytes = base64Decode(saltBase64);
  
  final derivator = pc.KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(pc.Pbkdf2Parameters(saltBytes, 100000, 32));
    
  final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
  final derivedKeyBytes = derivator.process(passphraseBytes);
  // Zero the passphrase bytes immediately after key derivation.
  passphraseBytes.fillRange(0, passphraseBytes.length, 0);
  final key = enc.Key(derivedKeyBytes);
  final iv = enc.IV.fromBase64(ivBase64);

  final encrypter = enc.Encrypter(enc.AES(key));
  
  String decryptedString;
  try {
    decryptedString = encrypter.decrypt64(encryptedBase64, iv: iv);
  } catch (e) {
    throw Exception('Incorrect passphrase or corrupted backup file.');
  }

  final payload = jsonDecode(decryptedString) as Map<String, dynamic>;
  
  if (!payload.containsKey('version') || payload['version'] != 1) {
    throw const FormatException('Unsupported backup version or corrupted file.');
  }
  
  if (!payload.containsKey('data')) {
    throw const FormatException('Backup file is missing required data.');
  }
  
  final data = payload['data'] as Map<String, dynamic>;
  
  // Validate expected arrays exist
  final expectedKeys = ['cycleEvents', 'routines', 'routineLogs', 'interventions', 'labResults', 'clinicalProfile', 'metabolicLogs'];
  for (final key in expectedKeys) {
    if (!data.containsKey(key) || data[key] is! List) {
      throw const FormatException('Backup file has invalid or missing table data.');
    }
  }

  return data;
}
