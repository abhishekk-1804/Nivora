// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportController)
final reportControllerProvider = ReportControllerProvider._();

final class ReportControllerProvider
    extends $NotifierProvider<ReportController, ReportState> {
  ReportControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'reportControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$reportControllerHash();

  @$internal
  @override
  ReportController create() => ReportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportState>(value),
    );
  }
}

String _$reportControllerHash() => r'7548f85fc87992765df5f43544636b46e9f3d71a';

abstract class _$ReportController extends $Notifier<ReportState> {
  ReportState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReportState, ReportState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ReportState, ReportState>, ReportState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
