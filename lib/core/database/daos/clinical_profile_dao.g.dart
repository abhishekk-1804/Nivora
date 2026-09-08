// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinical_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$ClinicalProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $ClinicalProfileTable get clinicalProfile => attachedDatabase.clinicalProfile;
  ClinicalProfileDaoManager get managers => ClinicalProfileDaoManager(this);
}

class ClinicalProfileDaoManager {
  final _$ClinicalProfileDaoMixin _db;
  ClinicalProfileDaoManager(this._db);
  $$ClinicalProfileTableTableManager get clinicalProfile =>
      $$ClinicalProfileTableTableManager(
          _db.attachedDatabase, _db.clinicalProfile);
}
