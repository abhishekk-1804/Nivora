import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imyra_app/features/today/presentation/widgets/metabolic_log_sheet.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/preferences_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MetabolicLogSheet — Widget Tests', () {
    testWidgets('Renders all fields and titles correctly', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MetabolicLogSheet(),
            ),
          ),
        ),
      );

      // Verify title & toggles
      expect(find.text('Metabolic Metrics'), findsOneWidget);
      expect(find.text('kg / cm'), findsOneWidget);

      // Verify input fields
      expect(find.widgetWithText(TextField, 'Weight (kg)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Waist (cm)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Hip (cm)'), findsOneWidget);

      // Verify chips
      expect(find.text('Dark skin patches (neck/armpits)'), findsOneWidget);
      expect(find.text('Severe Sugar Cravings'), findsOneWidget);

      // Verify Save button
      expect(find.text('Save Log'), findsOneWidget);

      await db.close();
    });

    testWidgets('Toggling unit swaps labels and clears text inputs', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MetabolicLogSheet(),
            ),
          ),
        ),
      );

      // Type some values
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '70');
      await tester.enterText(find.widgetWithText(TextField, 'Waist (cm)'), '80');
      await tester.pump();

      // Tap toggle
      await tester.tap(find.text('kg / cm'));
      await tester.pumpAndSettle();

      // Verify label change and that text is cleared
      expect(find.text('lb / in'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Weight (lb)'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Waist (in)'), findsOneWidget);

      final weightField = tester.widget<TextField>(find.widgetWithText(TextField, 'Weight (lb)'));
      expect(weightField.controller?.text, isEmpty);

      await db.close();
    });

    testWidgets('Strict validation returns error for invalid non-numeric inputs', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MetabolicLogSheet(),
            ),
          ),
        ),
      );

      // Type non-numeric text into weight
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), 'abc');
      await tester.tap(find.text('Save Log'));
      await tester.pump(const Duration(seconds: 1));

      // Verify error snackbar appears
      expect(find.text('Please enter a valid number for Weight.'), findsOneWidget);

      // Type a number into weight, but non-numeric into waist
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '70');
      await tester.enterText(find.widgetWithText(TextField, 'Waist (cm)'), 'xyz');
      await tester.tap(find.text('Save Log'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Please enter a valid number for Waist.'), findsOneWidget);

      // Type a number into waist, but non-numeric into hip
      await tester.enterText(find.widgetWithText(TextField, 'Waist (cm)'), '80');
      await tester.enterText(find.widgetWithText(TextField, 'Hip (cm)'), 'qwe');
      await tester.tap(find.text('Save Log'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Please enter a valid number for Hip.'), findsOneWidget);

      await db.close();
    });

    testWidgets('Strict validation returns error for out-of-range numeric inputs', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MetabolicLogSheet(),
            ),
          ),
        ),
      );

      // Out of range weight
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '5');
      await tester.tap(find.text('Save Log'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Weight must be between 10 kg and 500 kg.'), findsOneWidget);

      // Reset weight, out of range waist
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '70');
      await tester.enterText(find.widgetWithText(TextField, 'Waist (cm)'), '10');
      await tester.tap(find.text('Save Log'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Waist must be between 30 cm and 300 cm.'), findsOneWidget);

      await db.close();
    });

    testWidgets('Successful logging saves entry to SQLite database and dismisses', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const MetabolicLogSheet(),
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                }
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid data
      await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '75.5');
      await tester.enterText(find.widgetWithText(TextField, 'Waist (cm)'), '88');
      await tester.enterText(find.widgetWithText(TextField, 'Hip (cm)'), '102');
      
      // Tap chip
      await tester.tap(find.text('Severe Sugar Cravings'));
      await tester.pump();

      // Save
      await tester.tap(find.text('Save Log'));
      await tester.pumpAndSettle();

      // Verify MetabolicLogSheet is dismissed
      expect(find.byType(MetabolicLogSheet), findsNothing);

      // Verify DB entry exists
      final logs = await db.metabolicLogDao.getRecentLogs(DateTime.now().subtract(const Duration(minutes: 5)));
      expect(logs, hasLength(1));
      expect(logs.first.weight, equals(75.5));
      expect(logs.first.waistCircumference, equals(88.0));
      expect(logs.first.hipCircumference, equals(102.0));
      expect(logs.first.signs, contains('Severe Sugar Cravings'));

      await db.close();
    });
  });
}
