import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class IllustrationReport extends StatelessWidget {
  final double size;

  const IllustrationReport({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The background/body doesn't need to rotate
          CustomPaint(
            size: Size(size, size),
            painter: _ReportBackgroundPainter(),
          ),
          // Only the magnifying glass sways
          CustomPaint(
            size: Size(size, size),
            painter: _MagnifyingGlassPainter(),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .rotate(
            begin: -0.05,
            end: 0.05,
            duration: 1500.ms,
            curve: Curves.easeInOutSine,
          ),
        ],
      ),
    );
  }
}

class _ReportBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = AppColors.charcoalInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = AppColors.warmCanvas
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final roseFill = Paint()
      ..color = AppColors.brandAction.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Lumi the Cloud (Body)
    final path1 = Path()..addRRect(RRect.fromLTRBR(w * 0.2, h * 0.45, w * 0.8, h * 0.75, Radius.circular(h * 0.15)));
    final path2 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.4, h * 0.45), radius: w * 0.15));
    final path3 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.65, h * 0.55), radius: w * 0.18));
    
    var cloudPath = Path.combine(PathOperation.union, path1, path2);
    cloudPath = Path.combine(PathOperation.union, cloudPath, path3);

    canvas.drawPath(cloudPath, fillPaint);
    canvas.drawPath(cloudPath, strokePaint);

    // 2. Open Eyes (Circles)
    final eyePaint = Paint()
      ..color = AppColors.charcoalInk
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(w * 0.38, h * 0.6), w * 0.02, eyePaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.6), w * 0.02, eyePaint);

    // 3. Blush
    canvas.drawCircle(Offset(w * 0.3, h * 0.65), w * 0.04, roseFill);
    canvas.drawCircle(Offset(w * 0.6, h * 0.65), w * 0.04, roseFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MagnifyingGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = AppColors.charcoalInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final glassFill = Paint()
      ..color = AppColors.brandAction.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Anchor rotation near the "hand"
    canvas.translate(w * 0.7, h * 0.65);
    
    // Handle
    canvas.drawLine(Offset.zero, Offset(w * 0.15, h * 0.15), strokePaint);
    
    // Glass Center (offset from handle)
    final glassCenter = Offset(-w * 0.15, -h * 0.15);
    canvas.drawCircle(glassCenter, w * 0.15, glassFill);
    canvas.drawCircle(glassCenter, w * 0.15, strokePaint);

    // Little reflection line
    final reflectionPaint = Paint()
      ..color = AppColors.brandAction.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
      
    canvas.drawArc(
      Rect.fromCircle(center: glassCenter, radius: w * 0.1),
      -3.14159 / 4,
      3.14159 / 3,
      false,
      reflectionPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
