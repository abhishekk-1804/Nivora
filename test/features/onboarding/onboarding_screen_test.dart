import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imyra_app/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingScreen navigates pages and finishes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Initial page text should exist
    expect(find.textContaining('Your health.\nYour space.'), findsOneWidget);

    // Tap Next
    final nextButton = find.byKey(const ValueKey('next_row'));
    expect(nextButton, findsOneWidget);
    
    // Tap Next to go to Page 2 (Goals)
    await tester.tap(find.descendant(of: nextButton, matching: find.byType(ElevatedButton)));
    await tester.pumpAndSettle();
    expect(find.textContaining('What brings you to Imyra?'), findsOneWidget);

    // Tap Next to go to Page 3
    await tester.tap(find.descendant(of: nextButton, matching: find.byType(ElevatedButton)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Track With\nPrecision.'), findsOneWidget);

    // Tap Next to go to Page 4
    await tester.tap(find.descendant(of: nextButton, matching: find.byType(ElevatedButton)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Secured by\nBiometrics.'), findsOneWidget);

    // Get Started button should now be visible
    final getStartedButton = find.byKey(const ValueKey('get_started'));
    expect(getStartedButton, findsOneWidget);
  });
}
