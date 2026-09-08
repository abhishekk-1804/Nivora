// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metabolic_log_dao.dart';

// ignore_for_file: type=lint
mixin _$MetabolicLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $MetabolicLogsTable get metabolicLogs => attachedDatabase.metabolicLogs;
  MetabolicLogDaoManager get managers => MetabolicLogDaoManager(this);
}

class MetabolicLogDaoManager {
  final _$MetabolicLogDaoMixin _db;
  MetabolicLogDaoManager(this._db);
  $$MetabolicLogsTableTableManager get metabolicLogs =>
      $$MetabolicLogsTableTableManager(_db.attachedDatabase, _db.metabolicLogs);
}
