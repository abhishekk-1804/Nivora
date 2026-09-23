import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/utils/date_utils.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Critical Data-Integrity Deep Validation (Phase C)', () {
    late AppDatabase memDb;

    setUp(() {
      memDb = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await memDb.close();
    });

    // TEST 1: Log period data first, then log mood/energy/symptoms.
    test('TEST 1: Log period data then symptoms -> original period data remains intact', () async {
      final date = DateTime(2026, 3, 15, 8, 30);

      // Log full period entry
      await memDb.cycleDao.logCycleEvent(
        date: date,
        flowType: 'Heavy',
        painIntensity: 8,
        clotSize: 'Large',
        isFlooding: true,
        bloodColor: 'Dark Crimson',
        painReliefTaken: true,
        isTrueCycleStart: true,
        symptoms: 'Pelvic Cramping',
        notes: 'Morning heavy flow with severe pain',
      );

      // Log first symptom: Mood
      await memDb.cycleDao.logSymptom(
        date: date,
        symptom: 'Mood: Low',
        notes: 'Midday mood slump',
      );

      // Log second symptom: Energy
      await memDb.cycleDao.logSymptom(
        date: date,
        symptom: 'Energy: Exhausted',
      );

      // Log third symptom: Bloating
      await memDb.cycleDao.logSymptom(
        date: date,
        symptom: 'Bloating',
      );

      final record = await memDb.cycleDao.getEventForDate(date);
      expect(record, isNotNull);
      expect(record!.flowType, equals('Heavy'), reason: 'FlowType must not be clobbered by symptom log');
      expect(record.painIntensity, equals(8), reason: 'Pain intensity must be preserved');
      expect(record.clotSize, equals('Large'), reason: 'Clot size must be preserved');
      expect(record.isFlooding, isTrue, reason: 'Flooding flag must be preserved');
      expect(record.bloodColor, equals('Dark Crimson'), reason: 'Blood color must be preserved');
      expect(record.painReliefTaken, isTrue, reason: 'Pain relief flag must be preserved');
      expect(record.isTrueCycleStart, isTrue, reason: 'Cycle start flag must be preserved');
      expect(record.symptoms, contains('Pelvic Cramping'));
      expect(record.symptoms, contains('Mood: Low'));
      expect(record.symptoms, contains('Energy: Exhausted'));
      expect(record.symptoms, contains('Bloating'));
      expect(record.notes, contains('Morning heavy flow'));
      expect(record.notes, contains('Midday mood slump'));
    });

    // TEST 2: Log symptom first, then period data later in the day.
    test('TEST 2: Log symptom first then period data -> both survive with symptoms merged', () async {
      final date = DateTime(2026, 4, 10, 7, 0);

      // Morning: Log symptoms before bleeding starts
      await memDb.cycleDao.logSymptom(
        date: date,
        symptom: 'Headache, Fatigue',
        notes: 'Pre-period malaise',
      );

      // Evening: Menstrual bleeding starts, user logs full period event
      await memDb.cycleDao.logCycleEvent(
        date: date,
        flowType: 'Medium',
        painIntensity: 6,
        clotSize: 'Small',
        isFlooding: false,
        isTrueCycleStart: true,
        symptoms: 'Nausea',
        notes: 'Bleeding started at 6pm',
      );

      final record = await memDb.cycleDao.getEventForDate(date);
      expect(record, isNotNull);
      expect(record!.flowType, equals('Medium'));
      expect(record.painIntensity, equals(6));
      expect(record.clotSize, equals('Small'));
      expect(record.isFlooding, isFalse);
      expect(record.isTrueCycleStart, isTrue);
      expect(record.symptoms, contains('Headache'));
      expect(record.symptoms, contains('Fatigue'));
      expect(record.symptoms, contains('Nausea'));
      expect(record.notes, contains('Pre-period malaise'));
      expect(record.notes, contains('Bleeding started at 6pm'));
    });

    // TEST 3: Log multiple symptoms on the same day -> no data loss or duplicate bloat.
    test('TEST 3: Log multiple symptoms on same day -> deduplicated set without loss', () async {
      final date = DateTime(2026, 4, 15);

      await memDb.cycleDao.logSymptom(date: date, symptom: 'Anxiety');
      await memDb.cycleDao.logSymptom(date: date, symptom: 'Brain Fog');
      await memDb.cycleDao.logSymptom(date: date, symptom: 'Anxiety'); // Duplicate
      await memDb.cycleDao.logSymptom(date: date, symptom: 'Insomnia, Backache');

      final record = await memDb.cycleDao.getEventForDate(date);
      expect(record, isNotNull);
      expect(record!.symptoms, contains('Anxiety'));
      expect(record.symptoms, contains('Brain Fog'));
      expect(record.symptoms, contains('Insomnia'));
      expect(record.symptoms, contains('Backache'));

      // Ensure duplicate 'Anxiety' was deduplicated
      final occurrences = RegExp(r'\bAnxiety\b').allMatches(record.symptoms ?? '').length;
      expect(occurrences, equals(1), reason: 'Symptoms should be cleanly deduplicated');
    });

    // TEST 4: Update only one menstrual attribute -> unrelated attributes remain unchanged.
    test('TEST 4: Update only flowType -> pain, clots, flooding, and symptoms remain unchanged', () async {
      final date = DateTime(2026, 5, 2);

      // Initial comprehensive log
      await memDb.cycleDao.logCycleEvent(
        date: date,
        flowType: 'Heavy',
        painIntensity: 9,
        clotSize: 'Large',
        isFlooding: true,
        bloodColor: 'Bright Red',
        symptoms: 'Migraine',
        notes: 'Severe morning onset',
      );

      // Later update: User updates flow to Medium without specifying pain or clots
      await memDb.cycleDao.logCycleEvent(
        date: date,
        flowType: 'Medium',
      );

      final record = await memDb.cycleDao.getEventForDate(date);
      expect(record, isNotNull);
      expect(record!.flowType, equals('Medium'), reason: 'FlowType was updated');
      expect(record.painIntensity, equals(9), reason: 'Pain intensity must remain 9');
      expect(record.clotSize, equals('Large'), reason: 'Clot size must remain Large');
      expect(record.isFlooding, isTrue, reason: 'Flooding must remain true');
      expect(record.bloodColor, equals('Bright Red'), reason: 'Blood color must remain Bright Red');
      expect(record.symptoms, contains('Migraine'), reason: 'Symptoms must be preserved');
      expect(record.notes, contains('Severe morning onset'), reason: 'Notes must be preserved');
    });

    // TEST 5: Close and reopen database -> verify physical disk persistence.
    test('TEST 5: Close and reopen database -> data physically persists across instances', () async {
      final tempDir = Directory.systemTemp.createTempSync('nivora_persistence_test_');
      final dbFile = File('${tempDir.path}${Platform.pathSeparator}test_persistence.sqlite');

      try {
        // 1. Open first database instance on disk
        final dbInstance1 = AppDatabase.forTesting(NativeDatabase(dbFile));
        final logDate = DateTime(2026, 6, 1);

        await dbInstance1.cycleDao.logCycleEvent(
          date: logDate,
          flowType: 'Heavy',
          painIntensity: 7,
          clotSize: 'Medium',
          isFlooding: true,
          symptoms: 'Back Pain, Nausea',
          notes: 'Disk persistence verification',
        );

        // Explicitly close first instance
        await dbInstance1.close();

        // 2. Open a completely new database instance pointing to the same physical file
        final dbInstance2 = AppDatabase.forTesting(NativeDatabase(dbFile));

        final record = await dbInstance2.cycleDao.getEventForDate(logDate);
        expect(record, isNotNull);
        expect(record!.flowType, equals('Heavy'));
        expect(record.painIntensity, equals(7));
        expect(record.clotSize, equals('Medium'));
        expect(record.isFlooding, isTrue);
        expect(record.symptoms, contains('Back Pain'));
        expect(record.symptoms, contains('Nausea'));
        expect(record.notes, equals('Disk persistence verification'));

        await dbInstance2.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    // TEST 6: Create records on adjacent dates -> verify no date collision or cross-bleeding.
    test('TEST 6: Create records on adjacent dates -> distinct records with zero collision', () async {
      final day1 = DateTime(2026, 7, 1);
      final day2 = DateTime(2026, 7, 2);
      final day3 = DateTime(2026, 7, 3);

      await memDb.cycleDao.logCycleEvent(
        date: day1,
        flowType: 'Spotting',
        painIntensity: 1,
        isTrueCycleStart: false,
        symptoms: 'Mild Spotting',
      );

      await memDb.cycleDao.logCycleEvent(
        date: day2,
        flowType: 'Heavy',
        painIntensity: 7,
        isTrueCycleStart: true,
        symptoms: 'Full Flow Start',
      );

      await memDb.cycleDao.logCycleEvent(
        date: day3,
        flowType: 'Medium',
        painIntensity: 4,
        isTrueCycleStart: false,
        symptoms: 'Normal Period',
      );

      final record1 = await memDb.cycleDao.getEventForDate(day1);
      final record2 = await memDb.cycleDao.getEventForDate(day2);
      final record3 = await memDb.cycleDao.getEventForDate(day3);

      expect(record1, isNotNull);
      expect(record1!.flowType, equals('Spotting'));
      expect(record1.isTrueCycleStart, isFalse);

      expect(record2, isNotNull);
      expect(record2!.flowType, equals('Heavy'));
      expect(record2.isTrueCycleStart, isTrue);

      expect(record3, isNotNull);
      expect(record3!.flowType, equals('Medium'));
      expect(record3.isTrueCycleStart, isFalse);

      final allEvents = await memDb.cycleDao.getAllEvents();
      expect(allEvents.length, equals(3));
    });

    // TEST 7: Check timezone and date boundary behavior.
    test('TEST 7: Timezone, local midnight, 23:59:59, and date truncation boundary behavior', () async {
      // Different times on the exact same calendar day
      final morningLocal = DateTime(2026, 8, 10, 0, 0, 1);   // Just past midnight
      final middayLocal  = DateTime(2026, 8, 10, 12, 30, 0);  // Noon
      final nightLocal   = DateTime(2026, 8, 10, 23, 59, 59); // One second before midnight

      // Morning log: starts the record
      await memDb.cycleDao.logCycleEvent(
        date: morningLocal,
        flowType: 'Light',
        painIntensity: 2,
        symptoms: 'Morning Cramp',
      );

      // Midday log: symptom addition
      await memDb.cycleDao.logSymptom(
        date: middayLocal,
        symptom: 'Midday Fatigue',
      );

      // Night log: period intensifies to Heavy
      await memDb.cycleDao.logCycleEvent(
        date: nightLocal,
        flowType: 'Heavy',
        painIntensity: 6,
        isFlooding: true,
      );

      // Querying with ANY of the local times or normalized UTC must return the single merged record
      final qMorning = await memDb.cycleDao.getEventForDate(morningLocal);
      final qMidday  = await memDb.cycleDao.getEventForDate(middayLocal);
      final qNight   = await memDb.cycleDao.getEventForDate(nightLocal);
      final qUtc     = await memDb.cycleDao.getEventForDate(DateTime.utc(2026, 8, 10));

      expect(qMorning, isNotNull);
      expect(qMidday, isNotNull);
      expect(qNight, isNotNull);
      expect(qUtc, isNotNull);

      // All queries must resolve to the EXACT SAME event ID
      expect(qMorning!.id, equals(qMidday!.id));
      expect(qMidday.id, equals(qNight!.id));
      expect(qNight.id, equals(qUtc!.id));

      // Verify the final merged attributes
      expect(qUtc.flowType, equals('Heavy'));
      expect(qUtc.painIntensity, equals(6));
      expect(qUtc.isFlooding, isTrue);
      expect(qUtc.symptoms, contains('Morning Cramp'));
      expect(qUtc.symptoms, contains('Midday Fatigue'));

      // Next calendar day at 00:00:00 must NOT match August 10
      final nextDay = DateTime(2026, 8, 11, 0, 0, 0);
      final qNext = await memDb.cycleDao.getEventForDate(nextDay);
      expect(qNext, isNull, reason: 'Next day at midnight must not collide with previous day');

      // Daylight Saving Time sanity check: Days between test
      final springDstStart = DateTime(2026, 3, 8);
      final springDstEnd   = DateTime(2026, 3, 9);
      expect(AppDateUtils.daysBetween(springDstStart, springDstEnd), equals(1));
    });
  });
}
