import 'package:drift/drift.dart';
import '../tables/schema_tables.dart';
import '../app_database.dart';
import '../../utils/date_utils.dart';

part 'routine_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineLogs])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  /// Insert a new routine preset
  Future<int> insertRoutine({
    required String name,
    required String regimenType, // Cyclic_21_7, Daily
    int activeDays = 21,
    int breakDays = 7,
    required DateTime startDate,
    required String reminderTime,
    String? dose,
    String? notes,
    DateTime? endDate,
  }) {
    return into(routines).insert(
      RoutinesCompanion.insert(
        name: name,
        regimenType: regimenType,
        activeDays: Value(activeDays),
        breakDays: Value(breakDays),
        startDate: AppDateUtils.stripTime(startDate),
        reminderTime: reminderTime,
        dose: Value(dose),
        notes: Value(notes),
        endDate: Value(endDate == null ? null : AppDateUtils.stripTime(endDate)),
      ),
    );
  }

  /// Get active routine
  Future<Routine?> getActiveRoutine() {
    return (select(routines)..where((t) => t.isActive.equals(true))..limit(1)).getSingleOrNull();
  }
  
  /// Watch active routine (single)
  Stream<Routine?> watchActiveRoutine() {
    return (select(routines)..where((t) => t.isActive.equals(true))..limit(1)).watchSingleOrNull();
  }

  /// Watch ALL active routines (for multi-medicine support)
  Stream<List<Routine>> watchActiveRoutines() {
    return (select(routines)..where((t) => t.isActive.equals(true))).watch();
  }

  /// Get ALL active routines
  Future<List<Routine>> getActiveRoutines() {
    return (select(routines)..where((t) => t.isActive.equals(true))).get();
  }

  /// Log daily intake status
  Future<void> logIntake({
    required int routineId,
    required DateTime scheduledDate,
    required String status, // Taken, Missed, Skipped
    DateTime? completedAt,
  }) async {
    final normalizedDate = AppDateUtils.stripTime(scheduledDate);
    final companion = RoutineLogsCompanion.insert(
      routineId: routineId,
      scheduledDate: normalizedDate,
      status: status,
      completedAt: Value(completedAt),
    );

    // Check if log exists for this date
    final existing = await (select(routineLogs)
          ..where((t) => t.routineId.equals(routineId) & t.scheduledDate.equals(normalizedDate))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await update(routineLogs).replace(
        companion.copyWith(id: Value(existing.id)),
      );
    } else {
      await into(routineLogs).insert(companion);
    }
  }

  /// Get log for a specific date
  Future<RoutineLog?> getLogForDate(int routineId, DateTime date) {
    final normalizedDate = AppDateUtils.stripTime(date);
    return (select(routineLogs)
          ..where((t) => t.routineId.equals(routineId) & t.scheduledDate.equals(normalizedDate))
          ..limit(1))
        .getSingleOrNull();
  }
  
  /// Watch log for a specific date
  Stream<RoutineLog?> watchLogForDate(int routineId, DateTime date) {
    final normalizedDate = AppDateUtils.stripTime(date);
    return (select(routineLogs)
          ..where((t) => t.routineId.equals(routineId) & t.scheduledDate.equals(normalizedDate))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Get all logs for a routine within a date range
  Future<List<RoutineLog>> getLogsInRange(int routineId, DateTime startDate, DateTime endDate) {
    return (select(routineLogs)
          ..where((t) =>
              t.routineId.equals(routineId) &
              t.scheduledDate.isBetweenValues(AppDateUtils.stripTime(startDate), AppDateUtils.stripTime(endDate)))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate, mode: OrderingMode.asc)]))
        .get();
  }

  /// Watch all logs for multiple routines within a date range
  Stream<List<RoutineLog>> watchRecentLogsForRoutines(List<int> routineIds, DateTime startDate, DateTime endDate) {
    return (select(routineLogs)
          ..where((t) =>
              t.routineId.isIn(routineIds) &
              t.scheduledDate.isBetweenValues(AppDateUtils.stripTime(startDate), AppDateUtils.stripTime(endDate)))
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate, mode: OrderingMode.asc)]))
        .watch();
  }

  /// Delete a routine and all its logs
  Future<void> deleteRoutine(int routineId) async {
    await (delete(routineLogs)..where((t) => t.routineId.equals(routineId))).go();
    await (delete(routines)..where((t) => t.id.equals(routineId))).go();
  }

  /// Update an existing routine
  Future<void> updateRoutine({
    required int id,
    required String name,
    required String regimenType,
    required DateTime startDate,
    required String reminderTime,
    String? dose,
    String? notes,
    DateTime? endDate,
  }) async {
    await (update(routines)..where((t) => t.id.equals(id))).write(
      RoutinesCompanion(
        name: Value(name),
        regimenType: Value(regimenType),
        startDate: Value(AppDateUtils.stripTime(startDate)),
        reminderTime: Value(reminderTime),
        dose: Value(dose),
        notes: Value(notes),
        endDate: Value(endDate == null ? null : AppDateUtils.stripTime(endDate)),
      ),
    );
  }
}