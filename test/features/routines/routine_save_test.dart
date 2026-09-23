import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:nivora_app/core/database/app_database.dart';
import 'package:nivora_app/core/providers/database_provider.dart';
import 'package:nivora_app/features/routines/presentation/routine_setup_sheet.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Widget makeTestWidget({Routine? routine, AppDatabase? db}) {
  final database = db ?? AppDatabase.forTesting(NativeDatabase.memory());
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      routineDaoProvider.overrideWithValue(database.routineDao),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: RoutineSetupSheet(routine: routine),
      ),
    ),
  );
}

class MockFlutterLocalNotificationsPlugin extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    String? payload,
    dynamic matchDateTimeComponents,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));
  FlutterLocalNotificationsPlatform.instance = MockFlutterLocalNotificationsPlugin();
  
  const MethodChannel channel = MethodChannel('dexterous.com/flutter/local_notifications');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return null;
  });

  group('RoutineSetupSheet - Save Logic', () {
    testWidgets('TC-R03: Saves new routine to database', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(makeTestWidget(db: db));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'New Med');
      await tester.pumpAndSettle();
      
      final saveBtn = find.text('Save Medication');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      
      final routines = await db.routineDao.getActiveRoutines();
      expect(routines.length, 1);
      expect(routines.first.name, 'New Med');
      
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await db.close();
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
