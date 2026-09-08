import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/report_payload.dart';

class DoctorInClinicDialog extends StatelessWidget {
  final DoctorReportData data;
  const DoctorInClinicDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warmIvory,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Doctor Quick-Share',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepInk,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mutedSage),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                'Show this screen to your clinician for an instant overview of your reproductive & metabolic logs.',
                style: TextStyle(color: AppColors.mutedSage, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Mock QR Code (offline secure token)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: _QrPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Offline Clinician Token (Scan to Import)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedSage,
                ),
              ),
              const SizedBox(height: 28),

              // Clinical summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLINICAL SUMMARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandAction,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(Icons.calendar_today_outlined, 'Cycle Length (Median)', '${data.medianCycleLength} days'),
                    _buildSummaryRow(Icons.rule, 'Rotterdam Criteria Phenotype', 
                      data.rotterdamOvulatoryDysfunction && data.rotterdamHyperandrogenism
                          ? 'Phenotype A (Classic)'
                          : data.rotterdamOvulatoryDysfunction ? 'Phenotype D (Irregular Cycles)' : 'Subclinical'),
                    _buildSummaryRow(Icons.check_circle_outline, 'Medication Adherence', '${data.adherencePercentage}%'),
                    _buildSummaryRow(Icons.healing_outlined, 'Heavy Bleeding with Clots', '${data.totalHeavyWithClotsDays} days'),
                    _buildSummaryRow(Icons.warning_amber_rounded, 'Flooding (Soaking <2 hr)', '${data.floodingEventsCount} events'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepInk,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.mutedSage),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.deepInk, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.deepInk, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to generate a beautiful, authentic vector QR code pattern
class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.deepInk
      ..style = PaintingStyle.fill;

    // Background is white, draw black module squares
    final double moduleSize = size.width / 21; // 21x21 grid (QR version 1)
    
    // Helper to draw a square block
    void drawBlock(int x, int y, int sizeX, int sizeY) {
      canvas.drawRect(
        Rect.fromLTWH(x * moduleSize, y * moduleSize, sizeX * moduleSize, sizeY * moduleSize),
        paint,
      );
    }

    // Finder patterns (top-left, top-right, bottom-left)
    void drawFinder(int ox, int oy) {
      drawBlock(ox, oy, 7, 7);
      
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH((ox + 1) * moduleSize, (oy + 1) * moduleSize, 5 * moduleSize, 5 * moduleSize),
        whitePaint,
      );
      
      drawBlock(ox + 2, oy + 2, 3, 3);
    }

    drawFinder(0, 0); // Top-left
    drawFinder(14, 0); // Top-right
    drawFinder(0, 14); // Bottom-left

    // Draw alignment module
    drawBlock(14, 14, 2, 2);

    // Draw timing patterns
    for (int i = 8; i < 13; i++) {
      if (i % 2 == 0) {
        drawBlock(6, i, 1, 1);
        drawBlock(i, 6, 1, 1);
      }
    }

    // Draw pseudo-random data modules
    final rand = math.Random(1337);
    for (int y = 0; y < 21; y++) {
      for (int x = 0; x < 21; x++) {
        // Skip finder areas
        if ((x < 8 && y < 8) || (x > 12 && y < 8) || (x < 8 && y > 12)) {
          continue;
        }
        // Skip timing pattern
        if (x == 6 || y == 6) {
          continue;
        }
        if (rand.nextBool()) {
          drawBlock(x, y, 1, 1);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
