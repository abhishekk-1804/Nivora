// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get tabToday => 'आज';

  @override
  String get tabInsights => 'रिपोर्ट्स';

  @override
  String get tabSanctuary => 'सेंक्चुअरी';

  @override
  String get greetingEvening => 'शुभ संध्या।';

  @override
  String get logCycle => 'साइकिल लॉग करें';

  @override
  String cycleDay(int day) {
    return 'दिन $day';
  }

  @override
  String get catchUpTitle => 'पिछला ट्रैक करें';

  @override
  String get dateYesterday => 'कल';

  @override
  String get statusMissed => 'छूट गया';

  @override
  String get statusTaken => 'लिया गया';

  @override
  String get setupRoutinePrompt => 'दवा का नियम सेट करें';

  @override
  String medicinePhaseLabel(int day, int total) {
    return 'दवा · दिन $day / $total';
  }

  @override
  String breakPhaseLabel(int day, int total) {
    return 'ट्रीटमेंट ब्रेक · दिन $day / $total';
  }

  @override
  String get noMedicationRequired => 'आज कोई दवा लेने की आवश्यकता नहीं है।';

  @override
  String scheduledFor(String time) {
    return 'समय: $time';
  }

  @override
  String takenAt(String time) {
    return 'लिया गया समय: $time';
  }

  @override
  String get markAsTaken => 'लिया गया मार्क करें';

  @override
  String get cycleLogTitle => 'साइकिल लॉग';

  @override
  String currentlyOnDay(int day) {
    return 'अभी दिन $day पर हैं';
  }

  @override
  String get tapToLogPeriod => 'अपना पीरियड लॉग करने के लिए टैप करें';

  @override
  String get allCaughtUp => 'सब कुछ अप-टू-डेट है।';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsDataPrivacy => 'डेटा और प्राइवेसी';

  @override
  String get settingsOfflineBadge =>
      '100% ऑफलाइन डिवाइस। कोई क्लाउड सर्वर नहीं।';

  @override
  String get settingsExportBackup => 'एन्क्रिप्टेड बैकअप एक्सपोर्ट करें';

  @override
  String get settingsExportBackupDesc =>
      'अपने डेटा को स्थानीय रूप से AES-256 एन्क्रिप्टेड फ़ाइल के रूप में सहेजें';

  @override
  String get settingsHelpTesting => 'सहायता और परीक्षण';

  @override
  String get settingsFeedback => 'फीडबैक भेजें / समस्या की रिपोर्ट करें';

  @override
  String get settingsDiagnostics => 'अनाम डायग्नोस्टिक्स एक्सपोर्ट करें';

  @override
  String get settingsTriggerCrash => 'टेस्ट क्रैश ट्रिगर करें';

  @override
  String get settingsEraseData => 'डिवाइस से सारा डेटा मिटाएं';

  @override
  String get settingsEraseDataDialogTitle => 'सारा डेटा मिटाएं?';

  @override
  String get settingsEraseDataDialogBody =>
      'यह इस फोन से सभी साइकिल, दवा और लक्षणों के रिकॉर्ड को तुरंत मिटा देता है। इस कार्रवाई को वापस नहीं लिया जा सकता।';

  @override
  String get buttonCancel => 'रद्द करें';

  @override
  String get buttonErase => 'मिटाएं';

  @override
  String get buttonSaveLog => 'लॉग सहेजें';

  @override
  String get logPeriodTitle => 'पीरियड लॉग करें';

  @override
  String get flowIntensityTitle => 'बहाव की तीव्रता';

  @override
  String get flowLight => 'हल्का';

  @override
  String get flowMedium => 'माध्यम';

  @override
  String get flowHeavy => 'भारी';

  @override
  String get flowSpotting => 'स्पॉटिंग';

  @override
  String get symptomsTitle => 'लक्षण';
}
