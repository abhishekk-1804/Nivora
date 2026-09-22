import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';

part 'cycle_controller.g.dart';

class CycleState {
  final List<CycleEvent> recentEvents;
  final int? currentCycleDay; // null = no active period (>10 days since last bleeding log)
  final CycleEvent? currentPeriodStart;
  final bool isActivePeriod; // true only when user has bleeding logs within the past 10 days
  final int anovulatoryCount; // total anovulatory events logged (for display context)
  final int medianCycleLength; // user's historical median cycle length (fallback to 28)
  final int? estimatedCycleDay; // calculated when isActivePeriod is false
  final List<String> frequentSymptoms;

  CycleState({
    this.recentEvents = const [],
    this.currentCycleDay,
    this.currentPeriodStart,
    this.isActivePeriod = false,
    this.anovulatoryCount = 0,
    this.medianCycleLength = 28,
    this.estimatedCycleDay,
    this.frequentSymptoms = const [],
  });

  /// Estimates the current biological phase based on the cycle day and historical median length.
  String? get currentPhase {
    final day = currentCycleDay ?? estimatedCycleDay;
    if (day == null) return null;
    final m = medianCycleLength < 18 ? 28 : medianCycleLength; // Fallback for edge cases
    
    if (day <= 5) return 'Menstrual Phase';
    
    final lutealStart = m - 13;
    final ovulatoryStart = lutealStart - 4;
    
    if (day >= lutealStart) return 'Luteal Phase';
    if (day >= ovulatoryStart && day < lutealStart) return 'Ovulatory Window';
    return 'Follicular Phase';
  }
}

