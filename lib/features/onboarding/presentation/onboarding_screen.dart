import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../core/services/backup_service.dart';
import '../../settings/presentation/widgets/backup_passphrase_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _enableAppLock = false;
  bool _notificationGranted = false;
  bool _checkingNotification = false;

  bool _isPcosGoal = false;
  bool _isRoutineGoal = false;

  @override
  void initState() {
    super.initState();
    _checkInitialNotificationStatus();
  }

  /// Reads the current OS permission state so the button reflects reality
  /// even if the user already granted permission before onboarding
  /// (e.g., re-running onboarding after a reinstall on a device that remembers).
  Future<void> _checkInitialNotificationStatus() async {
    final granted = await NotificationService.areNotificationsEnabled();
    if (mounted) setState(() => _notificationGranted = granted);
  }

  Future<void> _requestNotificationPermission() async {
    if (_notificationGranted) return; // already granted — no-op
    setState(() => _checkingNotification = true);

    final granted = await NotificationService.requestPermission();

    if (mounted) {
      setState(() {
        _notificationGranted = granted;
        _checkingNotification = false;
      });
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_onboarded', true);
    await prefs.setBool('is_pcos_goal', _isPcosGoal);
    await prefs.setBool('is_routine_goal', _isRoutineGoal);
    if (_enableAppLock) {
      await prefs.setBool('app_lock_enabled', true);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildPage(
                    title: 'Your health.\nYour space.',
                    description:
                        'Nivora stores all your records securely on this device. '
                        'Zero cloud sync. Zero ads. Just you and your data.',
                    icon: Icons.shield_outlined,
                    actionWidget: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Consumer(
                        builder: (context, ref, child) {
                          return TextButton.icon(
                            icon: const Icon(Icons.restore, color: AppColors.brandAction),
                            label: const Text(
                              'Already have a backup? Restore your data',
                              style: TextStyle(color: AppColors.brandAction, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              try {
                                final file = await FilePicker.pickFile(
                                  type: FileType.custom,
                                  allowedExtensions: ['nivorabackup', 'imyrabackup'],
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
                                          Navigator.of(context).pop(); // pop loading dialog
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (context) => const MainNavigation()),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) Navigator.of(context).pop(); // pop loading dialog
                                        rethrow;
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
                          );
                        },
                      ),
                    ),
                  ),
                  _buildGoalsPage(),
                  _buildPage(
                    title: 'Track With\nPrecision.',
                    description:
                        'Log your symptoms, flow, and treatments effortlessly. '
                        'Built for complex cycles and PCOS.',
                    icon: Icons.water_drop_outlined,
                    actionWidget: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _buildNotificationWidget(),
                    ),
                  ),
                  _buildPage(
                    title: 'Secured by\nBiometrics.',
                    // Platform-neutral copy — no Apple-specific branding
                    description:
                        'Protected by biometric authentication (Face ID, '
                        'fingerprint, or PIN) and end-to-end encrypted backups.',
                    icon: Icons.fingerprint,
                    actionWidget: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Material(
                        color: AppColors.cardSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile(
                          title: const Text(
                            'Enable Biometric / PIN Lock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalInk,
                            ),
                          ),
                          subtitle: const Text(
                            'Require authentication to open the app',
                            style: TextStyle(
                              color: AppColors.mutedSage,
                              fontSize: 12,
                            ),
                          ),
                          value: _enableAppLock,
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
                                setState(() => _enableAppLock = false);
                                return; // Abort turning it on
                              }
                            }
                            setState(() => _enableAppLock = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page dots — always visible ────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedContainer(
                    duration: 300.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.brandAction
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── Footer button — full-width "Get Started" on last page ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _currentPage == 3
                    ? ElevatedButton(
                        key: const ValueKey('get_started'),
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : Row(
                        key: const ValueKey('next_row'),
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: 400.ms,
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 54),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Notification button widget — shows granted/pending state with animation.
  Widget _buildNotificationWidget() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: _notificationGranted
          ? _buildGrantedBadge()
          : _buildRequestButton(),
    );
  }

  Widget _buildGrantedBadge() {
    return Container(
      key: const ValueKey('granted'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // green-50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)), // green-200
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF16A34A), size: 20), // green-600
          const SizedBox(width: 10),
          Text(
            'Reminders Enabled',
            style: TextStyle(
              color: const Color(0xFF15803D), // green-700
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton() {
    return OutlinedButton.icon(
      key: const ValueKey('request'),
      onPressed: _checkingNotification ? null : _requestNotificationPermission,
      icon: _checkingNotification
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.notifications_active_outlined),
      label: const Text('Enable Daily Reminders'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.charcoalInk,
        iconColor: AppColors.charcoalInk,
        minimumSize: const Size(0, 54),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
    Widget? actionWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 64, color: AppColors.brandAction),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: AppColors.deepInk,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.mutedSage,
              fontSize: 18,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          if (actionWidget != null)
            actionWidget
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What brings you to Nivora?',
            style: TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: AppColors.deepInk,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select the features you need most. You can change this later.',
            style: TextStyle(fontSize: 15, color: AppColors.charcoalInk),
          ),
          const SizedBox(height: 32),
          _GoalCard(
            title: 'Cycle & Period Tracking',
            subtitle: 'Focus on cycle predictions and symptom logging.',
            icon: Icons.calendar_month,
            isSelected: true, // Always selected for baseline tracking
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _GoalCard(
            title: 'Managing PCOS & Health',
            subtitle: 'Advanced metabolic tracking and phenotype profile.',
            icon: Icons.health_and_safety,
            isSelected: _isPcosGoal,
            onTap: () => setState(() => _isPcosGoal = !_isPcosGoal),
          ),
          const SizedBox(height: 16),
          _GoalCard(
            title: 'Medication Adherence',
            subtitle: 'Daily reminders for supplements and birth control.',
            icon: Icons.medication,
            isSelected: _isRoutineGoal,
            onTap: () => setState(() => _isRoutineGoal = !_isRoutineGoal),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAction.withValues(alpha: 0.05) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandAction : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppColors.brandAction : AppColors.mutedSage),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.charcoalInk : AppColors.mutedSage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
