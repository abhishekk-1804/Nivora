import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

/// T2-3: First-time user guidance overlay.
///
/// Shows a gentle coach-mark modal the very first time a new user opens the
/// Today screen. Dismissed on tap and never shown again (caller handles
/// SharedPreferences persistence via [onDismiss]).
///
/// Usage:
/// ```dart
/// if (shouldShowGuide) {
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     showDialog(context: context, builder: (_) => FirstUseGuideOverlay(
///       onDismiss: () => prefs.setBool('seen_today_guide', true),
///     ));
///   });
/// }
/// ```
class FirstUseGuideOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const FirstUseGuideOverlay({super.key, required this.onDismiss});

  static const _steps = [
    _GuideStep(
      icon: Icons.favorite_border_rounded,
      color: AppColors.brandAction,
      title: 'Log your cycle',
      body:
          'Tap the red "Log Cycle" card to record your period, flow, pain, and symptoms. No perfect data needed — log what you have.',
    ),
    _GuideStep(
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFF2E7D32),
      title: 'Check in daily',
      body:
          'Tap the Energy and Mood chips each morning. These micro-logs build into symptom patterns the clinical report uses.',
    ),
    _GuideStep(
      icon: Icons.medication_outlined,
      color: Color(0xFF1565C0),
      title: 'Track your medication',
      body:
          'Set up a routine once via the ＋ button. Every day, tap "Mark as Taken" — Nivora tracks adherence automatically.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: _GuideCard(onDismiss: onDismiss),
    );
  }
}

class _GuideCard extends StatefulWidget {
  final VoidCallback onDismiss;
  const _GuideCard({required this.onDismiss});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  int _currentStep = 0;

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentStep < FirstUseGuideOverlay._steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismiss();
      Navigator.of(context).pop();
    }
  }

  void _skip() {
    HapticFeedback.lightImpact();
    widget.onDismiss();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = FirstUseGuideOverlay._steps[_currentStep];
    final isLast = _currentStep == FirstUseGuideOverlay._steps.length - 1;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(FirstUseGuideOverlay._steps.length, (i) {
              final active = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.brandAction
                      : AppColors.brandAction.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Icon
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_currentStep),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: step.color, size: 36),
            ).animate().scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.elasticOut,
                  duration: 500.ms,
                ),
          ),
          const SizedBox(height: 20),

          // Title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              key: ValueKey('title_$_currentStep'),
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.deepInk,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              key: ValueKey('body_$_currentStep'),
              step.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.mutedSage,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              // Skip (only on non-last steps)
              if (!isLast)
                Expanded(
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.mutedSage, fontSize: 15),
                    ),
                  ),
                ),
              if (!isLast) const SizedBox(width: 12),
              Expanded(
                flex: isLast ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandAction,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Get started' : 'Next',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }
}

class _GuideStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _GuideStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
