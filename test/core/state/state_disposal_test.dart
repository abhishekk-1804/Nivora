import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/features/today/presentation/today_controller.dart';
import 'package:imyra_app/features/cycle/presentation/cycle_controller.dart';
import 'package:imyra_app/features/report/presentation/report_controller.dart';

void main() {
  test('Erase All Data explicitly invalidates and disposes state providers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    // Read the providers to initialize them
    final todayState1 = container.read(todayControllerProvider);
    final cycleState1 = container.read(cycleControllerProvider);
    final reportState1 = container.read(reportControllerProvider);
    
    // Simulate Erase All Data transaction
    await db.transaction(() async {
      await db.delete(db.cycleEvents).go();
      await db.delete(db.routineLogs).go();
      await db.delete(db.routines).go();
      await db.delete(db.treatmentInterventions).go();
    });

    // explicitly call ref.invalidate (simulating SettingsScreen)
    container.invalidate(todayControllerProvider);
    container.invalidate(cycleControllerProvider);
    container.invalidate(reportControllerProvider);

    // Read providers again
    final todayState2 = container.read(todayControllerProvider);
    final cycleState2 = container.read(cycleControllerProvider);
    final reportState2 = container.read(reportControllerProvider);

    // After invalidation, the Riverpod container should spin up fresh states
    // The previous state instances should be disposed and unequal to the new ones
    expect(identical(todayState1, todayState2), false, reason: 'todayControllerProvider was not invalidated');
    expect(identical(cycleState1, cycleState2), false, reason: 'cycleControllerProvider was not invalidated');
    expect(identical(reportState1, reportState2), false, reason: 'reportControllerProvider was not invalidated');
  });
}
