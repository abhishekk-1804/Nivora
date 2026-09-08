import 'package:drift/drift.dart';
import '../tables/schema_tables.dart';
import '../app_database.dart';
import '../../utils/date_utils.dart';

part 'lab_result_dao.g.dart';

@DriftAccessor(tables: [LabResults])
class LabResultDao extends DatabaseAccessor<AppDatabase> with _$LabResultDaoMixin {
  LabResultDao(super.db);

  /// Get all lab results, ordered by date DESC.
  Stream<List<LabResult>> watchLabResults() {
    return (select(labResults)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  /// Insert a new lab result.
  Future<int> insertLabResult({
    required DateTime date,
    required String testName,
    required String value,
    String? notes,
  }) async {
    return into(labResults).insert(
      LabResultsCompanion.insert(
        date: AppDateUtils.stripTime(date),
        testName: testName,
        value: value,
        notes: Value(notes),
      ),
    );
  }

  /// Delete a lab result by ID.
  Future<void> deleteLabResult(int id) {
    return (delete(labResults)..where((t) => t.id.equals(id))).go();
  }
}
