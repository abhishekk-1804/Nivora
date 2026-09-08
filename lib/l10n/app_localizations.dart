import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi')
  ];

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// A warm, non-clinical term for the medical report tab.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// A term for the calming space / resource library.
  ///
  /// In en, this message translates to:
  /// **'Sanctuary'**
  String get tabSanctuary;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening.'**
  String get greetingEvening;

  /// No description provided for @logCycle.
  ///
  /// In en, this message translates to:
  /// **'Log Cycle'**
  String get logCycle;

  /// No description provided for @cycleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String cycleDay(int day);

  /// No description provided for @catchUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Catch Up'**
  String get catchUpTitle;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @statusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statusMissed;

  /// No description provided for @statusTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get statusTaken;

  /// No description provided for @setupRoutinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Set up a medication routine'**
  String get setupRoutinePrompt;

  /// No description provided for @medicinePhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine · Day {day} / {total}'**
  String medicinePhaseLabel(int day, int total);

  /// No description provided for @breakPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Treatment Break · Day {day} / {total}'**
  String breakPhaseLabel(int day, int total);

  /// No description provided for @noMedicationRequired.
  ///
  /// In en, this message translates to:
  /// **'No medication required today.'**
  String get noMedicationRequired;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String scheduledFor(String time);

  /// No description provided for @takenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken at {time}'**
  String takenAt(String time);

  /// No description provided for @markAsTaken.
  ///
  /// In en, this message translates to:
  /// **'Mark as Taken'**
  String get markAsTaken;

  /// No description provided for @cycleLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle Log'**
  String get cycleLogTitle;

  /// No description provided for @currentlyOnDay.
  ///
  /// In en, this message translates to:
  /// **'Currently on Day {day}'**
  String currentlyOnDay(int day);

  /// No description provided for @tapToLogPeriod.
  ///
  /// In en, this message translates to:
  /// **'Tap to log your period'**
  String get tapToLogPeriod;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get allCaughtUp;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get settingsDataPrivacy;

  /// No description provided for @settingsOfflineBadge.
  ///
  /// In en, this message translates to:
  /// **'100% Offline Device. Zero cloud servers.'**
  String get settingsOfflineBadge;

  /// No description provided for @settingsExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Encrypted Backup'**
  String get settingsExportBackup;

  /// No description provided for @settingsExportBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your data locally as an AES-256 encrypted file'**
  String get settingsExportBackupDesc;

  /// No description provided for @settingsHelpTesting.
  ///
  /// In en, this message translates to:
  /// **'Help & Testing'**
  String get settingsHelpTesting;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback / Report an Issue'**
  String get settingsFeedback;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Export Anonymous Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @settingsTriggerCrash.
  ///
  /// In en, this message translates to:
  /// **'Trigger Test Crash'**
  String get settingsTriggerCrash;

  /// No description provided for @settingsEraseData.
  ///
  /// In en, this message translates to:
  /// **'Erase All Data on Device'**
  String get settingsEraseData;

  /// No description provided for @settingsEraseDataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Erase All Data?'**
  String get settingsEraseDataDialogTitle;

  /// No description provided for @settingsEraseDataDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This immediately wipes all cycle, medication, and symptom records from this phone. This action cannot be undone.'**
  String get settingsEraseDataDialogBody;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonErase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get buttonErase;

  /// No description provided for @buttonSaveLog.
  ///
  /// In en, this message translates to:
  /// **'Save Log'**
  String get buttonSaveLog;

  /// No description provided for @logPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Period'**
  String get logPeriodTitle;

  /// No description provided for @flowIntensityTitle.
  ///
  /// In en, this message translates to:
  /// **'Flow Intensity'**
  String get flowIntensityTitle;

  /// No description provided for @flowLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get flowLight;

  /// No description provided for @flowMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get flowMedium;

  /// No description provided for @flowHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get flowHeavy;

  /// No description provided for @flowSpotting.
  ///
  /// In en, this message translates to:
  /// **'Spotting'**
  String get flowSpotting;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
