class DoctorReportData {
  final String dateRange;
  final int totalCycles;
  final int cycleRangeMin;
  final int cycleRangeMax;
  final int medianCycleLength;
  final int adherencePercentage;
  final int totalHeavyWithClotsDays;
  final int floodingEventsCount;
  final String spottingColorProfile;
  final List<List<String>> cycleRows;
  final List<List<String>> symptomPhaseClusters; // [Symptom, Frequency, Cluster]
  final List<List<String>> labResultsRows; // [Date, Test Name, Value, Notes]
  final List<int> cycleLengthsForChart;
  final Map<String, String>? treatmentBenchmark; // Pre- vs Post- stats
  final List<String> activeMedications;

  // ── Tier 1 Clinical Fields ─────────────────────────────────────────────────
  /// Number of months where the user explicitly logged an anovulatory/no-bleed event.
  final int anovulatoryMonthsLogged;

  /// Average NRS pain score (0.0–10.0) across all events where pain was assessed.
  /// Excludes events where painIntensity is null (pre-v3 data or unassessed days).
  final double averagePainScore;

  /// Highest single-day NRS pain score recorded in the period.
  final int peakPainScore;

  /// Average NRS pain score specifically within the luteal phase (PMDD indicator).
  final double lutealAveragePainScore;

  // Tier 4: Rotterdam Criteria Screening
  final bool rotterdamOvulatoryDysfunction;
  final bool rotterdamHyperandrogenism;
  final bool rotterdamPCOM;

  // Tier 4: Metabolic Trends (Date, Weight, Waist, Signs)
  final List<List<String>> metabolicRows;

  DoctorReportData({
    required this.dateRange,
    required this.totalCycles,
    required this.cycleRangeMin,
    required this.cycleRangeMax,
    required this.medianCycleLength,
    required this.adherencePercentage,
    required this.totalHeavyWithClotsDays,
    required this.floodingEventsCount,
    required this.spottingColorProfile,
    required this.cycleRows,
    required this.symptomPhaseClusters,
    required this.cycleLengthsForChart,
    this.labResultsRows = const [],
    this.treatmentBenchmark,
    this.activeMedications = const [],
    this.anovulatoryMonthsLogged = 0,
    this.averagePainScore = 0.0,
    this.peakPainScore = 0,
    this.lutealAveragePainScore = 0.0,
    this.rotterdamOvulatoryDysfunction = false,
    this.rotterdamHyperandrogenism = false,
    this.rotterdamPCOM = false,
    this.metabolicRows = const [],
  });

  /// Fallback empty state for reports
  factory DoctorReportData.empty(String rangeLabel) {
    return DoctorReportData(
      dateRange: rangeLabel,
      totalCycles: 0,
      cycleRangeMin: 0,
      cycleRangeMax: 0,
      medianCycleLength: 0,
      adherencePercentage: 0,
      totalHeavyWithClotsDays: 0,
      floodingEventsCount: 0,
      spottingColorProfile: 'N/A',
      cycleRows: [],
      cycleLengthsForChart: [],
      symptomPhaseClusters: [],
      labResultsRows: [],
      treatmentBenchmark: null,
      activeMedications: [],
      anovulatoryMonthsLogged: 0,
      averagePainScore: 0.0,
      peakPainScore: 0,
      lutealAveragePainScore: 0.0,
    );
  }

  /// Checks if there is absolutely no clinical data in this report
  bool get isEmptyData =>
      totalCycles == 0 &&
      labResultsRows.isEmpty &&
      metabolicRows.isEmpty &&
      anovulatoryMonthsLogged == 0;
}

class PdfExportOptions {
  final bool includeVitals;
  final bool includeSymptoms;
  final bool includeMedications;
  final bool includeMetabolic;

  const PdfExportOptions({
    this.includeVitals = true,
    this.includeSymptoms = true,
    this.includeMedications = true,
    this.includeMetabolic = true,
  });
}

