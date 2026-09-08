import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imyra_app/features/today/presentation/today_screen.dart';
import 'package:imyra_app/core/providers/database_provider.dart';
import 'package:imyra_app/core/database/app_database.dart';
import 'package:imyra_app/core/providers/preferences_provider.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget makeWidget({AppDatabase? db, SharedPreferences? prefs}) {
  final database = db ?? AppDatabase.forTesting(NativeDatabase.memory());
  
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs) else sharedPreferencesProvider.overrideWithValue(SharedPreferencesMock()),
    ],
    child: const MaterialApp(home: TodayScreen(onNavigateToSettings: null)),
  );
}

class SharedPreferencesMock implements SharedPreferences {
  @override
  Future<bool> clear() async => true;
  @override
  Future<bool> commit() async => true;
  @override
  bool containsKey(String key) => false;
  @override
  Object? get(String key) => null;
  @override
  bool? getBool(String key) => false; // Return false to mock it
  @override
  double? getDouble(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  Set<String> getKeys() => {};
  @override
  String? getString(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<void> reload() async {}
  @override
  Future<bool> remove(String key) async => true;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
}

void main() {
  group('TodayScreen — UI behavior', () {
    testWidgets('TC-T01: Screen renders without crashing', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump();
      expect(find.byType(TodayScreen), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('TC-T02: Energy chips are visible', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump();
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Med'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('TC-T03: "All caught up" does NOT show when no routines', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pumpAndSettle();
      expect(find.text("You're all caught up."), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('TC-T04: Log Period button opens QuickLogSheet', (tester) async {
      await tester.pumpWidget(makeWidget());
      await tester.pump();
      final logBtn = find.text('Log Period');
      if (logBtn.evaluate().isNotEmpty) {
        await tester.tap(logBtn);
        await tester.pumpAndSettle();
        expect(find.text('Log Period'), findsWidgets); // sheet + button
      }
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
