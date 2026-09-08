import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/features/today/presentation/today_controller.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/features/routines/domain/phase_state_machine.dart';

void main() {
  group('TodayState model tests', () {
    test('Legacy accessors return null when empty', () {
      const state = TodayState(routineCards: [], missedRecentLogs: []);
      
      expect(state.activeRoutine, null);
      expect(state.todayLog, null);
      expect(state.phaseState, null);
    });

    test('Legacy accessors return first routine data', () {
      final routine = Routine(
        id: 1,
        name: 'Birth Control',
        regimenType: 'Cyclic_21_7',
        startDate: DateTime(2023, 1, 1),
        reminderTime: '09:00',
        activeDays: 21,
        breakDays: 7,
        isActive: true,
      );
      
      final todayLog = RoutineLog(
        id: 1,
        routineId: 1,
        scheduledDate: DateTime(2023, 1, 15),
        status: 'Taken',
      );
      
      final phaseState = PhaseState(
        currentPhase: 1,
        dayInPhase: 15,
        totalPhaseDays: 21,
        isBreakPeriod: false,
      );

      final card = RoutineCardState(
        routine: routine,
        phaseState: phaseState,
        todayLog: todayLog,
      );

      final state = TodayState(
        routineCards: [card],
        missedRecentLogs: [],
      );

      expect(state.activeRoutine?.name, 'Birth Control');
      expect(state.todayLog?.status, 'Taken');
      expect(state.phaseState?.dayInPhase, 15);
    });
  });
}
