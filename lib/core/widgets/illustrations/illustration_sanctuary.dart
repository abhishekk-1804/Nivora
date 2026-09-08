import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class IllustrationSanctuary extends StatelessWidget {
  final double size;

  const IllustrationSanctuary({
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
          // The background lock doesn't animate
          CustomPaint(
            size: Size(size, size),
            painter: _SanctuaryLockPainter(),
          ),
          // Lumi hovering in front
          CustomPaint(
            size: Size(size, size),
            painter: _SanctuaryLumiPainter(),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .slideY(
            begin: -0.02,
            end: 0.02,
            duration: 2000.ms,
            curve: Curves.easeInOutSine,
          ),
        ],
      ),
    );
  }
}

class _SanctuaryLockPainter extends CustomPainter {
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

    final roseFill = Paint()
      ..color = AppColors.brandAction.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Center the lock
    canvas.save();
    canvas.translate(w * 0.45, h * 0.5);

    // Lock Shackle
    final shacklePath = Path();
    shacklePath.moveTo(-w * 0.15, -h * 0.1);
    shacklePath.lineTo(-w * 0.15, -h * 0.25);
    shacklePath.arcToPoint(
      Offset(w * 0.15, -h * 0.25),
      radius: Radius.circular(w * 0.15),
      clockwise: true,
    );
    shacklePath.lineTo(w * 0.15, -h * 0.1);
    canvas.drawPath(shacklePath, strokePaint);

    // Lock Body
    final lockBody = RRect.fromLTRBR(-w * 0.25, -h * 0.1, w * 0.25, h * 0.3, Radius.circular(h * 0.08));
    canvas.drawRRect(lockBody, roseFill);
    canvas.drawRRect(lockBody, strokePaint);

    // Keyhole
    canvas.drawCircle(Offset(0, h * 0.05), w * 0.04, strokePaint..style = PaintingStyle.fill);
    final keyholeDrop = Path();
    keyholeDrop.moveTo(-w * 0.02, h * 0.05);
    keyholeDrop.lineTo(0, h * 0.15);
    keyholeDrop.lineTo(w * 0.02, h * 0.05);
    canvas.drawPath(keyholeDrop, strokePaint..style = PaintingStyle.fill);
    
    // Reset stroke style
    strokePaint.style = PaintingStyle.stroke;

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SanctuaryLumiPainter extends CustomPainter {
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

    // Offset Lumi slightly to the left, peeking out
    canvas.save();
    canvas.translate(-w * 0.1, h * 0.1);

    // 1. Lumi the Cloud (Body)
    final path1 = Path()..addRRect(RRect.fromLTRBR(w * 0.2, h * 0.45, w * 0.8, h * 0.75, Radius.circular(h * 0.15)));
    final path2 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.4, h * 0.45), radius: w * 0.15));
    final path3 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.65, h * 0.55), radius: w * 0.18));
    
    var cloudPath = Path.combine(PathOperation.union, path1, path2);
    cloudPath = Path.combine(PathOperation.union, cloudPath, path3);

    canvas.drawPath(cloudPath, fillPaint);
    canvas.drawPath(cloudPath, strokePaint);

    // 2. Closed Happy Eyes (Arcs)
    final eyePath = Path();
    eyePath.moveTo(w * 0.55, h * 0.6);
    eyePath.quadraticBezierTo(w * 0.6, h * 0.55, w * 0.65, h * 0.6);
    
    eyePath.moveTo(w * 0.75, h * 0.6);
    eyePath.quadraticBezierTo(w * 0.8, h * 0.55, w * 0.85, h * 0.6);
    
    canvas.drawPath(eyePath, strokePaint);

    // 3. Blush
    canvas.drawCircle(Offset(w * 0.52, h * 0.65), w * 0.04, roseFill);
    canvas.drawCircle(Offset(w * 0.88, h * 0.65), w * 0.04, roseFill);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
