import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/providers/database_provider.dart';
import 'package:nivora_app/features/cycle/presentation/widgets/quick_log_sheet.dart';

Widget makeTestWidget() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      cycleDaoProvider.overrideWithValue(db.cycleDao),
    ],
    child: const MaterialApp(
      home: Scaffold(body: QuickLogSheet()),
    ),
  );
}

void main() {
  group('QuickLogSheet - form behavior', () {
    testWidgets('TC001: Sheet renders without crashing', (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      // Check that the core log action exists (Log flow button or equivalent)
      expect(find.byType(QuickLogSheet), findsOneWidget);
    });

    testWidgets('TC002: Flow type chips are visible', (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      // Spotting, Light, Medium, Heavy should be present
      expect(find.text('Spotting'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget);
    });

    testWidgets('TC003: Anovulatory option exists', (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('No bleed this month?'), findsOneWidget);
    });

    testWidgets('TC004: Common symptoms are visible when flow is selected',
        (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();

      // Tap a flow chip to enable symptom selection
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Check at least one symptom chip is present (e.g. Bloating)
      expect(find.textContaining('Bloating'), findsWidgets);
    });

    testWidgets('TC005: Pain slider is visible after selecting a flow type',
        (tester) async {
      await tester.pumpWidget(makeTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Heavy'));
      await tester.pumpAndSettle();

      // A Slider widget should appear for pain intensity
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
