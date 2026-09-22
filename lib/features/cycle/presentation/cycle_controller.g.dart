// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CycleController)
final cycleControllerProvider = CycleControllerProvider._();

final class CycleControllerProvider
    extends $StreamNotifierProvider<CycleController, CycleState> {
  CycleControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cycleControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cycleControllerHash();

  @$internal
  @override
  CycleController create() => CycleController();
}

String _$cycleControllerHash() => r'52619d5f8c9884892e5ffae97e460cdd1892d4fd';

abstract class _$CycleController extends $StreamNotifier<CycleState> {
  Stream<CycleState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CycleState>, CycleState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CycleState>, CycleState>,
        AsyncValue<CycleState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
