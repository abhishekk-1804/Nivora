import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:imyra_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Report Aggregation Logic', () {
    test('Cycle Range & Median Calculation', () async {
      // Given cycles of lengths [31, 47, 34, 42, 39]
      final start = DateTime(2023, 1, 1);
      final dates = [
        start, // C1
        start.add(const Duration(days: 31)), // C2 (prev length 31)
        start.add(const Duration(days: 31 + 47)), // C3 (prev length 47)
        start.add(const Duration(days: 31 + 47 + 34)), // C4 (prev length 34)
        start.add(const Duration(days: 31 + 47 + 34 + 42)), // C5 (prev length 42)
        start.add(const Duration(days: 31 + 47 + 34 + 42 + 39)), // C6 (prev length 39)
      ];

      for (var date in dates) {
        await db.cycleDao.logCycleEvent(date: date, flowType: 'Medium');
      }

      final report = await db.reportDao.generateReport(
        startDate: start.subtract(const Duration(days: 10)),
        endDate: dates.last.add(const Duration(days: 10)),
        rangeLabel: 'All',
      );

      // Expected sorted: 31, 34, 39, 42, 47
      // min = 31, max = 47, median = 39
      expect(report.cycleRangeMin, 31);
      expect(report.cycleRangeMax, 47);
      expect(report.medianCycleLength, 39);
      expect(report.totalCycles, 6);
    });

    test('Empty State Fallback', () async {
      final report = await db.reportDao.generateReport(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 12, 31),
        rangeLabel: 'Empty',
      );

      expect(report.totalCycles, 0);
      expect(report.cycleRangeMin, 0);
      expect(report.cycleRangeMax, 0);
      expect(report.medianCycleLength, 0);
      expect(report.adherencePercentage, 0);
      expect(report.cycleRows, isEmpty);
    });

    test('Single Cycle Fallback', () async {
      final date = DateTime(2023, 1, 1);
      await db.cycleDao.logCycleEvent(date: date, flowType: 'Medium');

      final report = await db.reportDao.generateReport(
        startDate: date.subtract(const Duration(days: 10)),
        endDate: date.add(const Duration(days: 10)),
        rangeLabel: 'Single',
      );

      expect(report.totalCycles, 1);
      expect(report.cycleRangeMin, 0); // No interval to calculate
      expect(report.cycleRangeMax, 0);
      expect(report.medianCycleLength, 0);
    });

    test('Adherence Math', () async {
      final start = DateTime(2023, 1, 1);
      final routineId = await db.routineDao.insertRoutine(
        name: 'Test',
        regimenType: 'Daily',
        startDate: start,
        reminderTime: '20:00',
      );

      // 4 doses scheduled: 3 Taken, 1 Missed = 75%
      await db.routineDao.logIntake(routineId: routineId, scheduledDate: start, status: 'Taken');
      await db.routineDao.logIntake(routineId: routineId, scheduledDate: start.add(const Duration(days: 1)), status: 'Taken');
      await db.routineDao.logIntake(routineId: routineId, scheduledDate: start.add(const Duration(days: 2)), status: 'Missed');
      await db.routineDao.logIntake(routineId: routineId, scheduledDate: start.add(const Duration(days: 3)), status: 'Taken');

      final report = await db.reportDao.generateReport(
        startDate: start.subtract(const Duration(days: 1)),
        endDate: start.add(const Duration(days: 4)),
        rangeLabel: 'Adherence',
      );

      expect(report.adherencePercentage, 75);
    });
  });
}
