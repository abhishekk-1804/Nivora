import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/quote_service.dart';
import 'today_controller.dart';
import '../../cycle/presentation/cycle_controller.dart';
import '../../cycle/presentation/widgets/quick_log_sheet.dart';
import '../../cycle/presentation/widgets/cycle_graph.dart';
import '../../routines/presentation/routine_setup_sheet.dart';
import 'widgets/metabolic_log_sheet.dart';
import 'widgets/first_use_guide_overlay.dart';
import 'widgets/clinical_log_sheet.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/nivora_logo.dart';
import '../../../core/widgets/illustrations/illustration_caught_up.dart';
import '../../../core/widgets/illustrations/illustration_routine.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/privacy_provider.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/constants/preference_keys.dart';

class PrivacyBlur extends ConsumerWidget {
  final Widget child;
  const PrivacyBlur({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivacyMode = ref.watch(privacyModeProvider);
    // Smooth 150ms crossfade between blurred/clear instead of an instant snap.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isPrivacyMode ? 4.0 : 0.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, sigma, _) {
        if (sigma < 0.01) return child;
        return GestureDetector(
          onLongPressStart: (_) =>
              ref.read(privacyModeProvider.notifier).setFalse(),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Container(color: Colors.transparent, child: child),
          ),
        );
      },
    );
  }
}

