import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imyra_app/features/splash/presentation/splash_screen.dart';
import 'package:imyra_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:imyra_app/main.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/preferences_provider.dart';
import 'package:imyra_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

void main() {
  setUp(() {
    _mockAllPlatformChannels();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Imyra',
      packageName: 'com.dexterous.imyra',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
  });

  tearDown(() {
    _clearAllPlatformChannels();
  });

  group('SplashScreen — Widget Tests', () {
    testWidgets('Renders splash screen assets and text correctly', (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SplashScreen(),
          ),
        ),
      );

      // Verify the logo exists
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('imyra health'), findsOneWidget);

      // Pump duration to clear pending splash hold timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Navigates to OnboardingScreen when has_onboarded is false', (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({'has_onboarded': false});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SplashScreen(),
          ),
        ),
      );

      // Verify it's on splash screen initially
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Fast forward the 2-second hold time
      await tester.pump(const Duration(seconds: 2));
      // Fast forward the transition time (500ms)
      await tester.pump(const Duration(milliseconds: 500));
      // Trigger any other microtasks
      await tester.pump();

      // Verify navigation to OnboardingScreen
      expect(find.byType(OnboardingScreen), findsOneWidget);

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Navigates to MainNavigation when has_onboarded is true', (WidgetTester tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      // Set seen_today_guide to true to prevent dialog popup during today screen load
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'seen_today_guide': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SplashScreen(),
          ),
        ),
      );

      // Verify it's on splash screen initially
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(MainNavigation), findsNothing);

      // Fast forward the 2-second hold time
      await tester.pump(const Duration(seconds: 2));
      // Fast forward the transition time (500ms)
      await tester.pump(const Duration(milliseconds: 500));
      // Trigger any other microtasks
      await tester.pump();

      // Verify navigation to MainNavigation
      expect(find.byType(MainNavigation), findsOneWidget);

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
