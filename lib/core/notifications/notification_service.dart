import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // requestAlertPermission: false — onboarding owns the first-time system prompt.
    // We only initialise here; the user explicitly grants permission on page 2 of onboarding.
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // NOTE: We intentionally do NOT call requestNotificationsPermission() here.
    // The onboarding screen is the single, intentional first-ask for permissions.
  }

  /// Checks whether notifications are currently enabled on this device.
  /// Returns false if the platform implementation is unavailable.
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      // requestPermissions with no-op booleans acts as a status check on iOS.
      // If permissions were already granted, returns true; denied returns false.
      return await iosImpl?.requestPermissions(alert: false, badge: false, sound: false) ?? false;
    }
    return false;
  }

  /// Requests notification permission from the OS.
  /// Returns true if the user granted permission.
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosImpl?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  static Future<void> scheduleRoutineReminder({
    required int routineId,
    required String routineName,
    required int hour,
    required int minute,
    required String regimenType,
    required DateTime startDate,
    int activeDays = 21,
    int breakDays = 7,
  }) async {
    // Cancel any previous single or windowed notifications for this routine
    await _notificationsPlugin.cancel(id: routineId);
    for (int i = 0; i < 30; i++) {
      await _notificationsPlugin.cancel(id: routineId * 1000 + i);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'Ila_routine_channel',
      'Routine Reminders',
      channelDescription: 'Neutral daily reminders for your routines',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    if (regimenType == 'Daily') {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Consumes only 1 slot and repeats forever
      await _notificationsPlugin.zonedSchedule(
        id: routineId,
        title: 'Imyra',
        body: 'Time for your scheduled routine.',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      // Moving Window Logic for non-daily (Cyclic)
      // We only schedule the next 14 active days to avoid hitting the iOS 64-notification limit
      final now = DateTime.now();
      final totalCycleLength = activeDays + breakDays;
      int scheduledCount = 0;
      final startMidnight = DateTime(startDate.year, startDate.month, startDate.day);

      // Scan up to 30 days ahead, schedule up to 14 active notifications
      for (int i = 0; i < 30; i++) {
        if (scheduledCount >= 14) break;
        
        final targetDate = now.add(Duration(days: i));
        final targetMidnight = DateTime(targetDate.year, targetDate.month, targetDate.day);
        
        if (targetMidnight.isBefore(startMidnight)) continue;
        
        final daysSinceStart = targetMidnight.difference(startMidnight).inDays;
        final dayInCycle = daysSinceStart % totalCycleLength;

        // If it's an active day, schedule it
        if (dayInCycle < activeDays) {
          final scheduledDate = tz.TZDateTime(
              tz.local, targetDate.year, targetDate.month, targetDate.day, hour, minute);
              
          if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
            await _notificationsPlugin.zonedSchedule(
              id: routineId * 1000 + scheduledCount,
              title: 'Imyra',
              body: 'Time for your scheduled routine.',
              scheduledDate: scheduledDate,
              notificationDetails: platformDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            scheduledCount++;
          }
        }
      }
    }
  }

  /// Call this when the app is foregrounded to rebuild the 14-day window
  static Future<void> rehydrateRoutineNotifications(List<dynamic> routines) async {
    for (final routine in routines) {
      if (routine.isActive) {
        final timeParts = routine.reminderTime.split(':');
        final hour = int.tryParse(timeParts[0]) ?? 9;
        final minute = int.tryParse(timeParts[1]) ?? 0;

        await scheduleRoutineReminder(
          routineId: routine.id,
          routineName: routine.name,
          hour: hour,
          minute: minute,
          regimenType: routine.regimenType,
          startDate: routine.startDate,
          activeDays: routine.activeDays,
          breakDays: routine.breakDays,
        );
      }
    }
  }
}
