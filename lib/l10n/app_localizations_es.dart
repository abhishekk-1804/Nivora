// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabInsights => 'Análisis';

  @override
  String get tabSanctuary => 'Santuario';

  @override
  String get greetingEvening => 'Buenas noches.';

  @override
  String get logCycle => 'Registrar Ciclo';

  @override
  String cycleDay(int day) {
    return 'Día $day';
  }

  @override
  String get catchUpTitle => 'Ponerse al Día';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String get statusMissed => 'No tomado';

  @override
  String get statusTaken => 'Tomado';

  @override
  String get setupRoutinePrompt => 'Configurar una rutina de medicación';

  @override
  String medicinePhaseLabel(int day, int total) {
    return 'Medicamento · Día $day / $total';
  }

  @override
  String breakPhaseLabel(int day, int total) {
    return 'Descanso del tratamiento · Día $day / $total';
  }

  @override
  String get noMedicationRequired => 'No se requiere medicación hoy.';

  @override
  String scheduledFor(String time) {
    return 'Programado para las $time';
  }

  @override
  String takenAt(String time) {
    return 'Tomado a las $time';
  }

  @override
  String get markAsTaken => 'Marcar como tomado';

  @override
  String get cycleLogTitle => 'Registro del Ciclo';

  @override
  String currentlyOnDay(int day) {
    return 'Actualmente en el Día $day';
  }

  @override
  String get tapToLogPeriod => 'Toca para registrar tu período';

  @override
  String get allCaughtUp => 'Estás al día.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsDataPrivacy => 'Datos y Privacidad';

  @override
  String get settingsOfflineBadge =>
      '100% Offline en este dispositivo. Cero servidores en la nube.';

  @override
  String get settingsExportBackup => 'Exportar Copia de Seguridad Cifrada';

  @override
  String get settingsExportBackupDesc =>
      'Guarda tus datos localmente como archivo AES-256 cifrado';

  @override
  String get settingsHelpTesting => 'Ayuda y Pruebas';

  @override
  String get settingsFeedback => 'Enviar comentarios / Reportar un problema';

  @override
  String get settingsDiagnostics => 'Exportar Diagnósticos Anónimos';

  @override
  String get settingsTriggerCrash => 'Provocar Fallo de Prueba';

  @override
  String get settingsEraseData => 'Borrar Todos los Datos del Dispositivo';

  @override
  String get settingsEraseDataDialogTitle => '¿Borrar Todos los Datos?';

  @override
  String get settingsEraseDataDialogBody =>
      'Esto borra inmediatamente todos los registros de ciclo, medicación y síntomas de este teléfono. Esta acción no se puede deshacer.';

  @override
  String get buttonCancel => 'Cancelar';

  @override
  String get buttonErase => 'Borrar';

  @override
  String get buttonSaveLog => 'Guardar Registro';

  @override
  String get logPeriodTitle => 'Registrar Período';

  @override
  String get flowIntensityTitle => 'Intensidad del Flujo';

  @override
  String get flowLight => 'Ligero';

  @override
  String get flowMedium => 'Moderado';

  @override
  String get flowHeavy => 'Abundante';

  @override
  String get flowSpotting => 'Manchado';

  @override
  String get symptomsTitle => 'Síntomas';
}
