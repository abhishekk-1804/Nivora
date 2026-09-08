import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class CycleGraph extends StatelessWidget {
  final int currentDay;

  const CycleGraph({super.key, required this.currentDay});

  @override
  Widget build(BuildContext context) {
    // PCOS Extreme Cycle Guardrail: Cap visual aspect ratio at 45 days
    final bool isPCOS = currentDay > 45;
    final int displayDay = isPCOS ? 45 : currentDay;
    final double progress = displayDay / 45.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.mutedSage.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Cycle',
                style: TextStyle(
                  color: AppColors.deepInk,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPCOS)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Extended Cycle (>45d)',
                    style: TextStyle(
                      color: AppColors.brandAction,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.dustyBlush, AppColors.brandAction],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Day 1', style: TextStyle(color: AppColors.mutedSage, fontSize: 12)),
              Text('Day $currentDay', style: const TextStyle(color: AppColors.deepInk, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }
}
