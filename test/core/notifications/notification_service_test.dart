import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:nivora_app/core/notifications/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RecordedScheduleCall {
  final int id;
  final String? title;
  final String? body;
  final dynamic scheduledDate;
  final String? payload;
  final dynamic matchDateTimeComponents;

  RecordedScheduleCall({
    required this.id,
    this.title,
    this.body,
    this.scheduledDate,
    this.payload,
    this.matchDateTimeComponents,
  });
}

class MockFlutterLocalNotificationsPlugin extends FlutterLocalNotificationsPlatform {
  final List<int> cancelledIds = [];
  final List<RecordedScheduleCall> scheduledCalls = [];

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    String? payload,
    dynamic matchDateTimeComponents,
  }) async {
    scheduledCalls.add(
      RecordedScheduleCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      ),
    );
  }
}

class MockRoutine {
  final int id;
  final String name;
  final String regimenType;
  final String reminderTime;
  final DateTime startDate;
  final int activeDays;
  final int breakDays;
  final bool isActive;

  MockRoutine({
    required this.id,
    required this.name,
    required this.regimenType,
    required this.reminderTime,
    required this.startDate,
    this.activeDays = 21,
    this.breakDays = 7,
    this.isActive = true,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    FlutterLocalNotificationsPlatform.instance = mockPlugin;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('NotificationService — Deterministic Scheduling & Privacy Audit', () {
    test('Daily routine scheduling uses neutral privacy-preserving text and daily match', () async {
      final startDate = DateTime.now().subtract(const Duration(days: 5));

      await NotificationService.scheduleRoutineReminder(
        routineId: 42,
        routineName: 'Metformin 500mg',
        hour: 9,
        minute: 30,
        regimenType: 'Daily',
        startDate: startDate,
      );

      // Verify cancellation of prior notifications occurred first
      expect(mockPlugin.cancelledIds.contains(42), isTrue);

      // Verify zonedSchedule was called once for Daily
      expect(mockPlugin.scheduledCalls.length, equals(1));

      final call = mockPlugin.scheduledCalls.first;
      expect(call.id, equals(42));
      // Must NOT leak medication name in notification title or body on lockscreen
      expect(call.title, equals('Nivora'));
      expect(call.body, equals('Time for your scheduled routine.'));
      expect(call.matchDateTimeComponents, equals(DateTimeComponents.time));
    });

    test('Cyclic 21/7 regimen schedules only active days within moving window', () async {
      mockPlugin.scheduledCalls.clear();
      mockPlugin.cancelledIds.clear();

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);

      await NotificationService.scheduleRoutineReminder(
        routineId: 101,
        routineName: 'Combined Oral Contraceptive',
        hour: 20,
        minute: 0,
        regimenType: 'Cyclic_21_7',
        startDate: startDate,
        activeDays: 21,
        breakDays: 7,
      );

      expect(mockPlugin.scheduledCalls.isNotEmpty, isTrue);
      // Moving window limits to 14 active days maximum
      expect(mockPlugin.scheduledCalls.length, lessThanOrEqualTo(14));

      for (final call in mockPlugin.scheduledCalls) {
        expect(call.title, equals('Nivora'));
        expect(call.body, equals('Time for your scheduled routine.'));
      }
    });

    test('rehydrateRoutineNotifications correctly parses times and filters inactive routines', () async {
      mockPlugin.scheduledCalls.clear();
      mockPlugin.cancelledIds.clear();

      final routines = [
        MockRoutine(
          id: 1,
          name: 'Active Daily Routine',
          regimenType: 'Daily',
          reminderTime: '08:15',
          startDate: DateTime.now(),
          isActive: true,
        ),
        MockRoutine(
          id: 2,
          name: 'Inactive Routine',
          regimenType: 'Daily',
          reminderTime: '12:00',
          startDate: DateTime.now(),
          isActive: false,
        ),
      ];

      await NotificationService.rehydrateRoutineNotifications(routines);

      // Only routine 1 should have been scheduled
      expect(mockPlugin.scheduledCalls.length, equals(1));
      expect(mockPlugin.scheduledCalls.first.id, equals(1));
    });
  });
}
