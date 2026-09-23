import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/services/backup_service.dart';

base class MockPlatformFile extends PlatformFile {
  @override
  final String name;
  @override
  final String? path;
  final int size;

  MockPlatformFile({
    required this.name,
    this.path,
    this.size = 0,
  });

  @override
  Future<int> length() async => 0;

  @override
  Stream<Uint8List> readAsByteStream() => throw UnimplementedError();

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Uri get uri => Uri.parse(path ?? '');

  @override
  get xFile => throw UnimplementedError();
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Encrypted Backup & Restore Full Round-Trip (Phase E)', () {
    late AppDatabase db;
    late Directory tempDir;
    const testPassphrase = 'Nivora@Secure#2026!LongPassphrase';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      tempDir = Directory.systemTemp.createTempSync('nivora_backup_roundtrip_test_');
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // Helper to populate realistic representative multi-table data
    Future<void> populateRealisticDataset(AppDatabase targetDb) async {
      // 1. CycleEvents
      await targetDb.into(targetDb.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: DateTime.utc(2026, 3, 1),
          flowType: 'Heavy',
          bloodColor: const Value('Dark Red'),
          clotSize: const Value('Large'),
          isFlooding: const Value(true),
          isTrueCycleStart: const Value(true),
          painIntensity: const Value(8),
          painReliefTaken: const Value(true),
          symptoms: const Value('Severe Pelvic Cramping, Migraine, Fatigue'),
          notes: const Value('Heavy onset with flooding requiring double protection'),
        ),
      );
      await targetDb.into(targetDb.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: DateTime.utc(2026, 3, 15),
          flowType: 'Spotting',
          bloodColor: const Value('Brown'),
          clotSize: const Value('None'),
          isFlooding: const Value(false),
          isTrueCycleStart: const Value(false),
          painIntensity: const Value(2),
          painReliefTaken: const Value(false),
          symptoms: const Value('Mild Ovulation Twinge'),
          notes: const Value('Mid-cycle spotting'),
        ),
      );

      // 2. Routines
      await targetDb.into(targetDb.routines).insert(
        RoutinesCompanion.insert(
          name: 'Myo-Inositol & D-Chiro 40:1',
          regimenType: 'Daily',
          startDate: DateTime.utc(2026, 1, 1),
          reminderTime: '08:00',
          dose: const Value('2000mg powder in water'),
          notes: const Value('Take with morning meal'),
        ),
      );
      await targetDb.into(targetDb.routines).insert(
        RoutinesCompanion.insert(
          name: 'Cyclic Progesterone',
          regimenType: 'Cyclic_21_7',
          startDate: DateTime.utc(2026, 2, 1),
          reminderTime: '22:00',
          dose: const Value('200mg micronized capsule'),
          notes: const Value('Days 14-28 of protocol'),
        ),
      );

      // 3. RoutineLogs
      await targetDb.into(targetDb.routineLogs).insert(
        RoutineLogsCompanion.insert(
          routineId: 1,
          scheduledDate: DateTime.utc(2026, 3, 1),
          status: 'Taken',
        ),
      );
      await targetDb.into(targetDb.routineLogs).insert(
        RoutineLogsCompanion.insert(
          routineId: 1,
          scheduledDate: DateTime.utc(2026, 3, 2),
          status: 'Missed',
        ),
      );

      // 4. TreatmentInterventions
      await targetDb.into(targetDb.treatmentInterventions).insert(
        TreatmentInterventionsCompanion.insert(
          title: 'Started Metformin ER 500mg',
          startDate: DateTime.utc(2026, 1, 15),
        ),
      );
      await targetDb.into(targetDb.treatmentInterventions).insert(
        TreatmentInterventionsCompanion.insert(
          title: 'Adopted Anti-Inflammatory Nutrition Plan',
          startDate: DateTime.utc(2026, 2, 1),
        ),
      );

      // 5. LabResults
      await targetDb.into(targetDb.labResults).insert(
        LabResultsCompanion.insert(
          testName: 'Fasting Insulin',
          value: '13.8 uIU/mL',
          date: DateTime.utc(2026, 1, 20),
          notes: const Value('12-hour overnight fasting draw'),
        ),
      );
      await targetDb.into(targetDb.labResults).insert(
        LabResultsCompanion.insert(
          testName: 'HbA1c',
          value: '5.4 %',
          date: DateTime.utc(2026, 1, 20),
        ),
      );

      // 6. ClinicalProfile
      await targetDb.into(targetDb.clinicalProfile).insert(
        ClinicalProfileCompanion.insert(
          phenotype: const Value('A'),
          hasPCOM: const Value(true),
        ),
      );

      // 7. MetabolicLogs
      await targetDb.into(targetDb.metabolicLogs).insert(
        MetabolicLogsCompanion.insert(
          date: DateTime.utc(2026, 3, 1),
          weight: const Value(65.4),
          waistCircumference: const Value(78.5),
          hipCircumference: const Value(99.0),
          signs: const Value('Acanthosis Nigricans, Sugar Cravings'),
        ),
      );
    }

    test('Full End-to-End Round-Trip: Create -> Export -> Erase -> Verify Empty -> Restore -> Field-by-Field Verification', () async {
      // 1. Populate multi-table dataset
      await populateRealisticDataset(db);

      // Verify dataset is populated
      expect((await db.select(db.cycleEvents).get()).length, equals(2));
      expect((await db.select(db.routines).get()).length, equals(2));
      expect((await db.select(db.routineLogs).get()).length, equals(2));
      expect((await db.select(db.treatmentInterventions).get()).length, equals(2));
      expect((await db.select(db.labResults).get()).length, equals(2));
      expect((await db.select(db.clinicalProfile).get()).length, equals(1));
      expect((await db.select(db.metabolicLogs).get()).length, equals(1));

      // 2. Export encrypted backup
      final encryptedPayload = await BackupService.generateEncryptedPayload(db, testPassphrase);
      expect(encryptedPayload, isNotEmpty);

      // Assert cryptographic structure: salt:iv:ciphertext
      final parts = encryptedPayload.split(':');
      expect(parts.length, greaterThanOrEqualTo(3));
      expect(parts[0], isNotEmpty, reason: 'PBKDF2 Salt must exist');
      expect(parts[1], isNotEmpty, reason: 'AES IV must exist');
      expect(parts[2], isNotEmpty, reason: 'Ciphertext must exist');

      // Assert no plaintext leakage
      expect(encryptedPayload, isNot(contains('Metformin')));
      expect(encryptedPayload, isNot(contains('Myo-Inositol')));
      expect(encryptedPayload, isNot(contains('Pelvic Cramping')));
      expect(encryptedPayload, isNot(contains('testPassphrase')));

      // 3. Write backup to temporary file (.nivorabackup)
      final backupFile = File('${tempDir.path}${Platform.pathSeparator}test_roundtrip.nivorabackup');
      await backupFile.writeAsString(encryptedPayload);
      expect(backupFile.existsSync(), isTrue);

      // 4. Erase All Data on Database
      await db.transaction(() async {
        await db.delete(db.cycleEvents).go();
        await db.delete(db.routines).go();
        await db.delete(db.routineLogs).go();
        await db.delete(db.treatmentInterventions).go();
        await db.delete(db.labResults).go();
        await db.delete(db.clinicalProfile).go();
        await db.delete(db.metabolicLogs).go();
      });

      // 5. Verify database is completely empty
      expect(await db.select(db.cycleEvents).get(), isEmpty);
      expect(await db.select(db.routines).get(), isEmpty);
      expect(await db.select(db.routineLogs).get(), isEmpty);
      expect(await db.select(db.treatmentInterventions).get(), isEmpty);
      expect(await db.select(db.labResults).get(), isEmpty);
      expect(await db.select(db.clinicalProfile).get(), isEmpty);
      expect(await db.select(db.metabolicLogs).get(), isEmpty);

      // 6. Restore from encrypted backup
      final platformFile = MockPlatformFile(
        name: 'test_roundtrip.nivorabackup',
        path: backupFile.path,
        size: backupFile.lengthSync(),
      );

      await BackupService.restoreEncryptedBackup(db, platformFile, testPassphrase);

      // 7. Field-by-Field Verification of Restored Records
      final restoredCycles = await db.select(db.cycleEvents).get();
      expect(restoredCycles.length, equals(2));
      final heavyEvent = restoredCycles.firstWhere((e) => e.flowType == 'Heavy');
      expect(heavyEvent.bloodColor, equals('Dark Red'));
      expect(heavyEvent.clotSize, equals('Large'));
      expect(heavyEvent.isFlooding, isTrue);
      expect(heavyEvent.isTrueCycleStart, isTrue);
      expect(heavyEvent.painIntensity, equals(8));
      expect(heavyEvent.painReliefTaken, isTrue);
      expect(heavyEvent.symptoms, contains('Severe Pelvic Cramping'));
      expect(heavyEvent.notes, contains('Heavy onset with flooding'));

      final spottingEvent = restoredCycles.firstWhere((e) => e.flowType == 'Spotting');
      expect(spottingEvent.bloodColor, equals('Brown'));
      expect(spottingEvent.clotSize, equals('None'));
      expect(spottingEvent.isFlooding, isFalse);
      expect(spottingEvent.isTrueCycleStart, isFalse);
      expect(spottingEvent.painIntensity, equals(2));

      final restoredRoutines = await db.select(db.routines).get();
      expect(restoredRoutines.length, equals(2));
      final inositol = restoredRoutines.firstWhere((r) => r.name.contains('Inositol'));
      expect(inositol.regimenType, equals('Daily'));
      expect(inositol.dose, equals('2000mg powder in water'));
      expect(inositol.reminderTime, equals('08:00'));

      final progesterone = restoredRoutines.firstWhere((r) => r.name.contains('Progesterone'));
      expect(progesterone.regimenType, equals('Cyclic_21_7'));
      expect(progesterone.dose, equals('200mg micronized capsule'));

      final restoredLogs = await db.select(db.routineLogs).get();
      expect(restoredLogs.length, equals(2));
      expect(restoredLogs.any((l) => l.status == 'Taken'), isTrue);
      expect(restoredLogs.any((l) => l.status == 'Missed'), isTrue);

      final restoredInterventions = await db.select(db.treatmentInterventions).get();
      expect(restoredInterventions.length, equals(2));
      expect(restoredInterventions.any((i) => i.title.contains('Metformin')), isTrue);
      expect(restoredInterventions.any((i) => i.title.contains('Anti-Inflammatory')), isTrue);

      final restoredLabs = await db.select(db.labResults).get();
      expect(restoredLabs.length, equals(2));
      final insulin = restoredLabs.firstWhere((l) => l.testName == 'Fasting Insulin');
      expect(insulin.value, equals('13.8 uIU/mL'));
      expect(insulin.notes, equals('12-hour overnight fasting draw'));

      final restoredProfile = await db.select(db.clinicalProfile).getSingle();
      expect(restoredProfile.phenotype, equals('A'));
      expect(restoredProfile.hasPCOM, isTrue);

      final restoredMetabolic = await db.select(db.metabolicLogs).getSingle();
      expect(restoredMetabolic.weight, equals(65.4));
      expect(restoredMetabolic.waistCircumference, equals(78.5));
      expect(restoredMetabolic.hipCircumference, equals(99.0));
      expect(restoredMetabolic.signs, contains('Acanthosis Nigricans'));
    });

    test('Failure Case 1: Wrong Passphrase -> throws error and leaves existing database untouched', () async {
      await populateRealisticDataset(db);
      final initialCycleCount = (await db.select(db.cycleEvents).get()).length;

      final encryptedPayload = await BackupService.generateEncryptedPayload(db, testPassphrase);
      final backupFile = File('${tempDir.path}${Platform.pathSeparator}wrong_pass.nivorabackup');
      await backupFile.writeAsString(encryptedPayload);

      final platformFile = MockPlatformFile(
        name: 'wrong_pass.nivorabackup',
        path: backupFile.path,
        size: backupFile.lengthSync(),
      );

      // Attempt restore with wrong password
      expect(
        () => BackupService.restoreEncryptedBackup(db, platformFile, 'CompletelyWrongPassphrase999'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Incorrect passphrase'))),
      );

      // Verify database data was NOT altered or wiped
      final postAttemptCount = (await db.select(db.cycleEvents).get()).length;
      expect(postAttemptCount, equals(initialCycleCount));
    });

    test('Failure Case 2: Corrupted/Truncated Ciphertext -> throws error without partial data restoration', () async {
      await populateRealisticDataset(db);
      final initialCount = (await db.select(db.cycleEvents).get()).length;

      final encryptedPayload = await BackupService.generateEncryptedPayload(db, testPassphrase);
      // Corrupt the ciphertext by truncating it and replacing end with garbage
      final parts = encryptedPayload.split(':');
      final corruptedCipher = '${parts[2].substring(0, parts[2].length ~/ 2)}===CORRUPTED===';
      final corruptedPayload = '${parts[0]}:${parts[1]}:$corruptedCipher';

      final backupFile = File('${tempDir.path}${Platform.pathSeparator}corrupted.nivorabackup');
      await backupFile.writeAsString(corruptedPayload);

      final platformFile = MockPlatformFile(
        name: 'corrupted.nivorabackup',
        path: backupFile.path,
        size: backupFile.lengthSync(),
      );

      expect(
        () => BackupService.restoreEncryptedBackup(db, platformFile, testPassphrase),
        throwsA(isA<Exception>()),
      );

      // Database records must remain intact
      expect((await db.select(db.cycleEvents).get()).length, equals(initialCount));
    });

    test('Failure Case 3: Empty File -> throws format error without modifying database', () async {
      final emptyFile = File('${tempDir.path}${Platform.pathSeparator}empty.nivorabackup');
      await emptyFile.writeAsString('');

      final platformFile = MockPlatformFile(
        name: 'empty.nivorabackup',
        path: emptyFile.path,
        size: 0,
      );

      expect(
        () => BackupService.restoreEncryptedBackup(db, platformFile, testPassphrase),
        throwsA(isA<Exception>()),
      );
    });

    test('Failure Case 4: Unsupported File Extension -> rejects file immediately', () async {
      final textFile = File('${tempDir.path}${Platform.pathSeparator}export.json');
      await textFile.writeAsString('{"data": {}}');

      final platformFile = MockPlatformFile(
        name: 'export.json',
        path: textFile.path,
        size: textFile.lengthSync(),
      );

      expect(
        () => BackupService.restoreEncryptedBackup(db, platformFile, testPassphrase),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Invalid file type'))),
      );
    });

    test('Compatibility Case: Legacy .imyrabackup extension -> decrypts and restores flawlessly', () async {
      await populateRealisticDataset(db);

      final encryptedPayload = await BackupService.generateEncryptedPayload(db, testPassphrase);

      // Save explicitly as legacy .imyrabackup extension
      final legacyBackupFile = File('${tempDir.path}${Platform.pathSeparator}legacy_user_backup.imyrabackup');
      await legacyBackupFile.writeAsString(encryptedPayload);

      // Wipe current DB
      await db.delete(db.cycleEvents).go();
      expect(await db.select(db.cycleEvents).get(), isEmpty);

      // Restore from .imyrabackup
      final platformFile = MockPlatformFile(
        name: 'legacy_user_backup.imyrabackup',
        path: legacyBackupFile.path,
        size: legacyBackupFile.lengthSync(),
      );

      await BackupService.restoreEncryptedBackup(db, platformFile, testPassphrase);

      // Verify all records restored from legacy backup
      final restoredCycles = await db.select(db.cycleEvents).get();
      expect(restoredCycles.length, equals(2));
      expect(restoredCycles.any((c) => c.flowType == 'Heavy'), isTrue);
      expect(restoredCycles.any((c) => c.flowType == 'Spotting'), isTrue);

      final restoredProfile = await db.select(db.clinicalProfile).getSingle();
      expect(restoredProfile.phenotype, equals('A'));
      expect(restoredProfile.hasPCOM, isTrue);
    });
  });
}
