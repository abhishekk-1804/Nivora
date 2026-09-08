import 'package:drift/drift.dart';
import '../tables/schema_tables.dart';
import '../app_database.dart';
import '../../utils/date_utils.dart';
import '../../../features/report/domain/report_payload.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

part 'report_dao.g.dart';

@DriftAccessor(tables: [CycleEvents, Routines, RoutineLogs, TreatmentInterventions, LabResults, ClinicalProfile, MetabolicLogs])
class ReportDao extends DatabaseAccessor<AppDatabase> with _$ReportDaoMixin {
  ReportDao(super.db);

  /// Compile raw database entries into the DoctorReportData domain model across any user-selected date range.
  Future<DoctorReportData> generateReport({
    required DateTime startDate,
    required DateTime endDate,
    required String rangeLabel,
  }) async {
    final start = AppDateUtils.stripTime(startDate);
    final end = AppDateUtils.stripTime(endDate);

    // 1. Fetch Cycle Events
    final cycles = await (select(cycleEvents)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();

    // 2. Fetch Routine Adherence
    final startBound = DateTime(start.year, start.month, start.day);
    final endBound = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final logs = await (select(routineLogs)
          ..where((t) => t.scheduledDate.isBetweenValues(startBound, endBound)))
        .get();

    // 3. Fetch Treatment Benchmark
    final intervention = await (select(treatmentInterventions)..orderBy([(t) => OrderingTerm(expression: t.startDate, mode: OrderingMode.desc)])..limit(1)).getSingleOrNull();

    // 4. Fetch Lab Results
    final labs = await (select(labResults)
          ..where((t) => t.date.isBetweenValues(startBound, endBound))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();

    // 5. Fetch Tier 4 (Clinical Profile & Metabolic Logs)
    final profile = await select(clinicalProfile).getSingleOrNull();
    final metabolic = await (select(metabolicLogs)
          ..where((t) => t.date.isBetweenValues(startBound, endBound))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();

    // 6. Fetch Active Routines (Medications)
    final activeRoutines = await (select(routines)..where((t) => t.isActive.equals(true))).get();

    // 7. Offload heavy clinical math to background Isolate
    final payload = {
      'cycles': cycles.map((e) => e.toJson()).toList(),
      'logs': logs.map((e) => e.toJson()).toList(),
      'labs': labs.map((e) => e.toJson()).toList(),
      'intervention': intervention?.toJson(),
      'profile': profile?.toJson(),
      'metabolic': metabolic.map((e) => e.toJson()).toList(),
      'activeRoutines': activeRoutines.map((e) => e.toJson()).toList(),
      'rangeLabel': rangeLabel,
      'startIso': start.toIso8601String(),
    };

    return await compute(_aggregateClinicalData, payload);
  }
}

/// Runs in a background Isolate to prevent UI frame drops during heavy array calculations
DoctorReportData _aggregateClinicalData(Map<String, dynamic> payload) {
  final cyclesRaw = payload['cycles'] as List<dynamic>;
  final logsRaw = payload['logs'] as List<dynamic>;
  final labsRaw = payload['labs'] as List<dynamic>;
  final interventionRaw = payload['intervention'] as Map<String, dynamic>?;
  final profileRaw = payload['profile'] as Map<String, dynamic>?;
  final metabolicRaw = payload['metabolic'] as List<dynamic>;
  final activeRoutinesRaw = payload['activeRoutines'] as List<dynamic>? ?? [];
  final rangeLabel = payload['rangeLabel'] as String;


  // Convert JSON maps back to Drift data classes or similar structures for logic.
  // Wrapped in try-catches to prevent isolate crashes from corrupted rows/schema drift.
  List<CycleEvent> cycles = [];
  try {
    cycles = cyclesRaw.map((e) => CycleEvent.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    cycles = [];
  }

  List<RoutineLog> logs = [];
  try {
    logs = logsRaw.map((e) => RoutineLog.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    logs = [];
  }

  List<LabResult> labs = [];
  try {
    labs = labsRaw.map((e) => LabResult.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    labs = [];
  }

  TreatmentIntervention? intervention;
  try {
    intervention = interventionRaw != null ? TreatmentIntervention.fromJson(interventionRaw) : null;
  } catch (e) {
    intervention = null;
  }

  bool profilePCOM = false;
  try {
    profilePCOM = profileRaw != null ? (profileRaw['hasPCOM'] as bool? ?? false) : false;
  } catch (e) {
    profilePCOM = false;
  }

  List<MetabolicLog> metabolic = [];
  try {
    metabolic = metabolicRaw.map((e) => MetabolicLog.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    metabolic = [];
  }

  List<Routine> activeRoutinesDb = [];
  try {
    activeRoutinesDb = activeRoutinesRaw.map((e) => Routine.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    activeRoutinesDb = [];
  }
  
  final activeMedications = activeRoutinesDb.map((r) {
    if (r.dose != null && r.dose!.isNotEmpty) {
      return '${r.name} (${r.dose})';
    }
    return r.name;
  }).toList();

  // 2. Calculate Cycle Statistics based on True Cycle Starts
  // Enforce 10-day buffer rule: consecutive true starts within 10 days are part of the same cycle.
  final rawTrueCycles = cycles.where((c) => c.isTrueCycleStart).toList();
  final List<CycleEvent> trueCycles = [];
  
  for (var c in rawTrueCycles) {
    if (trueCycles.isEmpty) {
      trueCycles.add(c);
    } else {
      final diff = AppDateUtils.daysBetween(trueCycles.last.date, c.date);
      if (diff >= 10) {
        trueCycles.add(c);
      }
    }
  }
  
  int totalCycles = trueCycles.length;
  List<int> cycleLengths = [];
  
  for (int i = 1; i < trueCycles.length; i++) {
    final prevDate = trueCycles[i - 1].date;
    final currDate = trueCycles[i].date;
    final diff = AppDateUtils.daysBetween(prevDate, currDate);
    if (diff > 14) { // Only count realistic cycle lengths
      cycleLengths.add(diff);
    }
  }

  int cycleRangeMin = 0;
  int cycleRangeMax = 0;
  int medianCycleLength = 0;

  if (cycleLengths.isNotEmpty) {
    cycleLengths.sort();
    cycleRangeMin = cycleLengths.first;
    cycleRangeMax = cycleLengths.last;
    
    final middle = cycleLengths.length ~/ 2;
    if (cycleLengths.length % 2 == 1) {
      medianCycleLength = cycleLengths[middle];
    } else {
      medianCycleLength = ((cycleLengths[middle - 1] + cycleLengths[middle]) / 2.0).round();
    }
  }

  // 3. Clinical Bleeding Metrics
  int totalHeavyWithClotsDays = 0;
  int floodingEventsCount = 0;
  Map<String, int> spottingColors = {};

  for (var c in cycles) {
    if (c.flowType == 'Heavy' && c.clotSize != 'None') {
      totalHeavyWithClotsDays++;
    }
    if (c.isFlooding) {
      floodingEventsCount++;
    }
    if (c.flowType == 'Spotting' && c.bloodColor != null) {
      spottingColors[c.bloodColor!] = (spottingColors[c.bloodColor!] ?? 0) + 1;
    }
  }

  String spottingColorProfile = 'N/A';
  if (spottingColors.isNotEmpty) {
    final dominant = spottingColors.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final formattedColor = dominant.replaceAllMapped(RegExp(r'([A-Z])'), (Match m) => ' ${m[1]}').trim();
    spottingColorProfile = 'Predominantly $formattedColor';
  }

  // 4. Fetch Routine Adherence
  int adherencePercentage = 0;
  if (logs.isNotEmpty) {
    final takenCount = logs.where((l) => l.status == 'Taken').length;
    adherencePercentage = (takenCount / logs.length * 100).round();
  }

  // 5. PMDD Clustering — exclude anovulatory events (flowType == 'Anovulatory')
  //    so 'Anovulatory / Missed Cycle' doesn't pollute the symptom phase table.
  final bleedingCycles = cycles.where((c) => c.flowType != 'Anovulatory').toList();
  Map<String, Map<String, int>> symptomPhases = {};

  for (var event in bleedingCycles) {
    if (event.symptoms == null || event.symptoms!.isEmpty) continue;
    
    DateTime? currentCycleDate;
    DateTime? nextCycleDate;
    
    for (var tc in trueCycles) {
      if (tc.date.isBefore(event.date) || tc.date.isAtSameMomentAs(event.date)) {
        currentCycleDate = tc.date;
      }
      if (tc.date.isAfter(event.date) && nextCycleDate == null) {
        nextCycleDate = tc.date;
      }
    }
    
    String phase = 'Mid-Cycle / Ovulatory';
    if (nextCycleDate != null) {
      final daysToNext = AppDateUtils.daysBetween(event.date, nextCycleDate);
      if (daysToNext >= 1 && daysToNext <= 7) phase = 'Luteal Phase (PMDD Indicator)';
    }
    if (currentCycleDate != null && phase == 'Mid-Cycle / Ovulatory') {
      final daysFromStart = AppDateUtils.daysBetween(currentCycleDate, event.date);
      if (daysFromStart >= 0 && daysFromStart <= 4) phase = 'Menstrual (Dysmenorrhea)';
    }

    final sympList = event.symptoms!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (var symp in sympList) {
      symptomPhases.putIfAbsent(symp, () => {'Luteal Phase (PMDD Indicator)': 0, 'Menstrual (Dysmenorrhea)': 0, 'Mid-Cycle / Ovulatory': 0});
      symptomPhases[symp]![phase] = symptomPhases[symp]![phase]! + 1;
    }
  }

  List<List<String>> symptomPhaseClusters = [];
  symptomPhases.forEach((symp, counts) {
    int total = counts.values.reduce((a, b) => a + b);
    if (total > 0) {
      String dominantPhase = counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      double ratio = counts[dominantPhase]! / total;
      
      String clusterLabel = dominantPhase;
      if (ratio >= 0.70 && dominantPhase == 'Luteal Phase (PMDD Indicator)') {
        clusterLabel = 'Luteal Alignment (PMDD Pattern)';
      } else if (ratio >= 0.70 && dominantPhase == 'Menstrual (Dysmenorrhea)') {
        clusterLabel = 'Menstrual Alignment';
      } else if (ratio < 0.50) {
        clusterLabel = 'Distributed Pattern';
      }
      
      symptomPhaseClusters.add([symp, total.toString(), clusterLabel]);
    }
  });

  symptomPhaseClusters.sort((a, b) => int.parse(b[1]).compareTo(int.parse(a[1])));

  // 5b. Pain Analytics (NRS 0–10)
  // Only consider events where painIntensity was assessed (non-null, i.e., v3+ data).
  final painEvents = cycles.where((c) => c.painIntensity != null).toList();
  double averagePainScore = 0.0;
  int peakPainScore = 0;
  double lutealAveragePainScore = 0.0;

  if (painEvents.isNotEmpty) {
    final total = painEvents.map((c) => c.painIntensity!).reduce((a, b) => a + b);
    averagePainScore = double.parse((total / painEvents.length).toStringAsFixed(1));
    peakPainScore = painEvents.map((c) => c.painIntensity!).reduce((a, b) => a > b ? a : b);

    // Compute average pain specifically in the luteal phase
    final lutealPainEvents = <int>[];
    for (var event in painEvents) {
      DateTime? nextCycleDate;
      for (var tc in trueCycles) {
        if (tc.date.isAfter(event.date) && nextCycleDate == null) {
          nextCycleDate = tc.date;
        }
      }
      if (nextCycleDate != null) {
        final daysToNext = AppDateUtils.daysBetween(event.date, nextCycleDate);
        if (daysToNext >= 1 && daysToNext <= 7) {
          lutealPainEvents.add(event.painIntensity!);
        }
      }
    }
    if (lutealPainEvents.isNotEmpty) {
      final lutealTotal = lutealPainEvents.reduce((a, b) => a + b);
      lutealAveragePainScore = double.parse(
        (lutealTotal / lutealPainEvents.length).toStringAsFixed(1),
      );
    }
  }

  // 5c. Anovulatory month count
  final anovulatoryMonthsLogged = cycles.where((c) => c.flowType == 'Anovulatory').length;

  // 6. Treatment Benchmark
  Map<String, String>? treatmentBenchmark;
  if (intervention != null) {
    final activeIntervention = intervention;
    final preCycles = trueCycles.where((c) => c.date.isBefore(activeIntervention.startDate)).toList();
    final postCycles = trueCycles.where((c) => c.date.isAfter(activeIntervention.startDate) || c.date.isAtSameMomentAs(activeIntervention.startDate)).toList();
    
    int preHeavy = cycles.where((c) => c.date.isBefore(activeIntervention.startDate) && c.flowType == 'Heavy').length;
    int postHeavy = cycles.where((c) => (c.date.isAfter(activeIntervention.startDate) || c.date.isAtSameMomentAs(activeIntervention.startDate)) && c.flowType == 'Heavy').length;
    
    int preMedian = 0;
    if (preCycles.length >= 2) {
      List<int> preLen = [];
      for (int i = 1; i < preCycles.length; i++) {
        preLen.add(AppDateUtils.daysBetween(preCycles[i-1].date, preCycles[i].date));
      }
      preLen.sort();
      preMedian = preLen[preLen.length ~/ 2];
    }
    
    int postMedian = 0;
    if (postCycles.length >= 2) {
      List<int> postLen = [];
      for (int i = 1; i < postCycles.length; i++) {
        postLen.add(AppDateUtils.daysBetween(postCycles[i-1].date, postCycles[i].date));
      }
      postLen.sort();
      postMedian = postLen[postLen.length ~/ 2];
    }

    treatmentBenchmark = {
      'title': activeIntervention.title,
      'pre': 'Pre-Treatment (${preCycles.length} cycles): Median ${preMedian > 0 ? '${preMedian}d' : 'N/A'} | $preHeavy Heavy Days',
      'post': 'Post-Treatment (${postCycles.length} cycles): Median ${postMedian > 0 ? '${postMedian}d' : 'N/A'} | $postHeavy Heavy Days',
    };
  }

  // 7. Generate Cycle Rows for Table (max 6 for PDF constraint)
  final DateFormat formatter = DateFormat('MMM d, yyyy');
  List<List<String>> cycleRows = [];
  
  final reversedCycles = trueCycles.reversed.toList();
  final limit = min(reversedCycles.length, 6);
  
  for (int i = 0; i < limit; i++) {
    final c = reversedCycles[i];
    final chronIndex = trueCycles.length - 1 - i;
    
    String endDateStr = 'Ongoing';
    String lengthStr = '-';
    
    if (chronIndex + 1 < trueCycles.length) {
      final nextCycle = trueCycles[chronIndex + 1];
      final length = AppDateUtils.daysBetween(c.date, nextCycle.date);
      endDateStr = formatter.format(nextCycle.date.subtract(const Duration(days: 1)));
      lengthStr = '$length days';
    } else {
      final length = AppDateUtils.daysBetween(c.date, DateTime.now());
      lengthStr = '$length days (Ongoing)';
    }

    final cycleEndBound = (chronIndex + 1 < trueCycles.length) ? trueCycles[chronIndex + 1].date : DateTime.now();
    final eventsInCycle = cycles.where((e) => (e.date.isAtSameMomentAs(c.date) || e.date.isAfter(c.date)) && e.date.isBefore(cycleEndBound)).toList();
    
    bool hasHeavy = eventsInCycle.any((e) => e.flowType == 'Heavy');
    bool hasFlooding = eventsInCycle.any((e) => e.isFlooding);
    bool hasClots = eventsInCycle.any((e) => e.clotSize == 'Large');

    String flowDesc = hasHeavy ? 'Heavy' : (eventsInCycle.isNotEmpty ? eventsInCycle.first.flowType : 'Unknown');
    List<String> flowDetails = [];
    if (hasClots) flowDetails.add('Large Clots');
    if (hasFlooding) flowDetails.add('Flooding');
    if (flowDetails.isNotEmpty) flowDesc += ' (${flowDetails.join(', ')})';

    final allSymptoms = eventsInCycle.where((e) => e.symptoms != null && e.symptoms!.isNotEmpty).map((e) => e.symptoms!).toSet();

    cycleRows.add([
      (chronIndex + 1).toString(),
      formatter.format(c.date),
      endDateStr,
      lengthStr,
      flowDesc,
      allSymptoms.isNotEmpty ? allSymptoms.join(', ') : 'None',
    ]);
  }

  // 8. Generate Lab Results Rows
  List<List<String>> labResultsRows = [];
  for (var lab in labs) {
    labResultsRows.add([
      formatter.format(lab.date),
      lab.testName,
      lab.value,
      lab.notes ?? '',
    ]);
  }

  // 9. Tier 4 Rotterdam & Metabolic Engine
  bool ovulatoryDysfunction = medianCycleLength > 35 || medianCycleLength < 21 || anovulatoryMonthsLogged > 0;
  bool hyperandrogenism = false;
  
  for (var cluster in symptomPhaseClusters) {
    String symp = cluster[0].toLowerCase();
    int count = int.parse(cluster[1]);
    if ((symp.contains('acne') || symp.contains('hair') || symp.contains('hirsutism') || symp.contains('skin')) && count > 2) {
      hyperandrogenism = true;
      break;
    }
  }

  List<List<String>> metabolicRows = [];
  for (var m in metabolic) {
    metabolicRows.add([
      formatter.format(m.date),
      m.weight != null ? '${m.weight} kg' : '-',
      m.waistCircumference != null && m.hipCircumference != null 
          ? '${(m.waistCircumference! / m.hipCircumference!).toStringAsFixed(2)} W/H' 
          : '-',
      m.signs ?? 'None',
    ]);
  }

  return DoctorReportData(
    dateRange: rangeLabel,
    totalCycles: totalCycles,
    cycleRangeMin: cycleRangeMin,
    cycleRangeMax: cycleRangeMax,
    medianCycleLength: medianCycleLength,
    adherencePercentage: adherencePercentage,
    totalHeavyWithClotsDays: totalHeavyWithClotsDays,
    floodingEventsCount: floodingEventsCount,
    spottingColorProfile: spottingColorProfile,
    cycleRows: cycleRows,
    cycleLengthsForChart: cycleLengths,
    symptomPhaseClusters: symptomPhaseClusters,
    labResultsRows: labResultsRows,
    treatmentBenchmark: treatmentBenchmark,
    anovulatoryMonthsLogged: anovulatoryMonthsLogged,
    averagePainScore: averagePainScore,
    peakPainScore: peakPainScore,
    lutealAveragePainScore: lutealAveragePainScore,
    rotterdamOvulatoryDysfunction: ovulatoryDysfunction,
    rotterdamHyperandrogenism: hyperandrogenism,
    rotterdamPCOM: profilePCOM,
    metabolicRows: metabolicRows,
    activeMedications: activeMedications,
  );
}
