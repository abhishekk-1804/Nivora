import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CalmEmptyStateIllustration extends StatelessWidget {
  final double width;
  final double height;

  const CalmEmptyStateIllustration({super.key, this.width = 180, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CalmEmptyStatePainter(),
      ),
    );
  }
}

class _CalmEmptyStatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()
      ..color = AppColors.deepInk.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final sagePaint = Paint()
      ..color = AppColors.mutedSage
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final peachFill = Paint()
      ..color = AppColors.subtlePeach.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Subtle background sun/moon glow
    canvas.drawCircle(Offset(w * 0.65, h * 0.4), 32, peachFill);

    // Large bottom pebble
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: 84, height: 28),
      inkPaint,
    );

    // Medium middle pebble
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.49, h * 0.60), width: 56, height: 20),
      inkPaint,
    );

    // Small top stone
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.52, h * 0.46), width: 34, height: 14),
      inkPaint,
    );

    // Resting Botanical Leaf Branch
    final leafPath = Path();
    leafPath.moveTo(w * 0.52, h * 0.46);
    leafPath.quadraticBezierTo(w * 0.35, h * 0.30, w * 0.25, h * 0.35);
    canvas.drawPath(leafPath, sagePaint);

    // Leaf buds
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.38, h * 0.34), width: 10, height: 6), sagePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.28, h * 0.33), width: 8, height: 5), sagePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
