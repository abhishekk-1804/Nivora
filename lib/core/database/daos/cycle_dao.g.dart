// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_dao.dart';

// ignore_for_file: type=lint
mixin _$CycleDaoMixin on DatabaseAccessor<AppDatabase> {
  $CycleEventsTable get cycleEvents => attachedDatabase.cycleEvents;
  CycleDaoManager get managers => CycleDaoManager(this);
}

class CycleDaoManager {
  final _$CycleDaoMixin _db;
  CycleDaoManager(this._db);
  $$CycleEventsTableTableManager get cycleEvents =>
      $$CycleEventsTableTableManager(_db.attachedDatabase, _db.cycleEvents);
}
