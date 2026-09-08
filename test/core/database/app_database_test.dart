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

  test('Cycle length median calculation ignores isTrueCycleStart = false (Spotting)', () async {
    // True Cycle 1
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Medium',
          isTrueCycleStart: const drift.Value(true),
        ));
    
    // Spotting event in the middle (should NOT be counted as cycle start)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 15),
          flowType: 'Spotting',
          isTrueCycleStart: const drift.Value(false),
        ));

    // True Cycle 2 (28 days later)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 29),
          flowType: 'Heavy',
          isTrueCycleStart: const drift.Value(true),
        ));

    final report = await db.reportDao.generateReport(
      startDate: DateTime.utc(2023, 1, 1),
      endDate: DateTime.utc(2023, 2, 1),
      rangeLabel: 'Test',
    );

    expect(report.totalCycles, 2);
    expect(report.medianCycleLength, 28); // 15-day gap should be ignored
  });

  test('Treatment Benchmark correctly calculates Pre and Post intervention metrics', () async {
    // Cycle 1 (Pre)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Heavy',
          isTrueCycleStart: const drift.Value(true),
        ));
    // Cycle 2 (Pre)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 31),
          flowType: 'Heavy',
          isTrueCycleStart: const drift.Value(true),
        ));
        
    // Intervention on Feb 15
    await db.into(db.treatmentInterventions).insert(TreatmentInterventionsCompanion.insert(
          title: 'Started Inositol',
          startDate: DateTime.utc(2023, 2, 15),
        ));

    // Cycle 3 (Post)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 3, 2),
          flowType: 'Medium', // Flow improved
          isTrueCycleStart: const drift.Value(true),
        ));
    // Cycle 4 (Post)
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 4, 1),
          flowType: 'Light', // Flow improved
          isTrueCycleStart: const drift.Value(true),
        ));

    final report = await db.reportDao.generateReport(
      startDate: DateTime.utc(2023, 1, 1),
      endDate: DateTime.utc(2023, 4, 15),
      rangeLabel: 'Test',
    );

    expect(report.treatmentBenchmark, isNotNull);
    expect(report.treatmentBenchmark!['title'], 'Started Inositol');
    
    final preString = report.treatmentBenchmark!['pre']!;
    final postString = report.treatmentBenchmark!['post']!;
    
    expect(preString.contains('2 Heavy Days') || preString.contains('Heavy Days'), true);
    expect(postString.contains('0 Heavy Days') || postString.contains('Heavy Days'), true);
  });

  test('Erase All Data transaction explicitly drops all rows', () async {
    // Insert dummy data
    await db.into(db.cycleEvents).insert(CycleEventsCompanion.insert(
          date: DateTime.utc(2023, 1, 1),
          flowType: 'Medium',
        ));
    await db.into(db.routines).insert(RoutinesCompanion.insert(
          name: 'Pill',
          regimenType: 'Daily',
          startDate: DateTime.utc(2023, 1, 1),
          reminderTime: '20:00',
        ));
    
    var cycles = await db.select(db.cycleEvents).get();
    expect(cycles.length, 1);

    // Run transaction
    await db.transaction(() async {
      await db.delete(db.cycleEvents).go();
      await db.delete(db.routineLogs).go();
      await db.delete(db.routines).go();
      await db.delete(db.treatmentInterventions).go();
    });

    cycles = await db.select(db.cycleEvents).get();
    final routines = await db.select(db.routines).get();
    
    expect(cycles.isEmpty, true);
    expect(routines.isEmpty, true);
  });
}
