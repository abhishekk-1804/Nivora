import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ImyraLogo extends StatelessWidget {
  final double size;
  final bool monochrome;

  const ImyraLogo({
    super.key,
    this.size = 32,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ImyraGeometricPainter(
          brandColor: monochrome ? AppColors.charcoalInk : AppColors.brandAction,
          inkColor: AppColors.charcoalInk,
        ),
      ),
    );
  }
}

class _ImyraGeometricPainter extends CustomPainter {
  final Color brandColor;
  final Color inkColor;

  _ImyraGeometricPainter({required this.brandColor, required this.inkColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. The Cycle Dot (Brand Color)
    final dotPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    
    canvas.drawCircle(Offset(w * 0.50, h * 0.18), w * 0.18, dotPaint);

    // 2. The Routine Capsule / Stem (Onyx)
    final stemPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stemPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.68), width: w * 0.36, height: h * 0.60),
        Radius.circular(w * 0.18), // Perfectly rounded pill caps
      ));
    
    canvas.drawPath(stemPath, stemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