@riverpod
class CycleController extends _$CycleController {
  @override
  Stream<CycleState> build() async* {
    final dao = ref.watch(cycleDaoProvider);

    await for (final events in dao.watchRecentEvents()) {
      if (events.isEmpty) {
        yield CycleState();
        continue;
      }

      final now = DateTime.now();

      // ── Calculate Frequent Symptoms ─────────────────────────────────────────
      final Map<String, int> symptomCounts = {};
      for (var e in events) {
        if (e.symptoms != null && e.symptoms!.isNotEmpty) {
          final symps = e.symptoms!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != 'Anovulatory / Missed Cycle');
          for (var s in symps) {
            symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
          }
        }
      }
      final sortedSymptoms = symptomCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final frequentSymptoms = sortedSymptoms.take(4).map((e) => e.key).toList();

      // ── Separate bleeding events from anovulatory markers ──────────────────
      // Anovulatory events (flowType == 'Anovulatory') are clinical records,
      // NOT bleeding logs. They must not affect streak or cycle-day calculations.
      final bleedingEvents = events.where((e) => e.flowType != 'Anovulatory').toList();
      final anovulatoryCount = events.where((e) => e.flowType == 'Anovulatory').length;

      if (bleedingEvents.isEmpty) {
        yield CycleState(recentEvents: events, anovulatoryCount: anovulatoryCount, frequentSymptoms: frequentSymptoms);
        continue;
      }

      // events are already ordered DESC — bleedingEvents preserves that order
      final mostRecent = bleedingEvents.first;
      final daysSinceLast = AppDateUtils.daysBetween(mostRecent.date, now);

      // ── Calculate Historical Median Cycle Length ───────────────
      final bleedingTrueCycles = bleedingEvents.where((e) => e.isTrueCycleStart).toList();
      int estimatedMedian = 28; // Default fallback
      
      if (bleedingTrueCycles.length >= 2) {
        List<int> lengths = [];
        for (int i = 0; i < bleedingTrueCycles.length - 1; i++) {
          final diff = AppDateUtils.daysBetween(bleedingTrueCycles[i + 1].date, bleedingTrueCycles[i].date);
          if (diff > 10) lengths.add(diff);
        }
        if (lengths.isNotEmpty) {
          lengths.sort();
          final middle = lengths.length ~/ 2;
          estimatedMedian = (lengths.length % 2 == 1) 
              ? lengths[middle] 
              : ((lengths[middle - 1] + lengths[middle]) / 2.0).round();
        }
      }

      // ── Guardrail: >10 days since last bleeding log = between periods ───────
      if (daysSinceLast > 10) {
        // Calculate estimated day based on the last true cycle start (bleeding or anovulatory)
        final allTrueCycles = events.where((e) => e.isTrueCycleStart).toList();
        
        int? estimatedDay;
        if (allTrueCycles.isNotEmpty) {
          final computedDay = AppDateUtils.daysBetween(allTrueCycles.first.date, now) + 1;
          if (computedDay <= (estimatedMedian * 1.5)) {
            estimatedDay = computedDay;
          }
        }
        
        yield CycleState(
          recentEvents: events,
          currentCycleDay: null,
          currentPeriodStart: null,
          isActivePeriod: false,
          anovulatoryCount: anovulatoryCount,
          medianCycleLength: estimatedMedian,
          estimatedCycleDay: estimatedDay,
          frequentSymptoms: frequentSymptoms,
        );
        continue;
      }

      // ── Find the true streak start ──────────────────────────────────────────
      // Walk backwards through bleeding events (already DESC) to find the first
      // consecutive day — this gives us the real cycle Day 1.
      CycleEvent streakStart = mostRecent;
      for (int i = 1; i < bleedingEvents.length; i++) {
        final gap = AppDateUtils.daysBetween(bleedingEvents[i].date, streakStart.date);
        if (gap <= 1) {
          // consecutive (gap == 1) or same-day duplicate (gap == 0)
          streakStart = bleedingEvents[i];
        } else {
          break;
        }
      }

      final cycleDay = AppDateUtils.daysBetween(streakStart.date, now) + 1;

      yield CycleState(
        recentEvents: events,
        currentCycleDay: cycleDay,
        currentPeriodStart: streakStart,
        isActivePeriod: true,
        anovulatoryCount: anovulatoryCount,
        medianCycleLength: estimatedMedian,
        estimatedCycleDay: null,
        frequentSymptoms: frequentSymptoms,
      );
    }
  }

  /// Log a bleeding/flow cycle event.
  ///
  /// [isTrueCycleStart] should be `true` for Heavy/Medium flow and `false` for
  /// mid-cycle spotting. The [QuickLogSheet] auto-suggests this but the user
  /// can override. Getting this right is critical for accurate median cycle
  /// length in the PDF report.
  Future<void> logCycleEvent({
    required DateTime date,
    required String flowType,
    String? bloodColor,
    String clotSize = 'None',
    bool isFlooding = false,
    bool isTrueCycleStart = true,
    int? painIntensity,       // NRS 0–10; null = not assessed
    bool painReliefTaken = false,
    List<String> symptoms = const [],
    String? notes,
  }) async {
    final dao = ref.read(cycleDaoProvider);
    await dao.logCycleEvent(
      date: date,
      flowType: flowType,
      bloodColor: bloodColor,
      clotSize: clotSize,
      isFlooding: isFlooding,
      isTrueCycleStart: isTrueCycleStart,
      painIntensity: painIntensity,
      painReliefTaken: painReliefTaken,
      symptoms: symptoms.isEmpty ? null : symptoms.join(', '),
      notes: notes,
    );
  }

  /// Log an anovulatory / no-bleed month.
  ///
  /// Stored as a special CycleEvent with flowType='Anovulatory' and
  /// isTrueCycleStart=false. These events:
  ///   - Do NOT affect streak or cycleDay calculations
  ///   - ARE counted in the clinical PDF as "Anovulatory Months Logged"
  ///   - ARE visible in the cycle history for clinical record-keeping
  Future<void> logAnovulatoryMonth({String? notes}) async {
    final dao = ref.read(cycleDaoProvider);
    await dao.logCycleEvent(
      date: DateTime.now(),
      flowType: 'Anovulatory',
      // B-04 fix: must be false — anovulatory months are clinical records only.
      // They must NOT affect streak, cycleDay, or median cycle length calculations.
      isTrueCycleStart: false,
      symptoms: 'Anovulatory / Missed Cycle',
      notes: notes,
    );
  }

  /// Log a standalone symptom (like an energy check-in) without a flow event.
  /// 
  /// Stored with flowType='Symptom Log' and isTrueCycleStart=false so it
  /// does not affect cycle length calculations. If a flow event already exists
  /// for this date, the symptom is merged and the flow event is preserved.
  Future<void> logSymptomOnly(String symptom, {DateTime? date}) async {
    final dao = ref.read(cycleDaoProvider);
    await dao.logCycleEvent(
      date: date ?? DateTime.now(),
      flowType: 'Symptom Log',
      isTrueCycleStart: false,
      symptoms: symptom,
    );
  }
}
