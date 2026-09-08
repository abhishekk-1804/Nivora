import 'package:drift/drift.dart';
import '../tables/schema_tables.dart';
import '../app_database.dart';
import '../../utils/date_utils.dart';

part 'cycle_dao.g.dart';

@DriftAccessor(tables: [CycleEvents])
class CycleDao extends DatabaseAccessor<AppDatabase> with _$CycleDaoMixin {
  CycleDao(super.db);

  /// Get recent cycle events (all types, ordered DESC).
  Stream<List<CycleEvent>> watchRecentEvents({int limit = 100}) {
    return (select(cycleEvents)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
          ..limit(limit))
        .watch();
  }

  /// Get all cycle events for report calculations (ordered ASC).
  Future<List<CycleEvent>> getAllEvents() {
    return (select(cycleEvents)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc)]))
        .get();
  }

  /// Insert or update a cycle event for a given date.
  ///
  /// - [isTrueCycleStart]: set `false` for mid-cycle spotting / breakthrough bleeding.
  ///   The [QuickLogSheet] auto-suggests this based on flow intensity but the user
  ///   can override. **This field is critical for accurate median cycle length
  ///   calculations in the clinical PDF — do not default it to `true` blindly.**
  ///
  /// - [painIntensity]: NRS 0–10. `null` means pain was not assessed. 0 = no pain.
  ///
  /// - [flowType]: one of Spotting | Light | Medium | Heavy | Anovulatory.
  ///   'Anovulatory' events are stored with [isTrueCycleStart] = false and are
  ///   excluded from streak calculations but counted in the clinical PDF.
  Future<void> logCycleEvent({
    required DateTime date,
    required String flowType,
    String? bloodColor,
    String clotSize = 'None',
    bool isFlooding = false,
    bool isTrueCycleStart = true,
    int? painIntensity,       // NRS 0–10; replaces legacy painReliefStatus
    bool painReliefTaken = false,
    String? symptoms,
    String? notes,
  }) async {
    final normalizedDate = AppDateUtils.stripTime(date);
    final companion = CycleEventsCompanion.insert(
      date: normalizedDate,
      flowType: flowType,
      bloodColor: Value(bloodColor),
      clotSize: Value(clotSize),
      isFlooding: Value(isFlooding),
      isTrueCycleStart: Value(isTrueCycleStart),
      // painReliefStatus intentionally left absent — legacy field, no longer written
      painIntensity: Value(painIntensity),
      painReliefTaken: Value(painReliefTaken),
      symptoms: Value(symptoms),
      notes: Value(notes),
    );

    // Upsert: update if an event already exists for this date
    final existing = await (select(cycleEvents)
          ..where((t) => t.date.equals(normalizedDate))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await update(cycleEvents).replace(
        companion.copyWith(id: Value(existing.id)),
      );
    } else {
      await into(cycleEvents).insert(companion);
    }
  }

  /// Delete a cycle event by ID.
  Future<void> deleteCycleEvent(int id) {
    return (delete(cycleEvents)..where((t) => t.id.equals(id))).go();
  }
}
