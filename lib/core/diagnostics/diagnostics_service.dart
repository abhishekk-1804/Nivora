import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'error_logger.dart';

class DiagnosticsService {
  static Future<String> compileReport(String? userFeedback, String? category, bool includeDiagnostics) async {
    final buffer = StringBuffer();
    buffer.writeln('=== Imyra TEST FEEDBACK ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    if (userFeedback != null && userFeedback.isNotEmpty) {
      buffer.writeln('--- USER FEEDBACK ---');
      buffer.writeln('Category: ${category ?? 'General'}');
      buffer.writeln(userFeedback);
      buffer.writeln('');
    }

    if (includeDiagnostics) {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      String osInfo = 'Unknown OS';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osInfo = 'iOS ${iosInfo.systemVersion} (${iosInfo.model})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osInfo = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        osInfo = 'Windows ${winInfo.majorVersion}.${winInfo.minorVersion} (Build ${winInfo.buildNumber})';
      }

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      bool? hasNotifPermission;
      if (Platform.isIOS) {
        hasNotifPermission = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isAndroid) {
        hasNotifPermission = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
      }

      final logs = await ErrorLogger.getSanitizedLogs();
      final logLines = logs.split('\n');
      final recentLogs = logLines.length > 100 
          ? logLines.sublist(logLines.length - 100).join('\n') 
          : logs;

      buffer.writeln('--- SYSTEM INFO ---');
      buffer.writeln('App Version: ${packageInfo.version}+${packageInfo.buildNumber}');
      buffer.writeln('OS: $osInfo');
      buffer.writeln('Schema Version: 1');
      buffer.writeln('Notifications Enabled: ${hasNotifPermission ?? 'Unknown'}');
      buffer.writeln('');
      buffer.writeln('--- RECENT SANITIZED LOGS ---');
      buffer.writeln(recentLogs);
    }
    
    buffer.writeln('===============================');

    return buffer.toString();
  }

  static Future<void> exportDiagnosticsPackage({String? userFeedback, String? category, bool includeDiagnostics = true}) async {
    try {
      final reportContent = await compileReport(userFeedback, category, includeDiagnostics);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Ila_diagnostic_report.txt');
      await file.writeAsString(reportContent);

      final subject = '[Imyra Test Feedback] - ${category ?? 'Diagnostics'}';
      
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: 'Attached is the Imyra test diagnostic report.',
      );
    } catch (e) {
      ErrorLogger.error('Failed to export diagnostics package', e);
    }
  }
}

