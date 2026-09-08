import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/snackbar_utils.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class FeedbackService {
  static Future<void> sendFeedback({
    required BuildContext context,
    required String category,
    required String feedbackText,
    required bool includeDiagnostics,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final String appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    
    String osInfo = Platform.operatingSystem;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osInfo = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt}) - ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osInfo = 'iOS ${iosInfo.systemVersion} - ${iosInfo.utsname.machine}';
      }
    } catch (_) {
      // Fallback
    }

    final String timezone = DateTime.now().timeZoneName;

    String body = '''
--- User Feedback ---
$feedbackText

''';

    if (includeDiagnostics) {
      body += '''
--- Diagnostic Info ---
App Version: $appVersion
OS: $osInfo
Device Timezone: $timezone
''';
    }

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'susmitadeybusiness@gmail.com',
      queryParameters: {
        'subject': '[Imyra Feedback] $category - v$appVersion',
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: body));
        if (!context.mounted) return;
        SnackbarUtils.show(
          context: context,
          title: 'Feedback Copied',
          message: 'Could not open email client. Feedback copied to clipboard.',
          contentType: ContentType.warning,
        );
      }
    }
  }
}
