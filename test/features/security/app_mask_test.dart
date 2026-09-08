import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:imyra_app/main.dart';
import 'package:imyra_app/core/widgets/imyra_logo.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:imyra_app/core/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Shared channel mock helpers ─────────────────────────────────────────────

Future<dynamic> _noopHandler(MethodCall call) async => null;

void _mockAllPlatformChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    _noopHandler,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications#android'),
    _noopHandler,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/local_auth'),
    (MethodCall call) async {
      if (call.method == 'getAvailableBiometrics') return <String>[];
      if (call.method == 'authenticate') return true;
      return null;
    },
  );
}

void _clearAllPlatformChannels() {
  for (final name in const [
    'dexterous.com/flutter/local_notifications',
    'dexterous.com/flutter/local_notifications#android',
    'plugins.flutter.io/local_auth',
  ]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(name), null);
  }
}

// ── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUp(_mockAllPlatformChannels);
  tearDown(_clearAllPlatformChannels);

  testWidgets(
    'App obscures UI when inactive or paused to prevent screenshots',
    (tester) async {
      // Disable flutter_animate in tests to prevent infinite microtask loops
      Animate.restartOnHotReload = false;

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues(
          {'app_lock_enabled': true, 'has_onboarded': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ImyraApp(),
        ),
      );

      // ── Go inactive: privacy overlay must appear ─────────────────────────
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 1));

      expect(
        find
            .descendant(
                of: find.byType(Stack), matching: find.byType(ImyraLogo))
            .last,
        findsOneWidget,
        reason:
            'Privacy overlay with ImyraLogo must be visible when app goes inactive',
      );

      // ── Resume: backgrounded < 10 s, so no biometric prompt fires ────────
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      // flutter_animate creates repeating frame loops that break pumpAndSettle.
      // We explicitly pump through the exact timer chain instead:
      // 1. SplashScreen 2s delay
      await tester.pump(const Duration(seconds: 2));
      // 2. Navigation transition 500ms
      await tester.pump(const Duration(milliseconds: 500));
      // 3. ImyraApp authentication guard 600ms
      await tester.pump(const Duration(milliseconds: 600));
      // 4. _authenticate 500ms debounce
      await tester.pump(const Duration(milliseconds: 500));

      // Ensure all microtasks complete
      await tester.pump();

      // Replace the widget tree and dispose container so that active timers/streams are cancelled.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
