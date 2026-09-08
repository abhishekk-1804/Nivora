// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appDatabaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'448adad5717e7b1c0b3ca3ca7e03d0b2116237af';

@ProviderFor(cycleDao)
final cycleDaoProvider = CycleDaoProvider._();

final class CycleDaoProvider
    extends $FunctionalProvider<CycleDao, CycleDao, CycleDao>
    with $Provider<CycleDao> {
  CycleDaoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cycleDaoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cycleDaoHash();

  @$internal
  @override
  $ProviderElement<CycleDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CycleDao create(Ref ref) {
    return cycleDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CycleDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CycleDao>(value),
    );
  }
}

String _$cycleDaoHash() => r'65772a7c7125448d48af9da7aee77a34daefb0ce';

@ProviderFor(routineDao)
final routineDaoProvider = RoutineDaoProvider._();

final class RoutineDaoProvider
    extends $FunctionalProvider<RoutineDao, RoutineDao, RoutineDao>
    with $Provider<RoutineDao> {
  RoutineDaoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'routineDaoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$routineDaoHash();

  @$internal
  @override
  $ProviderElement<RoutineDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoutineDao create(Ref ref) {
    return routineDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutineDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutineDao>(value),
    );
  }
}

String _$routineDaoHash() => r'01cbaba76e9868be55b08924c4d2469faddca2d1';

@ProviderFor(reportDao)
final reportDaoProvider = ReportDaoProvider._();

final class ReportDaoProvider
    extends $FunctionalProvider<ReportDao, ReportDao, ReportDao>
    with $Provider<ReportDao> {
  ReportDaoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'reportDaoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$reportDaoHash();

  @$internal
  @override
  $ProviderElement<ReportDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReportDao create(Ref ref) {
    return reportDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportDao>(value),
    );
  }
}

String _$reportDaoHash() => r'8571697dddfbd65740c81b4243acd080894d8483';

@ProviderFor(labResultDao)
final labResultDaoProvider = LabResultDaoProvider._();

final class LabResultDaoProvider
    extends $FunctionalProvider<LabResultDao, LabResultDao, LabResultDao>
    with $Provider<LabResultDao> {
  LabResultDaoProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'labResultDaoProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$labResultDaoHash();

  @$internal
  @override
  $ProviderElement<LabResultDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LabResultDao create(Ref ref) {
    return labResultDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabResultDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabResultDao>(value),
    );
  }
}

String _$labResultDaoHash() => r'd29173d2ca99aacbb40a6727a32d30d1a55e775e';
