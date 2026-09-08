import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ErrorLogger {
  static const int _maxLines = 500;
  static const String _fileName = 'Ila_diagnostics.log';

  static List<String> _activeRoutineNames = [];

  static void setRoutineNames(List<String> names) {
    _activeRoutineNames = names;
  }

  /// Ensure we don't log health data by replacing obvious patterns
  /// (In a real clinical app, this sanitization would be far more robust)
  static String _sanitize(String message) {
    String sanitized = message
        .replaceAll(RegExp(r'\d{4}-\d{2}-\d{2}'), '[DATE_REDACTED]')
        .replaceAll(RegExp(r'\b(?:spotting|heavy|medium|light|cramps|clots|flooding)\b', caseSensitive: false), '[CLINICAL_TERM_REDACTED]')
        .replaceAll(RegExp(r'\b(?:medroxyprogesterone|pill|medication)\b', caseSensitive: false), '[MED_TERM_REDACTED]');
    
    for (final name in _activeRoutineNames) {
      if (name.isNotEmpty) {
        sanitized = sanitized.replaceAll(RegExp(RegExp.escape(name), caseSensitive: false), '[ROUTINE_NAME_REDACTED]');
      }
    }
    return sanitized;
  }

  static Future<File> _getLogFile() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  static Future<void> _writeLine(String level, String message, [dynamic error, StackTrace? stackTrace]) async {
    try {
      final file = await _getLogFile();
      final now = DateTime.now().toIso8601String();
      final sanitizedMessage = _sanitize(message);
      
      String logEntry = '[$now] [$level] $sanitizedMessage';
      if (error != null) {
        logEntry += '\nError: $error';
      }
      if (stackTrace != null) {
        // Only take top 3 lines of stack trace to prevent log flooding
        final shortStack = stackTrace.toString().split('\n').take(3).join('\n');
        logEntry += '\nStack:\n$shortStack';
      }

      // Read existing lines to implement FIFO rotation
      List<String> lines = await file.readAsLines();
      lines.add(logEntry);
      
      if (lines.length > _maxLines) {
        lines = lines.sublist(lines.length - _maxLines);
      }
      
      await file.writeAsString('${lines.join('\n')}\n', mode: FileMode.write);
    } catch (e) {
      // Fail silently if logger fails
      debugPrint('Logger failed: $e');
    }
  }

  static void info(String message) {
    // Fire and forget
    _writeLine('INFO', message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Fire and forget
    _writeLine('ERROR', message, error, stackTrace);
  }

  static Future<String> getSanitizedLogs() async {
    try {
      final file = await _getLogFile();
      return await file.readAsString();
    } catch (e) {
      return 'Error retrieving logs: $e';
    }
  }

  static Future<void> clearLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Clear logs failed: $e');
    }
  }
}

