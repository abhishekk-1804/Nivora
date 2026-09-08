import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/features/today/presentation/today_controller.dart';

/// Creates a [ProviderContainer] backed by an in-memory Drift database.
ProviderContainer makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      routineDaoProvider.overrideWithValue(db.routineDao),
    ],
  );
}

void main() {
  group('TodayController — state computation', () {
    late ProviderContainer container;
    late AppDatabase db;
    late ProviderSubscription subscription;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = makeContainer(db);
      // Keep the provider alive for the duration of the test
      subscription = container.listen(todayControllerProvider, (_, __) {});
    });

    tearDown(() async {
      subscription.close();
      container.dispose();
      await db.close();
    });

    test('TC001: emits empty TodayState when there are no routines', () async {
      final states = container.read(todayControllerProvider);
      // First emission should be AsyncLoading
      expect(states, isA<AsyncValue<TodayState>>());

      // Wait for data
      final value = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(value.routineCards, isEmpty);
      expect(value.missedRecentLogs, isEmpty);
    });

    test('TC002: Daily routine never shows break period', () async {
      final dao = container.read(routineDaoProvider);
      await dao.insertRoutine(
        name: 'Inositol',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        reminderTime: '08:00',
      );

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(state.routineCards, isNotEmpty);
      final card = state.routineCards.first;
      expect(card.phaseState.isBreakPeriod, isFalse,
          reason: 'Daily routines must never report a break period');
    });

    test('TC003: Cyclic 21/7 routine on day 22 reports break period', () async {
      final dao = container.read(routineDaoProvider);
      // Start date 22 days ago → day 22 = first day of 7-day break
      await dao.insertRoutine(
        name: 'Birth Control',
        regimenType: 'Cyclic_21_7',
        startDate: DateTime.now().subtract(const Duration(days: 21)),
        reminderTime: '20:00',
        activeDays: 21,
        breakDays: 7,
      );

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(state.routineCards, isNotEmpty);
      final card = state.routineCards.first;
      expect(card.phaseState.isBreakPeriod, isTrue,
          reason: 'Day 22 of a 21/7 regimen must be a break period');
    });

    test('TC004: Expired routine (endDate in past) is excluded', () async {
      final dao = container.read(routineDaoProvider);
      await dao.insertRoutine(
        name: 'Metformin',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        reminderTime: '12:00',
        endDate: DateTime.now().subtract(const Duration(days: 1)), // expired yesterday
      );

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(state.routineCards, isEmpty,
          reason: 'Routines past their end date must not appear on Today screen');
    });

    test('TC005: markTaken logs intake with Taken status', () async {
      final dao = container.read(routineDaoProvider);
      final routineId = await dao.insertRoutine(
        name: 'Metformin',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        reminderTime: '12:00',
      );

      // Wait for initial state to load
      await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      final controller = container.read(todayControllerProvider.notifier);
      await controller.markTaken(DateTime.now(), routineId: routineId);
      await Future.delayed(const Duration(milliseconds: 100));

      // Re-read
      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      final card = state.routineCards.firstWhere((c) => c.routine.id == routineId);
      expect(card.todayLog?.status, 'Taken');
    });

    test('TC006: markSkipped logs intake with Skipped status', () async {
      final dao = container.read(routineDaoProvider);
      final routineId = await dao.insertRoutine(
        name: 'Inositol',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        reminderTime: '09:00',
      );

      await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      final controller = container.read(todayControllerProvider.notifier);
      await controller.markSkipped(DateTime.now(), routineId: routineId);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      final card = state.routineCards.firstWhere((c) => c.routine.id == routineId);
      expect(card.todayLog?.status, 'Skipped');
    });

    test('TC007: deleteRoutine removes it from routineCards', () async {
      final dao = container.read(routineDaoProvider);
      final routineId = await dao.insertRoutine(
        name: 'Vitamin D',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        reminderTime: '07:00',
      );

      await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      final controller = container.read(todayControllerProvider.notifier);
      await controller.deleteRoutine(routineId);
      await Future.delayed(const Duration(milliseconds: 100));

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(state.routineCards.any((c) => c.routine.id == routineId), isFalse);
    });

    test('TC008: multiple routines all tracked independently', () async {
      final dao = container.read(routineDaoProvider);
      await dao.insertRoutine(
        name: 'Routine A',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        reminderTime: '08:00',
      );
      await dao.insertRoutine(
        name: 'Routine B',
        regimenType: 'Daily',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        reminderTime: '20:00',
      );
      await Future.delayed(const Duration(milliseconds: 100));

      final state = await container
          .read(todayControllerProvider.future)
          .timeout(const Duration(seconds: 5));

      expect(state.routineCards.length, 2);
      expect(state.routineCards.map((c) => c.routine.name).toSet(),
          containsAll(['Routine A', 'Routine B']));
    });
  });
}
