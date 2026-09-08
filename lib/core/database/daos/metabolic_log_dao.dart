import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/schema_tables.dart';

part 'metabolic_log_dao.g.dart';

@DriftAccessor(tables: [MetabolicLogs])
class MetabolicLogDao extends DatabaseAccessor<AppDatabase> with _$MetabolicLogDaoMixin {
  MetabolicLogDao(super.db);

  Stream<List<MetabolicLog>> watchLogs() => (select(metabolicLogs)
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();

  Future<List<MetabolicLog>> getRecentLogs(DateTime since) => (select(metabolicLogs)
        ..where((t) => t.date.isBiggerOrEqualValue(since))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();

  Future<void> addLog({
    double? weight,
    double? waistCircumference,
    double? hipCircumference,
    String? signs,
  }) {
    return into(metabolicLogs).insert(
      MetabolicLogsCompanion.insert(
        date: DateTime.now(),
        weight: Value(weight),
        waistCircumference: Value(waistCircumference),
        hipCircumference: Value(hipCircumference),
        signs: Value(signs),
      ),
    );
  }
}
