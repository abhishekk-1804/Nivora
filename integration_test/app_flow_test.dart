import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:imyra_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E Golden Path: Onboarding -> Log Event -> Generate PDF -> Erase Data', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Onboarding
    expect(find.text('Already have a backup? Restore your data'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 2. Dashboard Verification
    expect(find.text('Today'), findsOneWidget); // Navigation Bar label
    
    // 3. Data Entry (Open Quick Log Sheet)
    await tester.tap(find.byIcon(Icons.add)); // The FAB on TodayScreen
    await tester.pumpAndSettle();

    // Select tags
    expect(find.text('Medium'), findsOneWidget);
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    
    // Check if the event was logged (Snack bar might appear, or UI updates)

    // 4. Clinical Report Tab
    await tester.tap(find.byIcon(Icons.analytics_outlined));
    await tester.pumpAndSettle();

    // Tap Generate Report
    expect(find.text('Generate Doctor\'s Report (PDF)'), findsOneWidget);
    await tester.tap(find.text('Generate Doctor\'s Report (PDF)'));
    await tester.pumpAndSettle(); // This will trigger compute() and open share sheet natively

    // 5. Data Deletion
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Erase All Data on Device'));
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Erase All Data?'), findsOneWidget);
    await tester.tap(find.text('Erase'));
    await tester.pumpAndSettle();

    // Verify Success SnackBar
    expect(find.text('All data has been permanently erased.'), findsOneWidget);
  });
}
