import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/report_payload.dart';

class DoctorInClinicDialog extends StatelessWidget {
  final DoctorReportData data;
  final VoidCallback? onExportPdf;

  const DoctorInClinicDialog({
    super.key,
    required this.data,
    this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlooding = data.floodingEventsCount > 0;
    final hasHeavyBleeding = data.totalHeavyWithClotsDays > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.brandAction,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In-Clinic Quick Glance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoalInk,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.dateRange,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mutedText, size: 20),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.mutedText),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Present this screen directly to your clinician during consultation for quick clinical parameters.',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'MEDIAN CYCLE',
                      value: data.medianCycleLength > 0 ? '${data.medianCycleLength}d' : 'N/A',
                      subtext: data.totalCycles > 0 ? 'Range: ${data.cycleRangeMin}–${data.cycleRangeMax}d' : '0 cycles logged',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'TOTAL CYCLES',
                      value: '${data.totalCycles}',
                      subtext: 'Observed window',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'ADHERENCE',
                      value: '${data.adherencePercentage}%',
                      subtext: 'Protocol logs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Clinical summary section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLINICAL PARAMETERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandAction,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      icon: Icons.rule_folder_outlined,
                      label: 'Rotterdam Phenotype',
                      value: _getRotterdamLabel(),
                      isHighlight: data.rotterdamOvulatoryDysfunction,
                    ),
                    _buildSummaryRow(
                      icon: Icons.opacity_outlined,
                      label: 'Heavy Bleeding Days (Clots)',
                      value: '${data.totalHeavyWithClotsDays} days',
                      isAlert: hasHeavyBleeding,
                    ),
                    _buildSummaryRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Flooding Events (Soaking <2h)',
                      value: '${data.floodingEventsCount} events',
                      isAlert: hasFlooding,
                    ),
                    _buildSummaryRow(
                      icon: Icons.colorize_outlined,
                      label: 'Spotting Profile',
                      value: data.spottingColorProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.charcoalInk),
                      ),
                    ),
                  ),
                  if (onExportPdf != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onExportPdf!();
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text(
                          'Export Full PDF',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAction,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRotterdamLabel() {
    if (data.rotterdamOvulatoryDysfunction && data.rotterdamHyperandrogenism) {
      return 'Phenotype A (Classic)';
    } else if (data.rotterdamOvulatoryDysfunction) {
      return 'Phenotype D (Irregular Cycles)';
    } else if (data.rotterdamHyperandrogenism) {
      return 'Hyperandrogenic Only';
    }
    return 'Subclinical / Normal';
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedText,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoalInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isAlert = false,
    bool isHighlight = false,
  }) {
    Color textColor = AppColors.charcoalInk;
    if (isAlert) {
      textColor = AppColors.alertRed;
    } else if (isHighlight) {
      textColor = AppColors.brandAction;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isAlert ? AppColors.alertRed : AppColors.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.charcoalInk,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: (isAlert || isHighlight) ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
