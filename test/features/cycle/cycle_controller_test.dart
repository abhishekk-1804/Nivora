import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/features/cycle/presentation/cycle_controller.dart';

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
}
