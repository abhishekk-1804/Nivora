import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/schema_tables.dart';
import 'daos/cycle_dao.dart';
import 'daos/routine_dao.dart';
import 'daos/report_dao.dart';
import 'daos/lab_result_dao.dart';
import 'daos/clinical_profile_dao.dart';
import 'daos/metabolic_log_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CycleEvents, Routines, RoutineLogs, TreatmentInterventions, LabResults, ClinicalProfile, MetabolicLogs],
  daos: [CycleDao, RoutineDao, ReportDao, LabResultDao, ClinicalProfileDao, MetabolicLogDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Used for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(cycleEvents, cycleEvents.isTrueCycleStart);
            await m.addColumn(cycleEvents, cycleEvents.painReliefStatus);
            await m.createTable(treatmentInterventions);
          }
          if (from < 3) {
            // Use raw SQL to avoid Column<T> vs GeneratedColumn<Object>
            // type mismatches that occur before build_runner regenerates .g.dart.
            // SQLite stores Dart bool as INTEGER (0 = false, 1 = true).
            await customStatement(
              'ALTER TABLE cycle_events ADD COLUMN pain_intensity INTEGER',
            );
            await customStatement(
              'ALTER TABLE cycle_events ADD COLUMN pain_relief_taken INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (from < 4) {
            await m.createTable(labResults);
            await customStatement(
              'ALTER TABLE routines ADD COLUMN dose TEXT',
            );
            await customStatement(
              'ALTER TABLE routines ADD COLUMN notes TEXT',
            );
          }
          if (from < 5) {
            await m.createTable(clinicalProfile);
            await m.createTable(metabolicLogs);
          }
          if (from < 6) {
            await m.addColumn(routines, routines.endDate);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'Ila_health.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

