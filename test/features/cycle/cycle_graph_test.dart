import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/features/cycle/presentation/widgets/cycle_graph.dart';

void main() {
  testWidgets('CycleGraph renders normally for a 28-day cycle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CycleGraph(currentDay: 28),
        ),
      ),
    );

    // Verify it renders the day
    expect(find.text('Day 28'), findsOneWidget);
    // Verify badge does NOT exist
    expect(find.text('Extended Cycle (>45d)'), findsNothing);
  });

  testWidgets('CycleGraph triggers PCOS guardrail for a 120-day cycle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CycleGraph(currentDay: 120),
        ),
      ),
    );

    // Let the flutter_animate animations finish
    await tester.pumpAndSettle();

    // Verify it renders the actual day text
    expect(find.text('Day 120'), findsOneWidget);
    // Verify the PCOS badge exists
    expect(find.text('Extended Cycle (>45d)'), findsOneWidget);
  });
}