class TodayScreen extends ConsumerStatefulWidget {
  /// Called when the user taps the settings icon — lets the parent shell
  /// switch the bottom-nav to the Settings tab without a push route.
  final VoidCallback? onNavigateToSettings;
  const TodayScreen({super.key, this.onNavigateToSettings});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  @override
  void initState() {
    super.initState();
    // T2-3: Show the first-use guide overlay exactly once per install.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final alreadySeen = prefs.getBool(PreferenceKeys.seenTodayGuide) ?? false;
      if (!alreadySeen) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => FirstUseGuideOverlay(
            onDismiss: () => prefs.setBool(PreferenceKeys.seenTodayGuide, true),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayState = ref.watch(todayControllerProvider);
    final cycleState = ref.watch(cycleControllerProvider);
    final isRoutineGoal = ref.watch(isRoutineGoalProvider);
    final isAdvancedClinical = ref.watch(advancedClinicalTrackingProvider);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionMenu(context),
        backgroundColor: AppColors.brandAction,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Minimal logo app bar ──────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppColors.warmIvory,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 56,
              leadingWidth: 160,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NivoraLogo(size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'nivora',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.brandAction,
                          ),
                    ),
                  ],
                ),
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final isPrivacyMode = ref.watch(privacyModeProvider);
                    return IconButton(
                      icon: Icon(
                        isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.deepInk,
                        size: 22,
                      ),
                      tooltip: 'Privacy Blur',
                      onPressed: () {
                        ref.read(privacyModeProvider.notifier).toggle();
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.deepInk, size: 22),
                  tooltip: 'Settings',
                  onPressed: () {
                    widget.onNavigateToSettings?.call();
                  },
                ),
              ],
            ),

            // ── Body ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 4.0, bottom: 64.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Premium greeting block ──────────────────────────────
                    _GreetingBlock(
                      cycleDay: cycleState.value?.currentCycleDay,
                      cyclePhase: cycleState.value?.currentPhase,
                    ),
                    const SizedBox(height: 20),

                    todayState.when(
                      data: (state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cycle graph (if tracking)
                          if (cycleState.value?.currentCycleDay != null) ...[
                            CycleGraph(
                                    currentDay:
                                        cycleState.value!.currentCycleDay!)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0, duration: 400.ms),
                            const SizedBox(height: 12),
                          ],
                          
                          // Clinical & Metabolic Cards
                          if (isAdvancedClinical) ...[
                            _buildMetabolicCard(context),
                            const SizedBox(height: 24),
                          ],

                          // Catch-up drawer
                          if (state.missedRecentLogs.isNotEmpty)
                            _buildCatchUpDrawer(context, state.missedRecentLogs)
                                .animate()
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut),

                          // Medication cards (one per active routine)
                          if (isRoutineGoal) ...[
                            if (state.routineCards.isEmpty)
                              _buildEmptyRoutineCard(context)
                            else
                              ...state.routineCards.map((card) =>
                                  _MedicationCard(
                                    key: ValueKey(card.routine.id),
                                    cardState: card,
                                    onMarkTaken: () {
                                        ref.read(todayControllerProvider.notifier)
                                            .markTaken(DateTime.now(),
                                                routineId: card.routine.id);
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.favorite, color: Colors.white, size: 20),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'Great job prioritizing your health today!',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor: AppColors.brandAction,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            duration: const Duration(seconds: 3),
                                          )
                                        );
                                    },
                                    onEdit: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => RoutineSetupSheet(
                                          routine: card.routine),
                                    ),
                                    onDelete: () => _confirmDelete(
                                        context, card.routine),
                                  )),

                            // Add another medicine button (when at least one exists)
                            if (state.routineCards.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: OutlinedButton.icon(
                                onPressed: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const RoutineSetupSheet(),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add another medication'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.deepInk,
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  side: const BorderSide(
                                      color: AppColors.lightBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ).animate().fade(duration: 400.ms).slideY(begin: 0.05),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.brandAction)),
                      ),
                      error: (err, _) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                              'We couldn\'t load your routines. Please pull to refresh.',
                              style: TextStyle(
                                  color: AppColors.mutedSage, fontSize: 13)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildCycleCard(context, cycleState.value),
                    const SizedBox(height: 24),
                    _buildClinicalInsights(context, cycleState.value),
                    const SizedBox(height: 24),

                    // B-03 fix: All caught up state.
                    // Guard against null state and explicitly require a non-empty
                    // routineCards list so an empty today-state never shows "caught up".
                    if (todayState.value != null &&
                        todayState.value!.routineCards.isNotEmpty &&
                        todayState.value!.missedRecentLogs.isEmpty &&
                        todayState.value!.routineCards
                            .every((c) => c.todayLog?.status == 'Taken'))
                      Center(
                        child: Column(
                          children: [
                            const IllustrationCaughtUp(size: 150),
                            const SizedBox(height: 24),
                            Text(
                              "You're all caught up.",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.charcoalInk,
                                  ),
                            ),
                          ],
                        ),
                      ).animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1.0, 1.0),
                            duration: 450.ms,
                            curve: Curves.elasticOut,
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

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 48),
        decoration: const BoxDecoration(
          color: AppColors.warmIvory,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What would you like to log?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepInk)),
            const SizedBox(height: 24),
            _buildActionTile(
              context, 
              icon: Icons.water_drop, 
              title: 'Cycle & Symptoms', 
              subtitle: 'Bleeding, pain, and physical symptoms',
              color: Colors.red.shade400,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const QuickLogSheet(),
                );
              }
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context, 
              icon: Icons.monitor_weight_outlined, 
              title: 'Metabolic Vitals', 
              subtitle: 'Weight, waist, signs of insulin resistance',
              color: AppColors.charcoalInk,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const MetabolicLogSheet(),
                );
              }
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context, 
              icon: Icons.medication, 
              title: 'New Medication', 
              subtitle: 'Add a new daily or cyclic routine',
              color: AppColors.brandAction,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const RoutineSetupSheet(),
                );
              }
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              context, 
              icon: Icons.biotech_outlined, 
              title: 'Clinical & Lab Logs', 
              subtitle: 'Log lab results, profile updates, treatments',
              color: Colors.teal.shade600,
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ClinicalLogSheet(),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: Border.all(color: AppColors.lightBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepInk)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.mutedSage, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedSage),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.warmIvory,
        title: Text('Remove ${routine.name}?',
            style: const TextStyle(
                color: AppColors.deepInk, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This will delete the medication and all its logs. This cannot be undone.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.lightBorder),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.deepInk,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(todayControllerProvider.notifier)
                          .deleteRoutine(routine.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Remove',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatchUpDrawer(
      BuildContext context, List<RoutineLog> missedLogs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.subtlePeach.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.subtlePeach.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catch Up',
            style: TextStyle(
              color: AppColors.deepInk,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...missedLogs.map((log) {
            final isYesterday =
                DateTime.now().difference(log.scheduledDate).inDays == 1;
            final dateLabel = isYesterday
                ? 'Yesterday'
                : DateFormat('EEEE').format(log.scheduledDate);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateLabel,
                      style: const TextStyle(
                          color: AppColors.deepInk, fontSize: 14)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => ref
                            .read(todayControllerProvider.notifier)
                            .markSkipped(log.scheduledDate,
                                routineId: log.routineId),
                        child: const Text('Missed',
                            style: TextStyle(color: AppColors.mutedSage)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                            helpText: 'When did you take this?',
                          );
                          if (time != null) {
                            final customDate = DateTime(
                              log.scheduledDate.year,
                              log.scheduledDate.month,
                              log.scheduledDate.day,
                              time.hour,
                              time.minute,
                            );
                            ref
                                .read(todayControllerProvider.notifier)
                                .markTaken(log.scheduledDate,
                                    completedAt: customDate,
                                    routineId: log.routineId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAction,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Taken'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyRoutineCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const RoutineSetupSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          children: [
            IllustrationRoutine(size: 100),
            SizedBox(height: 16),
            Text(
              'Add a medication routine',
              style: TextStyle(
                color: AppColors.charcoalInk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Track Metformin, Inositol, birth control and more.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedSage, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleCard(BuildContext context, CycleState? state) {
    final cycleDay = state?.currentCycleDay;
    final phase = state?.currentPhase;
    final mostRecentEvent =
        state?.recentEvents.isNotEmpty == true ? state!.recentEvents.first : null;
    final isAnovulatory = mostRecentEvent?.flowType == 'Anovulatory';

    String subtitle = 'Tap to log your period';
    if (cycleDay != null) {
      subtitle = phase != null ? 'Day $cycleDay • $phase' : 'Currently on Day $cycleDay';
    } else if (state?.estimatedCycleDay != null) {
      subtitle = isAnovulatory 
          ? 'Cycle Day ~${state!.estimatedCycleDay} (Post-Anovulatory)'
          : 'Cycle Day ~${state!.estimatedCycleDay} (estimated)';
    } else if (isAnovulatory) {
      subtitle = 'Anovulatory cycle logged';
    }

    final card = GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const QuickLogSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.softLavender.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.brandAction.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cycle Log',
                    style: TextStyle(
                        color: AppColors.deepInk,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.mutedSage, fontSize: 14)),
              ],
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.brandAction),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        _buildCycleSyncingTip(phase),
      ],
    );
  }

  Widget _buildCycleSyncingTip(String? phase) {
    if (phase == null) return const SizedBox.shrink();
    
    String title = '';
    String tip = '';
    IconData iconData = Icons.spa;
    Color color = AppColors.brandAction;

    if (phase == 'Menstrual Phase') {
      title = 'Rest & Restore';
      tip = 'Your energy is naturally lowest now. Focus on gentle movement like yoga, prioritize sleep, and eat iron-rich foods.';
      iconData = Icons.nights_stay;
      color = Colors.indigo.shade400;
    } else if (phase == 'Follicular Phase') {
      title = 'Build Momentum';
      tip = 'Estrogen is rising! This is a great time for strength training, trying new things, and eating protein-rich foods.';
      iconData = Icons.trending_up;
      color = Colors.green.shade600;
    } else if (phase == 'Ovulatory Window') {
      title = 'Peak Energy';
      tip = 'You likely have the most energy and sociability now. High-intensity workouts feel great. Focus on fiber-rich veggies.';
      iconData = Icons.local_fire_department;
      color = Colors.orange.shade700;
    } else if (phase == 'Luteal Phase') {
      title = 'Nesting & Nourishing';
      tip = 'Progesterone is rising. You may feel more introverted. Switch to Pilates or walking, and eat complex carbs to stabilize mood.';
      iconData = Icons.self_improvement;
      color = AppColors.brandAction;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tip,
            style: const TextStyle(
              color: AppColors.deepInk,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildMetabolicCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const MetabolicLogSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.subtlePeach.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.subtlePeach.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Metabolic Tracking',
                    style: TextStyle(
                        color: AppColors.deepInk,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Weight, Waist-to-Hip, Signs',
                    style:
                        TextStyle(color: AppColors.mutedSage, fontSize: 14)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                  color: AppColors.cardBg, shape: BoxShape.circle),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: AppColors.charcoalInk),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildClinicalInsights(BuildContext context, CycleState? cycleState) {
    if (cycleState == null) return const SizedBox.shrink();

    final List<Widget> cards = [];
    final symptoms = cycleState.frequentSymptoms.map((s) => s.toLowerCase()).toList();

    // Rule 1: Metabolic / Insulin Resistance
    final hasMetabolicSymptom = symptoms.any((s) =>
        s.contains('sugar cravings') ||
        s.contains('fatigue') ||
        s.contains('tiredness') ||
        s.contains('energy: low'));
    if (hasMetabolicSymptom) {
      cards.add(
        _buildInsightCard(
          context,
          icon: Icons.biotech_rounded,
          color: Colors.teal.shade600,
          title: 'Metabolic Biomarker Check',
          body: 'Recent logs of fatigue or cravings can indicate metabolic / insulin changes. Consider asking your clinician about a Fasting Insulin or HbA1c test.',
        ),
      );
    }

    // Rule 2: Androgen Excess
    final hasAndrogenSymptom = symptoms.any((s) =>
        s.contains('acne') ||
        s.contains('hair') ||
        s.contains('hirsutism') ||
        s.contains('skin tags'));
    if (hasAndrogenSymptom) {
      cards.add(
        _buildInsightCard(
          context,
          icon: Icons.health_and_safety_outlined,
          color: AppColors.brandAction,
          title: 'Androgen Biomarker Check',
          body: 'Physical signs like skin or hair changes are associated with androgens. Discuss checking Total Testosterone or DHEA-S levels at your next visit.',
        ),
      );
    }

    // Rule 3: Irregular cycles
    if (cycleState.medianCycleLength > 35 || cycleState.medianCycleLength < 21) {
      cards.add(
        _buildInsightCard(
          context,
          icon: Icons.insights_rounded,
          color: Colors.indigo.shade600,
          title: 'Cycle Frequency Check',
          body: 'Your median cycle length of ${cycleState.medianCycleLength} days is outside the typical range. Ask your doctor about an LH / FSH ratio screen.',
        ),
      );
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Clinical Insights & Nudges',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.mutedSage,
          ),
        ),
        const SizedBox(height: 10),
        ...cards,
      ],
    );
  }

  Widget _buildInsightCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                      color: AppColors.deepInk, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

} // end TodayScreen

// ── Premium Greeting Block ────────────────────────────────────────────────────

class _GreetingBlock extends ConsumerStatefulWidget {
  final int? cycleDay;
  final String? cyclePhase;
  const _GreetingBlock({this.cycleDay, this.cyclePhase});

  @override
  ConsumerState<_GreetingBlock> createState() => _GreetingBlockState();
}

class _GreetingBlockState extends ConsumerState<_GreetingBlock> {
  // T2-1: Track which energy/mood chip was last tapped. ValueNotifier is passed down
  // to each chip so they can de-select each other.
  // Initialized from DB on first build — survives Riverpod provider rebuilds.
  final ValueNotifier<String?> _selectedEnergy = ValueNotifier(null);
  final ValueNotifier<String?> _selectedMood = ValueNotifier(null);
  bool _chipsInitialized = false;

  static String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    if (hour < 21) return 'Good evening.';
    return 'Good night.';
  }

  @override
  void dispose() {
    _selectedEnergy.dispose();
    _selectedMood.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    // T2-1: Restore chip selections from DB on first build.
    // watchRecentEvents returns a live stream, so the ValueNotifiers will
    // stay in sync even if the user logs via another route.
    final symptomsAsync = ref.watch(todaySymptomLogsProvider);
    symptomsAsync.whenData((events) {
      if (_chipsInitialized) return;
      _chipsInitialized = true;
      for (final e in events) {
        final s = e.symptoms ?? '';
        if (s.startsWith('Energy: ')) {
          _selectedEnergy.value = s.replaceFirst('Energy: ', '');
        } else if (s.startsWith('Mood: ')) {
          // 'Mood: Good 🙂' — strip the emoji suffix for matching
          final parts = s.replaceFirst('Mood: ', '').split(' ');
          if (parts.isNotEmpty) _selectedMood.value = parts.first;
        }
      }
    });

    // Watch the quote service provider
    final quoteAsync = ref.watch(quoteServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: const TextStyle(
            color: AppColors.deepInk,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: const TextStyle(
            color: AppColors.mutedSage,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.cycleDay != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandAction.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: PrivacyBlur(
              child: Text(
                widget.cyclePhase != null ? 'Cycle Day ${widget.cycleDay} • ${widget.cyclePhase}' : 'Cycle Day ${widget.cycleDay}',
                style: const TextStyle(
                  color: AppColors.brandAction,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.battery_charging_full, size: 14, color: AppColors.mutedSage),
            const SizedBox(width: 6),
            const Text('Energy:', style: TextStyle(color: AppColors.mutedSage, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _EnergyChip(label: 'High', color: const Color(0xFF2E7D32), selectedEnergy: _selectedEnergy),
            const SizedBox(width: 6),
            _EnergyChip(label: 'Med', color: const Color(0xFFE65100), selectedEnergy: _selectedEnergy),
            const SizedBox(width: 6),
            _EnergyChip(label: 'Low', color: const Color(0xFFC62828), selectedEnergy: _selectedEnergy),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.mood, size: 14, color: AppColors.mutedSage),
            const SizedBox(width: 6),
            const Text('Mood:  ', style: TextStyle(color: AppColors.mutedSage, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _MoodChip(emoji: '😭', label: 'Awful', selectedMood: _selectedMood),
            const SizedBox(width: 8),
            _MoodChip(emoji: '🙁', label: 'Bad', selectedMood: _selectedMood),
            const SizedBox(width: 8),
            _MoodChip(emoji: '😐', label: 'Okay', selectedMood: _selectedMood),
            const SizedBox(width: 8),
            _MoodChip(emoji: '🙂', label: 'Good', selectedMood: _selectedMood),
            const SizedBox(width: 8),
            _MoodChip(emoji: '😄', label: 'Great', selectedMood: _selectedMood),
          ],
        ),
        const SizedBox(height: 14),
        // ── Daily quote ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.brandAction.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandAction.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“', 
                style: GoogleFonts.alice(
                  fontSize: 28, 
                  color: AppColors.brandAction, 
                  height: 1.0, 
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: quoteAsync.when(
                  data: (service) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${service.getTodaysQuote()}”',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color.fromARGB(192, 127, 3, 3),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  loading: () => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('...”', style: GoogleFonts.playfairDisplay(color: AppColors.mutedSage, fontStyle: FontStyle.italic)),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Have a wonderful day.', 
                      style: GoogleFonts.playfairDisplay(color: AppColors.charcoalInk, fontStyle: FontStyle.italic, fontSize: 14)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Energy chip with selected-state tracking and a scale-bounce tap animation (P2).
/// Accepts a [selectedEnergy] ValueNotifier shared across all chips in the row
/// so that selecting one chip de-selects the others.

class _EnergyChip extends ConsumerStatefulWidget {
  final String label;
  final Color color;
  final ValueNotifier<String?> selectedEnergy;

  const _EnergyChip({
    required this.label,
    required this.color,
    required this.selectedEnergy,
  });

  @override
  ConsumerState<_EnergyChip> createState() => _EnergyChipState();
}

class _EnergyChipState extends ConsumerState<_EnergyChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_scaleCtrl);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    // E-04 fix: Guard against tapping while the cycle controller is still loading.
    final cycleState = ref.read(cycleControllerProvider);
    if (cycleState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Just a moment…'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.deepInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    // Fire scale bounce animation.
    _scaleCtrl.forward(from: 0);
    HapticFeedback.lightImpact(); // Subtle chip-select tap

    // Update selected state (ValueNotifier — no Riverpod provider needed).
    widget.selectedEnergy.value = widget.label;
    ref.read(cycleControllerProvider.notifier).logSymptomOnly('Energy: ${widget.label}');

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.label} energy logged!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder rebuilds this chip whenever any chip in the row is tapped.
    return ListenableBuilder(
      listenable: widget.selectedEnergy,
      builder: (context, _) {
        final selected = widget.selectedEnergy.value == widget.label;

        return AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: GestureDetector(
            onTap: () => _handleTap(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? widget.color.withValues(alpha: 0.85)
                    : widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withValues(alpha: selected ? 1.0 : 0.3),
                  width: selected ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: selected ? Colors.white : widget.color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mood chip for quick journaling. Similar to _EnergyChip but uses emojis.
class _MoodChip extends ConsumerStatefulWidget {
  final String emoji;
  final String label;
  final ValueNotifier<String?> selectedMood;

  const _MoodChip({
    required this.emoji,
    required this.label,
    required this.selectedMood,
  });

  @override
  ConsumerState<_MoodChip> createState() => _MoodChipState();
}

class _MoodChipState extends ConsumerState<_MoodChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_scaleCtrl);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    final cycleState = ref.read(cycleControllerProvider);
    if (cycleState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Just a moment…'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.deepInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    _scaleCtrl.forward(from: 0);
    HapticFeedback.lightImpact(); // Subtle chip-select tap
    widget.selectedMood.value = widget.label;
    
    // Log it as a symptom so it appears in analytics.
    ref.read(cycleControllerProvider.notifier).logSymptomOnly('Mood: ${widget.label} ${widget.emoji}');

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mood logged!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.selectedMood,
      builder: (context, _) {
        final selected = widget.selectedMood.value == widget.label;

        return AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: GestureDetector(
            onTap: () => _handleTap(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandAction.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.brandAction.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.grey,
                  selected ? BlendMode.dst : BlendMode.saturation,
                ),
                child: Text(
                  widget.emoji,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Individual Medication Card ────────────────────────────────────────────────

class _MedicationCard extends StatefulWidget {
  final RoutineCardState cardState;
  final VoidCallback onMarkTaken;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    super.key,
    required this.cardState,
    required this.onMarkTaken,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<_MedicationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _celebrationCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.97), weight: 20),
      TweenSequenceItem(
        tween: Tween(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50),
    ]).animate(_celebrationCtrl);
  }

  @override
  void dispose() { _celebrationCtrl.dispose(); super.dispose(); }

  // E-03 fix: Prevent duplicate RoutineLogs from rapid double-taps.
  // The DAO's logIntake() is an upsert, but there's a tiny race window between
  // the getSingleOrNull check and the insert. This bool gate closes that window
  // at the UI layer — the button is re-enabled once the stream pushes isTaken=true.
  bool _isTaking = false;

  void _handleMarkTaken() {
    if (_isTaking) return;
    setState(() => _isTaking = true);
    HapticFeedback.mediumImpact(); // Satisfying confirmation tap
    _celebrationCtrl.forward(from: 0);
    widget.onMarkTaken();
    // The stream update will rebuild this widget with isTaken=true,
    // at which point the button is replaced entirely — no need to reset _isTaking.
  }

  @override
  Widget build(BuildContext context) {
    final cardState = widget.cardState;
    final routine = cardState.routine;
    final phase = cardState.phaseState;
    final isTaken = cardState.todayLog?.status == 'Taken';
    final isBreak = phase.isBreakPeriod;

    final routineDose = (routine.dose != null && routine.dose!.isNotEmpty)
        ? ' (${routine.dose})'
        : '';

    final String phaseText = isBreak
        ? 'Treatment Break · Day ${phase.dayInPhase} / ${phase.totalPhaseDays}'
        : (phase.totalPhaseDays == null)
            ? '${routine.name}$routineDose · Day ${phase.dayInPhase}'
            : '${routine.name}$routineDose · Day ${phase.dayInPhase} / ${phase.totalPhaseDays}';

    final Widget leadingIcon = isBreak
        ? const Icon(Icons.spa, size: 20, color: AppColors.mutedSage)
        : const Icon(Icons.medication, size: 20, color: AppColors.brandAction);

    final String subText = isBreak
        ? 'No medication required today.'
        : 'Scheduled for ${routine.reminderTime}';

    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leadingIcon,
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrivacyBlur(
                            child: Text(
                              phaseText,
                              style: const TextStyle(
                                color: AppColors.deepInk,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PrivacyBlur(
                      child: Text(
                        subText,
                        style: const TextStyle(
                            color: AppColors.mutedSage, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit / Delete menu
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') widget.onEdit();
                  if (val == 'delete') widget.onDelete();
                },
                icon: const Icon(Icons.more_vert,
                    color: AppColors.mutedSage, size: 20),
                color: AppColors.cardBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.deepInk),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Remove',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isBreak) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: isTaken
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check, color: AppColors.mutedSage),
                      label: Text(
                        // E-07 fix: Avoid misleading "Taken at <now>" when completedAt is null.
                        // completedAt should always be set by logIntake() for 'Taken' status,
                        // but a missing value shows '–' rather than the current time.
                        cardState.todayLog?.completedAt != null
                            ? 'Taken at ${DateFormat('h:mm a').format(cardState.todayLog!.completedAt!)}'
                            : 'Taken',
                        style: const TextStyle(color: AppColors.mutedSage),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.lightBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleMarkTaken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAction,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Mark as Taken',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
      child: cardWidget,
    );
  }
}
