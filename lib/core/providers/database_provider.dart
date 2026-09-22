import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/cycle_dao.dart';
import '../database/daos/routine_dao.dart';
import '../database/daos/report_dao.dart';
import '../database/daos/lab_result_dao.dart';
import '../utils/date_utils.dart';

import '../database/daos/clinical_profile_dao.dart';
import '../database/daos/metabolic_log_dao.dart';

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

@Riverpod(keepAlive: true)
ClinicalProfileDao clinicalProfileDao(Ref ref) {
  return ref.watch(appDatabaseProvider).clinicalProfileDao;
}

@Riverpod(keepAlive: true)
MetabolicLogDao metabolicLogDao(Ref ref) {
  return ref.watch(appDatabaseProvider).metabolicLogDao;
}

// T2-1: Streams today's Symptom Log events so the energy/mood chips in the
// greeting block can restore their selected state after any Riverpod rebuild.
// Returns any event logged for today that includes recorded symptoms.
// Written as a manual StreamProvider to avoid build_runner phase dependency issues
// with the drift-generated CycleEvent type.
final todaySymptomLogsProvider = StreamProvider<List<CycleEvent>>((ref) {
  final dao = ref.watch(cycleDaoProvider);
  final today = AppDateUtils.stripTime(DateTime.now());
  return dao.watchRecentEvents(limit: 50).map(
    (events) => events
        .where((e) =>
            (e.symptoms != null && e.symptoms!.isNotEmpty) &&
            AppDateUtils.isSameDay(e.date, today))
        .toList(),
  );
});


