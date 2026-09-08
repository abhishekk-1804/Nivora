import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class IllustrationCaughtUp extends StatelessWidget {
  final double size;

  const IllustrationCaughtUp({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CaughtUpPainter(),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.03, 0.97),
      duration: 2000.ms,
      curve: Curves.easeInOutSine,
    );
  }
}

class _CaughtUpPainter extends CustomPainter {
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

    // 1. Pillow (Background)
    canvas.save();
    canvas.translate(w * 0.5, h * 0.75);
    canvas.rotate(-0.05);
    final pillowRect = RRect.fromLTRBR(-w * 0.4, -h * 0.15, w * 0.4, h * 0.15, Radius.circular(h * 0.05));
    canvas.drawRRect(pillowRect, roseFill);
    canvas.drawRRect(pillowRect, strokePaint);
    canvas.restore();

    // 2. Lumi the Cloud (Body)
    final path1 = Path()..addRRect(RRect.fromLTRBR(w * 0.2, h * 0.45, w * 0.8, h * 0.75, Radius.circular(h * 0.15)));
    final path2 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.4, h * 0.45), radius: w * 0.15));
    final path3 = Path()..addOval(Rect.fromCircle(center: Offset(w * 0.65, h * 0.55), radius: w * 0.18));
    
    var cloudPath = Path.combine(PathOperation.union, path1, path2);
    cloudPath = Path.combine(PathOperation.union, cloudPath, path3);

    canvas.drawPath(cloudPath, fillPaint);
    canvas.drawPath(cloudPath, strokePaint);

    // 3. Sleeping Eyes (Arcs)
    final eyePath = Path();
    eyePath.moveTo(w * 0.35, h * 0.6);
    eyePath.quadraticBezierTo(w * 0.4, h * 0.65, w * 0.45, h * 0.6);
    
    eyePath.moveTo(w * 0.55, h * 0.6);
    eyePath.quadraticBezierTo(w * 0.6, h * 0.65, w * 0.65, h * 0.6);
    
    canvas.drawPath(eyePath, strokePaint);

    // 4. Blush
    canvas.drawCircle(Offset(w * 0.32, h * 0.65), w * 0.04, roseFill);
    canvas.drawCircle(Offset(w * 0.68, h * 0.65), w * 0.04, roseFill);

    // 5. Zzz (Floating above)
    final zPaint = Paint()
      ..color = AppColors.brandAction
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final zPath = Path();
    // Big Z
    zPath.moveTo(w * 0.65, h * 0.2);
    zPath.lineTo(w * 0.75, h * 0.2);
    zPath.lineTo(w * 0.65, h * 0.3);
    zPath.lineTo(w * 0.75, h * 0.3);
    // Small Z
    zPath.moveTo(w * 0.8, h * 0.1);
    zPath.lineTo(w * 0.85, h * 0.1);
    zPath.lineTo(w * 0.8, h * 0.15);
    zPath.lineTo(w * 0.85, h * 0.15);

    canvas.drawPath(zPath, zPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
