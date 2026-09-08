import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class IllustrationRoutine extends StatelessWidget {
  final double size;

  const IllustrationRoutine({
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
          // Background sprout and jar
          CustomPaint(
            size: Size(size, size),
            painter: _RoutineBackgroundPainter(),
          ),
          // Water droplets dropping
          CustomPaint(
            size: Size(size, size),
            painter: _RoutineWaterPainter(),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .slideY(
            begin: 0.0,
            end: 0.2,
            duration: 1000.ms,
            curve: Curves.easeIn,
          )
          .fadeIn(duration: 200.ms)
          .fadeOut(delay: 800.ms, duration: 200.ms),
        ],
      ),
    );
  }
}

class _RoutineBackgroundPainter extends CustomPainter {
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

    // 1. Little Jar/Pot
    final potPath = Path();
    potPath.moveTo(w * 0.7, h * 0.8);
    potPath.lineTo(w * 0.75, h * 0.6);
    potPath.lineTo(w * 0.95, h * 0.6);
    potPath.lineTo(w * 0.9, h * 0.8);
    potPath.close();
    
    canvas.drawPath(potPath, fillPaint);
    canvas.drawPath(potPath, roseFill);
    canvas.drawPath(potPath, strokePaint);

    // 2. Sprout inside jar
    final sproutPath = Path();
    sproutPath.moveTo(w * 0.85, h * 0.6);
    sproutPath.quadraticBezierTo(w * 0.8, h * 0.5, w * 0.85, h * 0.4);
    canvas.drawPath(sproutPath, strokePaint);
    
    // Leaf 1
    final leaf1 = Path();
    leaf1.moveTo(w * 0.83, h * 0.45);
    leaf1.quadraticBezierTo(w * 0.75, h * 0.42, w * 0.78, h * 0.5);
    leaf1.quadraticBezierTo(w * 0.85, h * 0.48, w * 0.83, h * 0.45);
    canvas.drawPath(leaf1, strokePaint..style = PaintingStyle.fill);
    
    // Leaf 2
    final leaf2 = Path();
    leaf2.moveTo(w * 0.86, h * 0.4);
    leaf2.quadraticBezierTo(w * 0.95, h * 0.35, w * 0.92, h * 0.45);
    leaf2.quadraticBezierTo(w * 0.85, h * 0.42, w * 0.86, h * 0.4);
    canvas.drawPath(leaf2, strokePaint..style = PaintingStyle.fill);
    
    strokePaint.style = PaintingStyle.stroke;

    // 3. Lumi the Cloud (Body hovering)
    canvas.save();
    canvas.translate(-w * 0.1, -h * 0.1);
    
    final path1 = Path()..addRRect(RRect.fromLTRBR(w * 0.2, h * 0.45, w * 0.8, h * 0.75, Radius.circular(h * 0.15)));
    final path2 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.4, h * 0.45), radius: w * 0.15));
    final path3 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.65, h * 0.55), radius: w * 0.18));
    
    var cloudPath = Path.combine(PathOperation.union, path1, path2);
    cloudPath = Path.combine(PathOperation.union, cloudPath, path3);

    canvas.drawPath(cloudPath, fillPaint);
    canvas.drawPath(cloudPath, strokePaint);

    // Eyes looking down (v v)
    final eyePath = Path();
    eyePath.moveTo(w * 0.55, h * 0.6);
    eyePath.lineTo(w * 0.6, h * 0.65);
    eyePath.lineTo(w * 0.65, h * 0.6);
    
    eyePath.moveTo(w * 0.75, h * 0.6);
    eyePath.lineTo(w * 0.8, h * 0.65);
    eyePath.lineTo(w * 0.85, h * 0.6);
    
    canvas.drawPath(eyePath, strokePaint);

    // Blush
    canvas.drawCircle(Offset(w * 0.52, h * 0.65), w * 0.04, roseFill);
    canvas.drawCircle(Offset(w * 0.88, h * 0.65), w * 0.04, roseFill);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutineWaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final waterPaint = Paint()
      ..color = AppColors.brandAction.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // A few scattered drops falling from Lumi to the sprout
    canvas.drawCircle(Offset(w * 0.75, h * 0.35), w * 0.015, waterPaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.3), w * 0.02, waterPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.38), w * 0.015, waterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
