import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:imyra_app/core/diagnostics/error_logger.dart';

void main() {
  testWidgets('Generate assets', (tester) async {
    final directory = Directory('assets/branding');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1024, 1024));

    // Background: Crisp White
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), Paint()..color = const Color(0xFFFAFAFA));

    canvas.save();
    // Center and scale the geometry
    canvas.translate(332, 180); 

    // 1. Cycle Dot (Imyra Rose)
    canvas.drawCircle(
      const Offset(180, 120), 
      120, 
      Paint()..color = const Color(0xFFF43F5E)..isAntiAlias = true
    );

    // 2. Routine Capsule (Onyx Black)
    final stemPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(180, 520), width: 240, height: 480),
        const Radius.circular(120),
      ));
    canvas.drawPath(stemPath, Paint()..color = const Color(0xFF111111)..isAntiAlias = true);

    canvas.restore();

    final picture = recorder.endRecording();
    
    // Using tester.runAsync prevents the headless test environment from hanging during Image rasterization
    await tester.runAsync(() async {
      final img = await picture.toImage(1024, 1024);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await File('assets/branding/imyra_icon.png').writeAsBytes(pngBytes);
      await File('assets/branding/imyra_splash.png').writeAsBytes(pngBytes);
      await File('assets/branding/imyra_icon_foreground.png').writeAsBytes(pngBytes);
    });

    ErrorLogger.info('Bold, high-contrast production icons generated successfully.');
  });
}
