// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabToday => 'Today';

  @override
  String get tabInsights => 'Insights';

  @override
  String get tabSanctuary => 'Sanctuary';

  @override
  String get greetingEvening => 'Good evening.';

  @override
  String get logCycle => 'Log Cycle';

  @override
  String cycleDay(int day) {
    return 'Day $day';
  }

  @override
  String get catchUpTitle => 'Catch Up';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusTaken => 'Taken';

  @override
  String get setupRoutinePrompt => 'Set up a medication routine';

  @override
  String medicinePhaseLabel(int day, int total) {
    return 'Medicine · Day $day / $total';
  }

  @override
  String breakPhaseLabel(int day, int total) {
    return 'Treatment Break · Day $day / $total';
  }

  @override
  String get noMedicationRequired => 'No medication required today.';

  @override
  String scheduledFor(String time) {
    return 'Scheduled for $time';
  }

  @override
  String takenAt(String time) {
    return 'Taken at $time';
  }

  @override
  String get markAsTaken => 'Mark as Taken';

  @override
  String get cycleLogTitle => 'Cycle Log';

  @override
  String currentlyOnDay(int day) {
    return 'Currently on Day $day';
  }

  @override
  String get tapToLogPeriod => 'Tap to log your period';

  @override
  String get allCaughtUp => 'You\'re all caught up.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDataPrivacy => 'Data & Privacy';

  @override
  String get settingsOfflineBadge => '100% Offline Device. Zero cloud servers.';

  @override
  String get settingsExportBackup => 'Export Encrypted Backup';

  @override
  String get settingsExportBackupDesc =>
      'Save your data locally as an AES-256 encrypted file';

  @override
  String get settingsHelpTesting => 'Help & Testing';

  @override
  String get settingsFeedback => 'Send Feedback / Report an Issue';

  @override
  String get settingsDiagnostics => 'Export Anonymous Diagnostics';

  @override
  String get settingsTriggerCrash => 'Trigger Test Crash';

  @override
  String get settingsEraseData => 'Erase All Data on Device';

  @override
  String get settingsEraseDataDialogTitle => 'Erase All Data?';

  @override
  String get settingsEraseDataDialogBody =>
      'This immediately wipes all cycle, medication, and symptom records from this phone. This action cannot be undone.';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonErase => 'Erase';

  @override
  String get buttonSaveLog => 'Save Log';

  @override
  String get logPeriodTitle => 'Log Period';

  @override
  String get flowIntensityTitle => 'Flow Intensity';

  @override
  String get flowLight => 'Light';

  @override
  String get flowMedium => 'Medium';

  @override
  String get flowHeavy => 'Heavy';

  @override
  String get flowSpotting => 'Spotting';

  @override
  String get symptomsTitle => 'Symptoms';
}
