class PhaseState {
  final int currentPhase;
  final int dayInPhase;
  final int? totalPhaseDays;
  final bool isBreakPeriod;

  PhaseState({
    required this.currentPhase,
    required this.dayInPhase,
    this.totalPhaseDays,
    required this.isBreakPeriod,
  });

  static PhaseState calculate({
    required DateTime startDate,
    required DateTime targetDate,
    int activeDays = 21,
    int breakDays = 7,
  }) {
    final diffDays = targetDate.difference(startDate).inDays;
    if (diffDays < 0) {
      return PhaseState(currentPhase: 1, dayInPhase: 1, totalPhaseDays: activeDays, isBreakPeriod: false);
    }

    final cycleLength = activeDays + breakDays;
    final completedCycles = diffDays ~/ cycleLength;
    final dayInCycle = (diffDays % cycleLength) + 1;

    final currentPhase = completedCycles + 1;
    final isBreak = dayInCycle > activeDays;
    final dayInPhase = isBreak ? (dayInCycle - activeDays) : dayInCycle;
    final totalPhaseDays = isBreak ? breakDays : activeDays;

    return PhaseState(
      currentPhase: currentPhase,
      dayInPhase: dayInPhase,
      totalPhaseDays: totalPhaseDays,
      isBreakPeriod: isBreak,
    );
  }
}
