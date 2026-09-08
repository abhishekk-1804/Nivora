import 'package:drift/drift.dart';
import '../database/app_database.dart';

class DevDataSeeder {
  static Future<void> seedSixMonths(AppDatabase db) async {
    await db.delete(db.routineLogs).go();
    await db.delete(db.cycleEvents).go();
    await db.delete(db.routines).go();

    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 180));

    // 1. Seed 21/7 Prescription Routine
    final routineId = await db.into(db.routines).insert(
      RoutinesCompanion.insert(
        name: 'Medroxyprogesterone 10mg',
        regimenType: 'Cyclic_21_7',
        activeDays: const Value(21),
        breakDays: const Value(7),
        startDate: sixMonthsAgo,
        reminderTime: '20:00',
        isActive: const Value(true),
      ),
    );

    // 2. Generate 180 Days of 21/7 Adherence Logs
    for (int day = 0; day < 180; day++) {
      final logDate = sixMonthsAgo.add(Duration(days: day));
      final cyclePosition = day % 28;

      if (cyclePosition < 21) {
        final isMissed = (day == 14 || day == 48 || day == 102 || day == 160);
        await db.into(db.routineLogs).insert(
          RoutineLogsCompanion.insert(
            routineId: routineId,
            scheduledDate: logDate,
            completedAt: isMissed ? const Value.absent() : Value(logDate.add(const Duration(hours: 20, minutes: 15))),
            status: isMissed ? 'Missed' : 'Taken',
          ),
        );
      }
    }

    // 3. Seed 5 Irregular Cycles (Gaps: 34d, 42d, 31d, 47d, 39d)
    final cycleStarts = [
      sixMonthsAgo.add(const Duration(days: 3)),
      sixMonthsAgo.add(const Duration(days: 37)),
      sixMonthsAgo.add(const Duration(days: 79)),
      sixMonthsAgo.add(const Duration(days: 110)),
      sixMonthsAgo.add(const Duration(days: 157)),
    ];

    for (int i = 0; i < cycleStarts.length; i++) {
      final start = cycleStarts[i];

      // Day 1: Brown spotting / start
      await db.into(db.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: start,
          flowType: 'Light',
          bloodColor: const Value('DarkBrown'),
          clotSize: const Value('None'),
          symptoms: const Value('Mild Cramps'),
        ),
      );

      // Day 2 & 3: Heavy / Bright Red / Clots / Flooding
      await db.into(db.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: start.add(const Duration(days: 1)),
          flowType: 'Heavy',
          bloodColor: const Value('BrightRed'),
          clotSize: const Value('Large'),
          isFlooding: const Value(true),
          symptoms: const Value('Severe Pelvic Pain, Fatigue'),
        ),
      );
      await db.into(db.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: start.add(const Duration(days: 2)),
          flowType: 'Heavy',
          bloodColor: const Value('BrightRed'),
          clotSize: const Value('Small'),
          isFlooding: const Value(false),
          symptoms: const Value('Pelvic Pain'),
        ),
      );

      // Day 4: Medium
      await db.into(db.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: start.add(const Duration(days: 3)),
          flowType: 'Medium',
          bloodColor: const Value('BrightRed'),
          clotSize: const Value('None'),
        ),
      );

      // Day 5: Brown Spotting
      await db.into(db.cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: start.add(const Duration(days: 4)),
          flowType: 'Spotting',
          bloodColor: const Value('DarkBrown'),
          clotSize: const Value('None'),
        ),
      );

      // Mid-Cycle Spotting (Cycles 3 & 4)
      if (i == 2 || i == 3) {
        await db.into(db.cycleEvents).insert(
          CycleEventsCompanion.insert(
            date: start.add(const Duration(days: 14)),
            flowType: 'Spotting',
            bloodColor: const Value('Pink'),
            clotSize: const Value('None'),
            symptoms: const Value('Ovulation Pain, Spotting'),
          ),
        );
      }
    }
  }
}
