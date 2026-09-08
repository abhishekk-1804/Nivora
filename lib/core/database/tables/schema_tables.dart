import 'package:drift/drift.dart';

@TableIndex(name: 'idx_cycle_events_date', columns: {#date})
class CycleEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  // flowType: Spotting | Light | Medium | Heavy | Anovulatory
  TextColumn get flowType => text()();
  TextColumn get bloodColor => text().nullable()(); // BrightRed, DarkBrown, Pink
  TextColumn get clotSize => text().withDefault(const Constant('None'))(); // None, Small, Large
  BoolColumn get isFlooding => boolean().withDefault(const Constant(false))(); // Soaking < 2 hrs
  TextColumn get symptoms => text().nullable()(); // Comma-separated list
  TextColumn get notes => text().nullable()();
  BoolColumn get isTrueCycleStart => boolean().withDefault(const Constant(true))();
  // Legacy field kept for backward compat — new code uses painIntensity + painReliefTaken instead.
  TextColumn get painReliefStatus => text().nullable()();
  // NRS 0-10 pain scale (null = not assessed; old events pre-v3 will be null)
  IntColumn get painIntensity => integer().nullable()();
  // Whether the user took pain relief medication on this day
  BoolColumn get painReliefTaken => boolean().withDefault(const Constant(false))();
}

class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // e.g. "Birth Control", "Inositol"
  TextColumn get regimenType => text()(); // e.g. "Cyclic_21_7", "Daily"
  IntColumn get activeDays => integer().withDefault(const Constant(21))();
  IntColumn get breakDays => integer().withDefault(const Constant(7))();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get reminderTime => text()(); // e.g. "20:00"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  // V4 fields
  TextColumn get dose => text().nullable()(); // e.g. "500mg"
  TextColumn get notes => text().nullable()();
  // V6 fields
  DateTimeColumn get endDate => dateTime().nullable()();
}

@TableIndex(name: 'idx_routine_logs_date', columns: {#scheduledDate})
class RoutineLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text()(); // Taken, Missed, Skipped
}

class TreatmentInterventions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // e.g., "Started Metformin + Inositol"
  DateTimeColumn get startDate => dateTime()();
  TextColumn get notes => text().nullable()();
}

@TableIndex(name: 'idx_lab_results_date', columns: {#date})
class LabResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get testName => text()(); // e.g. "Fasting Insulin"
  TextColumn get value => text()(); // e.g. "14.2 mIU/L"
  TextColumn get notes => text().nullable()();
}

// ── Tier 4 Clinical & Metabolic ───────────────────────────────────────────

class ClinicalProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get phenotype => text().nullable()(); // 'A', 'B', 'C', 'D'
  BoolColumn get hasPCOM => boolean().withDefault(const Constant(false))(); // Ultrasound confirmed Polycystic Ovaries
}

@TableIndex(name: 'idx_metabolic_logs_date', columns: {#date})
class MetabolicLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real().nullable()(); // stored in kg
  RealColumn get waistCircumference => real().nullable()(); // stored in cm
  RealColumn get hipCircumference => real().nullable()(); // stored in cm
  TextColumn get signs => text().nullable()(); // Comma-separated: "Acanthosis Nigricans, Sugar Cravings"
}
