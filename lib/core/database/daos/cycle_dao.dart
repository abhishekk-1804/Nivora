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

  /// Get cycle event for a specific date if it exists.
  Future<CycleEvent?> getEventForDate(DateTime date) {
    final normalizedDate = AppDateUtils.stripTime(date);
    return (select(cycleEvents)
          ..where((t) => t.date.equals(normalizedDate))
          ..limit(1))
        .getSingleOrNull();
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
  /// - [flowType]: one of Spotting | Light | Medium | Heavy | Anovulatory | Symptom Log.
  ///   'Anovulatory' events are stored with [isTrueCycleStart] = false and are
  ///   excluded from streak calculations but counted in the clinical PDF.
  ///
  /// If a menstrual event already exists for [date], logging a symptom via
  /// `flowType == 'Symptom Log'` will merge the symptom into the existing event
  /// while completely preserving [flowType], [painIntensity], [clotSize], and [isFlooding].
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

    // Upsert: check if an event already exists for this date
    final existing = await (select(cycleEvents)
          ..where((t) => t.date.equals(normalizedDate))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      if (flowType == 'Symptom Log') {
        // Only update symptoms and append notes, preserving flow, pain, clots, flooding
        final mergedSymptoms = _mergeSymptoms(existing.symptoms, symptoms);
        final mergedNotes = notes != null && notes.isNotEmpty
            ? (existing.notes != null && existing.notes!.isNotEmpty
                ? '${existing.notes}\n$notes'
                : notes)
            : existing.notes;

        await (update(cycleEvents)..where((t) => t.id.equals(existing.id))).write(
          CycleEventsCompanion(
            symptoms: Value(mergedSymptoms),
            notes: Value(mergedNotes),
          ),
        );
        return;
      }

      // Existing event exists and incoming is a flow event:
      // Merge symptoms so earlier symptom logs on the same date are preserved.
      final mergedSymptoms = _mergeSymptoms(existing.symptoms, symptoms);
      final mergedNotes = notes != null && notes.isNotEmpty
          ? (existing.notes != null && existing.notes!.isNotEmpty
              ? '${existing.notes}\n$notes'
              : notes)
          : (notes ?? existing.notes);

      await (update(cycleEvents)..where((t) => t.id.equals(existing.id))).write(
        CycleEventsCompanion(
          flowType: Value(flowType),
          bloodColor: Value(bloodColor ?? existing.bloodColor),
          clotSize: Value(clotSize != 'None' ? clotSize : existing.clotSize),
          isFlooding: Value(isFlooding || existing.isFlooding),
          isTrueCycleStart: Value(isTrueCycleStart),
          painIntensity: Value(painIntensity ?? existing.painIntensity),
          painReliefTaken: Value(painReliefTaken || existing.painReliefTaken),
          symptoms: Value(mergedSymptoms),
          notes: Value(mergedNotes),
        ),
      );
    } else {
      await into(cycleEvents).insert(
        CycleEventsCompanion.insert(
          date: normalizedDate,
          flowType: flowType,
          bloodColor: Value(bloodColor),
          clotSize: Value(clotSize),
          isFlooding: Value(isFlooding),
          isTrueCycleStart: Value(isTrueCycleStart),
          painIntensity: Value(painIntensity),
          painReliefTaken: Value(painReliefTaken),
          symptoms: Value(symptoms),
          notes: Value(notes),
        ),
      );
    }
  }

  /// Log a symptom for a given date, merging with any existing event.
  Future<void> logSymptom({
    required DateTime date,
    required String symptom,
    String? notes,
  }) async {
    await logCycleEvent(
      date: date,
      flowType: 'Symptom Log',
      isTrueCycleStart: false,
      symptoms: symptom,
      notes: notes,
    );
  }

  /// Helper to merge comma-separated symptom strings without duplicates.
  static String? _mergeSymptoms(String? existingSymptoms, String? newSymptoms) {
    if (newSymptoms == null || newSymptoms.trim().isEmpty) return existingSymptoms;
    if (existingSymptoms == null || existingSymptoms.trim().isEmpty) return newSymptoms;

    final set = <String>{};
    for (final s in existingSymptoms.split(',')) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
    for (final s in newSymptoms.split(',')) {
      final trimmed = s.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
    return set.join(', ');
  }

  /// Delete a cycle event by ID.
  Future<void> deleteCycleEvent(int id) {
    return (delete(cycleEvents)..where((t) => t.id.equals(id))).go();
  }
}
