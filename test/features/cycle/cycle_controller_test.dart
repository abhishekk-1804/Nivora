import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nivora_app/features/cycle/presentation/cycle_controller.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/providers/database_provider.dart';

void main() {
  group('CycleState Phase Calculation', () {
    test('Day 1-5 is always Menstrual Phase', () {
      final state = CycleState(
        currentCycleDay: 3,
        medianCycleLength: 28,
      );
      expect(state.currentPhase, 'Menstrual Phase');
    });

    test('Standard 28-day cycle: Day 14 is Ovulatory Window', () {
      final state = CycleState(
        currentCycleDay: 14,
        medianCycleLength: 28,
      );
      expect(state.currentPhase, 'Ovulatory Window');
    });

    test('Standard 28-day cycle: Day 16 is Luteal Phase', () {
      final state = CycleState(
        currentCycleDay: 16,
        medianCycleLength: 28,
      );
      expect(state.currentPhase, 'Luteal Phase');
    });

    test('Short 24-day cycle: Day 9 is Ovulatory Window', () {
      // lutealStart = 24 - 13 = 11
      // ovulatoryStart = 11 - 4 = 7
      final state = CycleState(
        currentCycleDay: 9,
        medianCycleLength: 24,
      );
      expect(state.currentPhase, 'Ovulatory Window');
    });

    test('Long 35-day cycle: Day 20 is Ovulatory Window', () {
      // lutealStart = 35 - 13 = 22
      // ovulatoryStart = 22 - 4 = 18
      final state = CycleState(
        currentCycleDay: 20,
        medianCycleLength: 35,
      );
      expect(state.currentPhase, 'Ovulatory Window');
    });
    
    test('Uses estimatedCycleDay if currentCycleDay is null', () {
      final state = CycleState(
        currentCycleDay: null,
        estimatedCycleDay: 25,
        medianCycleLength: 28,
      );
      expect(state.currentPhase, 'Luteal Phase');
    });
    
    test('Returns null if both days are null', () {
      final state = CycleState(
        currentCycleDay: null,
        estimatedCycleDay: null,
        medianCycleLength: 28,
      );
      expect(state.currentPhase, null);
    });
  });

  group('Cycle Data Integrity & Upsert Merging (Regression)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          cycleDaoProvider.overrideWithValue(db.cycleDao),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('Period log (Heavy, pain 8, clots Large, flooding true) + Symptom log (energy 3, mood low) = All fields preserved', () async {
      final controller = container.read(cycleControllerProvider.notifier);
      final today = DateTime.now();

      // 1. User logs heavy period event
      await controller.logCycleEvent(
        date: today,
        flowType: 'Heavy',
        clotSize: 'Large',
        isFlooding: true,
        isTrueCycleStart: true,
        painIntensity: 8,
        symptoms: ['Cramps'],
      );

      // 2. User logs symptom later on the same day (e.g. Energy check-in from TodayScreen)
      await controller.logSymptomOnly('Energy: 3');

      // 3. User logs another symptom (Mood check-in)
      await controller.logSymptomOnly('Mood: Low');

      // 4. Verify in database that period flow, pain, clots, flooding, and symptoms are all preserved
      final event = await db.cycleDao.getEventForDate(today);
      expect(event, isNotNull);
      expect(event!.flowType, 'Heavy');
      expect(event.painIntensity, 8);
      expect(event.clotSize, 'Large');
      expect(event.isFlooding, isTrue);
      expect(event.isTrueCycleStart, isTrue);
      expect(event.symptoms, contains('Cramps'));
      expect(event.symptoms, contains('Energy: 3'));
      expect(event.symptoms, contains('Mood: Low'));
    });

    test('Symptom log first + Period log later = All fields preserved and symptoms merged', () async {
      final controller = container.read(cycleControllerProvider.notifier);
      final today = DateTime.now();

      // 1. Morning symptom log
      await controller.logSymptomOnly('Energy: 3');

      // 2. Afternoon period log
      await controller.logCycleEvent(
        date: today,
        flowType: 'Heavy',
        clotSize: 'Large',
        isFlooding: true,
        isTrueCycleStart: true,
        painIntensity: 8,
        symptoms: ['Cramps'],
      );

      // 3. Verify
      final event = await db.cycleDao.getEventForDate(today);
      expect(event, isNotNull);
      expect(event!.flowType, 'Heavy');
      expect(event.painIntensity, 8);
      expect(event.clotSize, 'Large');
      expect(event.isFlooding, isTrue);
      expect(event.isTrueCycleStart, isTrue);
      expect(event.symptoms, contains('Energy: 3'));
      expect(event.symptoms, contains('Cramps'));
    });
  });

  group('DAO Provider Resolution', () {
    test('clinicalProfileDaoProvider and metabolicLogDaoProvider resolve correctly', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      final clinicalDao = container.read(clinicalProfileDaoProvider);
      final metabolicDao = container.read(metabolicLogDaoProvider);

      expect(clinicalDao, isNotNull);
      expect(metabolicDao, isNotNull);

      container.dispose();
      db.close();
    });
  });
}
