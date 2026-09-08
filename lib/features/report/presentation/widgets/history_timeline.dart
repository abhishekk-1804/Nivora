import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cycle/presentation/cycle_controller.dart';
import '../../../../core/database/app_database.dart';

class HistoryTimeline extends ConsumerWidget {
  const HistoryTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleState = ref.watch(cycleControllerProvider);

    return cycleState.when(
      data: (state) {
        final events = state.recentEvents;
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'No history logged yet.',
              style: TextStyle(color: AppColors.mutedSage),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildTimelineItem(context, event, isLast: index == events.length - 1);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brandAction)),
      error: (_, __) => const Center(child: Text('Failed to load timeline.')),
    );
  }

  Widget _buildTimelineItem(BuildContext context, CycleEvent event, {required bool isLast}) {
    final isAnovulatory = event.flowType == 'Anovulatory';
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    color: isAnovulatory ? AppColors.mutedSage : AppColors.brandAction,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.warmIvory, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0, right: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(event.date),
                      style: const TextStyle(
                        color: AppColors.deepInk,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (isAnovulatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mutedSage.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Anovulatory / Missed Cycle', style: TextStyle(color: AppColors.charcoalInk, fontSize: 12)),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(Icons.water_drop, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text('${event.flowType} Flow', style: const TextStyle(fontSize: 13, color: AppColors.charcoalInk)),
                          if (event.painIntensity != null && event.painIntensity! > 0) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.bolt, size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            Text('Pain: ${event.painIntensity}/10', style: const TextStyle(fontSize: 13, color: AppColors.charcoalInk)),
                          ]
                        ],
                      ),
                      
                      if (event.symptoms != null && event.symptoms!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: event.symptoms!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).map((symptom) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.deepInk.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: Text(symptom, style: const TextStyle(fontSize: 11, color: AppColors.deepInk)),
                            );
                          }).toList(),
                        ),
                      ]
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
