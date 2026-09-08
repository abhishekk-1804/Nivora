import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:imyra_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Luteal Phase (PMDD Cluster) is correctly identified 4 days before next cycle', () async {
    // Insert Cycle 1
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));
    
    // Insert Cycle 2 (28 days later)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 29),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));

    // Insert Symptom 4 days before Cycle 2 (Luteal Phase)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 25),
          flowType: 'Spotting',
          symptoms: const drift.Value('Severe Anxiety'),
          isTrueCycleStart: const drift.Value(false),
        ));

    final report = await db.reportDao.generateReport(
      startDate: DateTime.utc(2023, 1, 1),
      endDate: DateTime.utc(2023, 1, 31),
      rangeLabel: 'Test',
    );

    expect(report.symptomPhaseClusters.isNotEmpty, true);
    // Should be categorized as Luteal Phase clustering
    expect(report.symptomPhaseClusters.first[2].contains('Luteal'), true);
  });

  test('Menstrual Phase is correctly identified on Day 2 of cycle', () async {
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));

    // Symptom on Day 2
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 2),
          flowType: 'Heavy',
          symptoms: const drift.Value('Pelvic Pain'),
          isTrueCycleStart: const drift.Value(false),
        ));

    final report = await db.reportDao.generateReport(
      startDate: DateTime.utc(2023, 1, 1),
      endDate: DateTime.utc(2023, 1, 10),
      rangeLabel: 'Test',
    );

    expect(report.symptomPhaseClusters.isNotEmpty, true);
    expect(report.symptomPhaseClusters.first[2].contains('Menstrual'), true);
  });

  test('Mid-Cycle / Follicular is correctly identified on Day 14', () async {
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));
        
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 29),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));

    // Symptom on Day 14
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 14),
          flowType: 'Spotting',
          symptoms: const drift.Value('Brain Fog'),
          isTrueCycleStart: const drift.Value(false),
        ));

    final report = await db.reportDao.generateReport(
      startDate: DateTime.utc(2023, 1, 1),
      endDate: DateTime.utc(2023, 1, 31),
      rangeLabel: 'Test',
    );

    expect(report.symptomPhaseClusters.isNotEmpty, true);
    expect(report.symptomPhaseClusters.first[2].contains('Distributed') || report.symptomPhaseClusters.first[2].contains('Mid-Cycle'), true);
  });
}
