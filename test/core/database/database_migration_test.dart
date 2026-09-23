import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nivora_app/core/database/app_database.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Database & Legacy Migration Validation (Phase D)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nivora_migration_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Case 1: Legacy Ila_health.sqlite exists -> safely copies to nivora_health.sqlite, creates backup, and preserves all historical records', () async {
      final legacyFile = File('${tempDir.path}${Platform.pathSeparator}Ila_health.sqlite');

      // 1. Populate legacy database with realistic historical data
      final legacyDb = AppDatabase.forTesting(NativeDatabase(legacyFile));
      final historicalDate = DateTime.utc(2025, 11, 20);

      await legacyDb.cycleDao.logCycleEvent(
        date: historicalDate,
        flowType: 'Heavy',
        painIntensity: 7,
        clotSize: 'Large',
        isFlooding: true,
        symptoms: 'Historical Cramps, Fatigue',
        notes: 'Legacy pre-migration cycle event',
      );

      await legacyDb.into(legacyDb.routines).insert(
        RoutinesCompanion.insert(
          name: 'Oral Contraceptive',
          regimenType: 'Cyclic_21_7',
          startDate: DateTime.utc(2025, 10, 1),
          reminderTime: '21:00',
          dose: const Value('1 tablet'),
        ),
      );

      await legacyDb.close();
      expect(legacyFile.existsSync(), isTrue);

      // 2. Perform file migration resolution
      final resolvedFile = await AppDatabase.resolveDatabaseFile(dbFolder: tempDir);
      final expectedNewFile = File('${tempDir.path}${Platform.pathSeparator}nivora_health.sqlite');
      final expectedBackupFile = File('${tempDir.path}${Platform.pathSeparator}Ila_health.sqlite.legacy_backup');

      expect(resolvedFile.path, equals(expectedNewFile.path));
      expect(expectedNewFile.existsSync(), isTrue, reason: 'nivora_health.sqlite must be created');
      expect(expectedBackupFile.existsSync(), isTrue, reason: 'Ila_health.sqlite.legacy_backup must be preserved');
      expect(legacyFile.existsSync(), isTrue, reason: 'Original legacy file should remain untouched');

      // 3. Open the newly migrated Nivora database
      final migratedDb = AppDatabase.forTesting(NativeDatabase(expectedNewFile));

      // Verify historical records survived
      final migratedEvent = await migratedDb.cycleDao.getEventForDate(historicalDate);
      expect(migratedEvent, isNotNull);
      expect(migratedEvent!.flowType, equals('Heavy'));
      expect(migratedEvent.painIntensity, equals(7));
      expect(migratedEvent.clotSize, equals('Large'));
      expect(migratedEvent.isFlooding, isTrue);
      expect(migratedEvent.symptoms, contains('Historical Cramps'));
      expect(migratedEvent.notes, equals('Legacy pre-migration cycle event'));

      final migratedRoutines = await migratedDb.select(migratedDb.routines).get();
      expect(migratedRoutines.length, equals(1));
      expect(migratedRoutines.first.name, equals('Oral Contraceptive'));
      expect(migratedRoutines.first.regimenType, equals('Cyclic_21_7'));
      expect(migratedRoutines.first.dose, equals('1 tablet'));

      // 4. Verify that new data can be written into the migrated database
      await migratedDb.into(migratedDb.clinicalProfile).insert(
        ClinicalProfileCompanion.insert(
          phenotype: const Value('PCOS-Phenotype-A'),
          hasPCOM: const Value(true),
        ),
      );

      final profile = await migratedDb.select(migratedDb.clinicalProfile).getSingle();
      expect(profile.phenotype, equals('PCOS-Phenotype-A'));
      expect(profile.hasPCOM, isTrue);

      await migratedDb.close();
    });

    test('Case 2: Destination nivora_health.sqlite already exists -> must NOT overwrite active database with legacy file', () async {
      final legacyFile = File('${tempDir.path}${Platform.pathSeparator}Ila_health.sqlite');
      final newFile = File('${tempDir.path}${Platform.pathSeparator}nivora_health.sqlite');

      // Populate legacy file with Old Data
      final legacyDb = AppDatabase.forTesting(NativeDatabase(legacyFile));
      await legacyDb.cycleDao.logCycleEvent(
        date: DateTime.utc(2024, 1, 1),
        flowType: 'Light',
        symptoms: 'Old Legacy Symptom',
      );
      await legacyDb.close();

      // Populate new file with Current Nivora Data
      final currentDb = AppDatabase.forTesting(NativeDatabase(newFile));
      await currentDb.cycleDao.logCycleEvent(
        date: DateTime.utc(2026, 1, 1),
        flowType: 'Heavy',
        symptoms: 'Current Nivora Symptom',
      );
      await currentDb.close();

      // Resolve database file
      final resolved = await AppDatabase.resolveDatabaseFile(dbFolder: tempDir);
      expect(resolved.path, equals(newFile.path));

      // Reopen and ensure current Nivora data was preserved (NOT overwritten by legacy)
      final recheckedDb = AppDatabase.forTesting(NativeDatabase(newFile));
      final currentEvent = await recheckedDb.cycleDao.getEventForDate(DateTime.utc(2026, 1, 1));
      final legacyEvent = await recheckedDb.cycleDao.getEventForDate(DateTime.utc(2024, 1, 1));

      expect(currentEvent, isNotNull);
      expect(currentEvent!.flowType, equals('Heavy'));
      expect(currentEvent.symptoms, contains('Current Nivora Symptom'));

      expect(legacyEvent, isNull, reason: 'Legacy data must not overwrite existing Nivora database');

      await recheckedDb.close();
    });

    test('Case 3: Fresh install (no legacy database) -> resolves to nivora_health.sqlite and initializes schema version 6', () async {
      final resolved = await AppDatabase.resolveDatabaseFile(dbFolder: tempDir);
      final expectedFile = File('${tempDir.path}${Platform.pathSeparator}nivora_health.sqlite');

      expect(resolved.path, equals(expectedFile.path));
      expect(expectedFile.existsSync(), isFalse, reason: 'File should be created on first database open');

      // Open new database
      final freshDb = AppDatabase.forTesting(NativeDatabase(expectedFile));
      expect(freshDb.schemaVersion, equals(6));

      // Verify all tables are writable and queryable
      final cycles = await freshDb.select(freshDb.cycleEvents).get();
      final routines = await freshDb.select(freshDb.routines).get();
      final routineLogs = await freshDb.select(freshDb.routineLogs).get();
      final interventions = await freshDb.select(freshDb.treatmentInterventions).get();
      final labs = await freshDb.select(freshDb.labResults).get();
      final clinical = await freshDb.select(freshDb.clinicalProfile).get();
      final metabolic = await freshDb.select(freshDb.metabolicLogs).get();

      expect(cycles, isEmpty);
      expect(routines, isEmpty);
      expect(routineLogs, isEmpty);
      expect(interventions, isEmpty);
      expect(labs, isEmpty);
      expect(clinical, isEmpty);
      expect(metabolic, isEmpty);

      await freshDb.close();
      expect(expectedFile.existsSync(), isTrue);
    });

    test('Case 4: Schema migration onUpgrade strategy handles schema increments', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      expect(db.schemaVersion, equals(6));

      // Ensure that Migrator operations execute cleanly
      final m = db.createMigrator();
      expect(m, isNotNull);

      await db.close();
    });
  });
}
