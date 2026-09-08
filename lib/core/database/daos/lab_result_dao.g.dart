// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_result_dao.dart';

// ignore_for_file: type=lint
mixin _$LabResultDaoMixin on DatabaseAccessor<AppDatabase> {
  $LabResultsTable get labResults => attachedDatabase.labResults;
  LabResultDaoManager get managers => LabResultDaoManager(this);
}

class LabResultDaoManager {
  final _$LabResultDaoMixin _db;
  LabResultDaoManager(this._db);
  $$LabResultsTableTableManager get labResults =>
      $$LabResultsTableTableManager(_db.attachedDatabase, _db.labResults);
}
