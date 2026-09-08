import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/features/routines/domain/phase_state_machine.dart';

void main() {
  group('PhaseStateMachine Deterministic 21/7 Logic', () {
    final startDate = DateTime(2023, 1, 1); // Started on Jan 1, 2023

    test('Day 1 of Phase 1', () {
      final targetDate = DateTime(2023, 1, 1);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 1);
      expect(phase.dayInPhase, 1);
      expect(phase.totalPhaseDays, 21);
      expect(phase.isBreakPeriod, false);
    });

    test('Day 21 of Phase 1 (Last active day)', () {
      final targetDate = DateTime(2023, 1, 21);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 1);
      expect(phase.dayInPhase, 21);
      expect(phase.totalPhaseDays, 21);
      expect(phase.isBreakPeriod, false);
    });

    test('Day 22 (Day 1 of Break 1)', () {
      final targetDate = DateTime(2023, 1, 22);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 1);
      expect(phase.dayInPhase, 1);
      expect(phase.totalPhaseDays, 7);
      expect(phase.isBreakPeriod, true);
    });

    test('Day 28 (Last day of Break 1)', () {
      final targetDate = DateTime(2023, 1, 28);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 1);
      expect(phase.dayInPhase, 7);
      expect(phase.totalPhaseDays, 7);
      expect(phase.isBreakPeriod, true);
    });

    test('Day 29 (Day 1 of Phase 2)', () {
      final targetDate = DateTime(2023, 1, 29);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 2);
      expect(phase.dayInPhase, 1);
      expect(phase.totalPhaseDays, 21);
      expect(phase.isBreakPeriod, false);
    });

    test('Target date prior to start date handles gracefully', () {
      final targetDate = DateTime(2022, 12, 31);
      final phase = PhaseState.calculate(
        startDate: startDate,
        targetDate: targetDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(phase.currentPhase, 1);
      expect(phase.dayInPhase, 1);
      expect(phase.totalPhaseDays, 21);
      expect(phase.isBreakPeriod, false);
    });
  });
}
