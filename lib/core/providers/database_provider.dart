import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/cycle_dao.dart';
import '../database/daos/routine_dao.dart';
import '../database/daos/report_dao.dart';
import '../database/daos/lab_result_dao.dart';
import '../utils/date_utils.dart';

part 'database_provider.g.dart';


@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
CycleDao cycleDao(Ref ref) {
  return ref.watch(appDatabaseProvider).cycleDao;
}

@Riverpod(keepAlive: true)
RoutineDao routineDao(Ref ref) {
  return ref.watch(appDatabaseProvider).routineDao;
}

@Riverpod(keepAlive: true)
ReportDao reportDao(Ref ref) {
  return ref.watch(appDatabaseProvider).reportDao;
}

@Riverpod(keepAlive: true)
LabResultDao labResultDao(Ref ref) {
  return ref.watch(appDatabaseProvider).labResultDao;
}

// T2-1: Streams today's Symptom Log events so the energy/mood chips in the
// greeting block can restore their selected state after any Riverpod rebuild.
// Only events with flowType == 'Symptom Log' from today are returned.
// Written as a manual StreamProvider to avoid build_runner phase dependency issues
// with the drift-generated CycleEvent type.
final todaySymptomLogsProvider = StreamProvider<List<CycleEvent>>((ref) {
  final dao = ref.watch(cycleDaoProvider);
  final today = AppDateUtils.stripTime(DateTime.now());
  return dao.watchRecentEvents(limit: 50).map(
    (events) => events
        .where((e) =>
            e.flowType == 'Symptom Log' &&
            AppDateUtils.isSameDay(e.date, today))
        .toList(),
  );
});


