import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/providers/database_provider.dart';
import '../../today/presentation/today_controller.dart';
import '../../cycle/presentation/cycle_controller.dart';
import '../../report/presentation/report_controller.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/auth_service.dart';
import 'widgets/feedback_dialog.dart';
import 'widgets/backup_passphrase_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../core/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'Version ${info.version}+${info.buildNumber}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        backgroundColor: AppColors.warmIvory,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Account & Security ──
          _buildSectionHeader('Account & Security'),
          Card(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.lightBorder),
            ),
            child: Builder(
              builder: (context) {
                final prefs = ref.watch(sharedPreferencesProvider);
                final isLocked = prefs.getBool('app_lock_enabled') ?? false;
                return SwitchListTile(
                  title: const Text('Biometric App Lock', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Require Face ID / Touch ID (Locks after 10 seconds in the background)', style: TextStyle(fontSize: 12)),
                  value: isLocked,
                  activeThumbColor: AppColors.brandAction,
                  onChanged: (val) async {
                    if (val) {
                      final authResult = await AuthService.authenticate();
                      if (authResult != AuthResult.success) {
                        if (context.mounted) {
                          SnackbarUtils.show(
                            context: context,
                            title: 'Setup Failed',
                            message: 'You must set up a device passcode or pass the authentication challenge to enable App Lock.',
                            contentType: ContentType.failure,
                          );
                        }
                        return; // Abort turning it on
                      }
                    }
                    await prefs.setBool('app_lock_enabled', val);
                    setState(() {});
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Data & Privacy ──
          _buildSectionHeader('Data & Privacy'),
          Card(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_off, color: AppColors.brandAction),
                  title: Text(AppLocalizations.of(context)!.settingsOfflineBadge, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1, color: AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.deepInk),
                  title: const Text('Export Encrypted Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('End-to-end encrypted with your passphrase. Only you can open this file.'),
                  trailing: const Icon(Icons.download_outlined, color: AppColors.mutedSage),
                  onTap: () async {
                    final passphrase = await showDialog<String>(
                      context: context,
                      builder: (context) => const BackupPassphraseDialog(),
                    );
                    if (passphrase != null && context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );
                      try {
                        final db = ref.read(appDatabaseProvider);
                        await BackupService.exportEncryptedBackup(db, passphrase);
                        if (context.mounted) {
                          SnackbarUtils.show(
                            context: context,
                            title: 'Backup Complete',
                            message: 'Encrypted backup generated.',
                            contentType: ContentType.success,
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.brandAction),
                  title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Import and decrypt a .imyrabackup file (replaces current local data).'),
                  trailing: const Icon(Icons.upload_file_outlined, color: AppColors.mutedSage),
                  onTap: () async {
                    try {
                      final file = await FilePicker.pickFile(
                        type: FileType.custom,
                        allowedExtensions: ['imyrabackup'],
                      );

                      if (file != null && file.path != null) {
                        if (context.mounted) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Replace All Data?'),
                              content: const Text('Restoring from a backup will permanently replace all existing data on this device. We strongly recommend exporting a backup of your current data first.\n\nDo you want to continue?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Restore Data', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true || !context.mounted) return;

                          final passphrase = await showDialog<String>(
                            context: context,
                            builder: (context) => const BackupPassphraseDialog(isRestore: true),
                          );

                          if (passphrase != null && context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              final db = ref.read(appDatabaseProvider);
                              await BackupService.restoreEncryptedBackup(db, file, passphrase);

                              if (context.mounted) {
                                SnackbarUtils.show(
                                  context: context,
                                  title: 'Restore Complete',
                                  message: 'Data imported successfully.',
                                  contentType: ContentType.success,
                                );
                                
                                ref.invalidate(appDatabaseProvider);
                                ref.invalidate(todayControllerProvider);
                                ref.invalidate(cycleControllerProvider);
                                ref.invalidate(reportControllerProvider);
                              }
                            } finally {
                              if (context.mounted) Navigator.of(context).pop();
                            }
                          }
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        SnackbarUtils.show(
                          context: context,
                          title: 'Restore Failed',
                          message: e.toString().contains('Exception:') ? e.toString().split('Exception:').last.trim() : 'Invalid backup file or incorrect passphrase.',
                          contentType: ContentType.failure,
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.lightBorder),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Erase All Data on Device', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    _showEraseDataDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Clinical Profile ──
          _buildSectionHeader('Clinical Profile'),
          Card(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.lightBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Medication & Supplements', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Show medication tracking and daily pill reminders', style: TextStyle(fontSize: 12)),
                  value: ref.watch(isRoutineGoalProvider),
                  activeThumbColor: AppColors.brandAction,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_routine_goal', val);
                    ref.read(isRoutineGoalProvider.notifier).state = val;
                  },
                ),
                const Divider(height: 1, color: AppColors.lightBorder),
                SwitchListTile(
                  title: const Text('Advanced Clinical Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Show Metabolic Tracking and Rotterdam Phenotype Config', style: TextStyle(fontSize: 12)),
                  value: ref.watch(advancedClinicalTrackingProvider),
                  activeThumbColor: AppColors.brandAction,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('advanced_clinical_tracking', val);
                    ref.read(advancedClinicalTrackingProvider.notifier).state = val;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── General ──
          _buildSectionHeader('General'),
          Card(
            color: AppColors.cardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback_outlined, color: AppColors.deepInk),
                  title: const Text('Send Feedback / Report an Issue', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.mutedSage),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FeedbackDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              _appVersion,
              style: const TextStyle(color: AppColors.mutedSage, fontSize: 12),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.deepInk,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEraseDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.warmIvory,
        title: const Text('Erase All Data?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This immediately wipes all cycle, medication, and symptom records from this phone. This action cannot be undone.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.lightBorder),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAction, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      Navigator.of(context).pop();
                      final db = ref.read(appDatabaseProvider);
                      // Enable secure_delete so SQLite overwrites deleted content with zeros (S-03)
                      await db.customStatement('PRAGMA secure_delete = ON;');
                      await db.transaction(() async {
                        await db.delete(db.cycleEvents).go();
                        await db.delete(db.routineLogs).go();
                        await db.delete(db.routines).go();
                        await db.delete(db.treatmentInterventions).go();
                        await db.delete(db.labResults).go();
                        await db.delete(db.clinicalProfile).go();
                        await db.delete(db.metabolicLogs).go();
                      });
                      
                      // Force SQLite to physically rebuild the file and overwrite free space
                      await db.customStatement('VACUUM');
                      
                      ref.invalidate(appDatabaseProvider);
                      ref.invalidate(todayControllerProvider);
                      ref.invalidate(cycleControllerProvider);
                      ref.invalidate(reportControllerProvider);
                      if (context.mounted) {
                        SnackbarUtils.show(
                          context: context,
                          title: 'Data Erased',
                          message: 'All data has been permanently erased.',
                          contentType: ContentType.failure,
                        );
                      }
                    },
                    child: const Text('Erase', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
