import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imyra_app/features/today/presentation/widgets/clinical_log_sheet.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/preferences_provider.dart';
import 'package:imyra_app/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClinicalLogSheet — Widget Tests', () {
    testWidgets('Renders all tabs and forms correctly', (tester) async {
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
            home: Scaffold(
              body: ClinicalLogSheet(),
            ),
          ),
        ),
      );

      // Verify title
      expect(find.text('Clinical & Medical Logs'), findsOneWidget);

      // Verify Tabs exist
      expect(find.text('Lab Results'), findsOneWidget);
      expect(find.text('Treatments'), findsOneWidget);
      expect(find.text('Profile / PCOM'), findsOneWidget);

      // Initially on Lab Results tab
      expect(find.widgetWithText(TextField, 'Value (e.g. 12.4 uIU/mL, 85 ng/dL)'), findsOneWidget);

      await db.close();
    });

    testWidgets('Deselecting / selecting tabs works', (tester) async {
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
            home: Scaffold(
              body: ClinicalLogSheet(),
            ),
          ),
        ),
      );

      // Switch to Treatments tab
      await tester.tap(find.text('Treatments'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Treatment/Intervention Title (e.g. Started Metformin 500mg)'), findsOneWidget);

      // Switch to Profile / PCOM tab
      await tester.tap(find.text('Profile / PCOM'));
      await tester.pumpAndSettle();

      expect(find.text('Ultrasound Confirmed PCOM'), findsOneWidget);

      await db.close();
    });

    testWidgets('Save Lab Result validates empty input and saves valid data', (tester) async {
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
            home: Scaffold(
              body: ClinicalLogSheet(),
            ),
          ),
        ),
      );

      // Trigger empty save
      await tester.tap(find.text('Save Lab Result'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter a test value (e.g. 14.2 uIU/mL)'), findsOneWidget);

      // Enter valid data
      await tester.enterText(find.widgetWithText(TextField, 'Value (e.g. 12.4 uIU/mL, 85 ng/dL)'), '15.0 uIU/mL');
      await tester.enterText(find.widgetWithText(TextField, 'Notes (optional)'), 'Routine checkup');
      await tester.tap(find.text('Save Lab Result'));
      await tester.pumpAndSettle();

      // Verify db insertion
      final results = await db.select(db.labResults).get();
      expect(results, hasLength(1));
      expect(results.first.testName, equals('Fasting Insulin'));
      expect(results.first.value, equals('15.0 uIU/mL'));
      expect(results.first.notes, equals('Routine checkup'));

      await db.close();
    });

    testWidgets('Save Treatment Intervention validates and saves', (tester) async {
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
            home: Scaffold(
              body: ClinicalLogSheet(),
            ),
          ),
        ),
      );

      // Go to treatments tab
      await tester.tap(find.text('Treatments'));
      await tester.pumpAndSettle();

      // Trigger empty save
      await tester.tap(find.text('Record Intervention'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Please enter a treatment title (e.g. Started Metformin)'), findsOneWidget);

      // Enter valid data
      await tester.enterText(find.widgetWithText(TextField, 'Treatment/Intervention Title (e.g. Started Metformin 500mg)'), 'Metformin 500mg');
      await tester.enterText(find.widgetWithText(TextField, 'Notes/Dose details (optional)'), 'Daily with dinner');
      await tester.tap(find.text('Record Intervention'));
      await tester.pumpAndSettle();

      // Verify db insertion
      final list = await db.select(db.treatmentInterventions).get();
      expect(list, hasLength(1));
      expect(list.first.title, equals('Metformin 500mg'));
      expect(list.first.notes, equals('Daily with dinner'));

      await db.close();
    });

    testWidgets('Update Clinical Profile saves profile updates', (tester) async {
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
            home: Scaffold(
              body: ClinicalLogSheet(),
            ),
          ),
        ),
      );

      // Go to profile tab
      await tester.tap(find.text('Profile / PCOM'));
      await tester.pumpAndSettle();

      // Toggle PCOM Switch
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Select phenotype
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phenotype A (Classic)').last);
      await tester.pumpAndSettle();

      // Save profile
      await tester.tap(find.text('Update Clinical Profile'));
      await tester.pumpAndSettle();

      // Verify db entry
      final profile = await db.clinicalProfileDao.getProfile();
      expect(profile, isNotNull);
      expect(profile!.hasPCOM, isTrue);
      expect(profile.phenotype, equals('A'));

      await db.close();
    });
  });
}
