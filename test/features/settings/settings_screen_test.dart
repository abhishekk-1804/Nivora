import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nivora_app/features/settings/presentation/settings_screen.dart';
import 'package:nivora_app/core/providers/preferences_provider.dart';
import 'package:nivora_app/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Nivora',
      packageName: 'com.nivora.health',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
  });

  testWidgets('SettingsScreen displays correctly', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify headers
    expect(find.text('Account & Security'), findsOneWidget);
    expect(find.text('Data & Privacy'), findsOneWidget);
    expect(find.text('Clinical Profile'), findsOneWidget);
    
    // Verify specific toggles exist
    expect(find.text('Biometric App Lock'), findsOneWidget);
    expect(find.text('Erase All Data on Device'), findsOneWidget);
  });
}
