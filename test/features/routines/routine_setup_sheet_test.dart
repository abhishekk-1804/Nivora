import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/providers/database_provider.dart';
import 'package:nivora_app/features/routines/presentation/routine_setup_sheet.dart';

Widget makeTestWidget({Routine? routine}) {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      routineDaoProvider.overrideWithValue(db.routineDao),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RoutineSetupSheet(routine: routine),
      ),
    ),
  );
}

void main() {
  group('RoutineSetupSheet — form behavior', () {
    testWidgets('TC001: Shows "Add Medication" title in add mode',
        (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Add Medication'), findsOneWidget);
    });

    testWidgets('TC002: Shows "Edit Medication" title in edit mode',
        (tester) async {
      final routine = Routine(
        id: 1,
        name: 'Metformin',
        regimenType: 'Daily',
        activeDays: 21,
        breakDays: 7,
        startDate: DateTime.now(),
        reminderTime: '08:00',
        isActive: true,
        dose: null,
        notes: null,
        endDate: null,
      );
      await tester.pumpWidget(makeTestWidget(routine: routine));
      await tester.pumpAndSettle();
      expect(find.text('Edit Medication'), findsOneWidget);
    });

    testWidgets('TC003: Edit mode pre-fills name from existing routine',
        (tester) async {
      final routine = Routine(
        id: 1,
        name: 'Inositol',
        regimenType: 'Daily',
        activeDays: 21,
        breakDays: 7,
        startDate: DateTime.now(),
        reminderTime: '20:00',
        isActive: true,
        dose: '2g',
        notes: null,
        endDate: null,
      );
      await tester.pumpWidget(makeTestWidget(routine: routine));
      await tester.pumpAndSettle();
      final nameField = find.widgetWithText(TextField, 'Inositol');
      expect(nameField, findsOneWidget);
    });

    testWidgets('TC004: Both schedule radio tiles are visible', (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Standard 21/7 Regimen'), findsOneWidget);
      expect(find.text('Continuous Daily'), findsOneWidget);
    });

    testWidgets('TC005: Save button exists and is labeled correctly',
        (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Save Medication'), findsOneWidget);
    });

    testWidgets('TC006: Duration dropdown shows all options', (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      
      final dropdown = find.byType(DropdownButton<String>);
      // Scroll to the dropdown since it might be off-screen
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      
      // Open the dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      
      expect(find.text('Indefinite'), findsWidgets);
      expect(find.text('1 Month').last, findsOneWidget);
      expect(find.text('3 Months').last, findsOneWidget);
      expect(find.text('6 Months').last, findsOneWidget);
      expect(find.text('Custom').last, findsOneWidget);
    });
  });
}
