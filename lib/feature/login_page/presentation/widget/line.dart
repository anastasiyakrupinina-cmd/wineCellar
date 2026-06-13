import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wine_cellar/core/colors/app_colors.dart';

class WineLinesPainter extends CustomPainter {
  final double progress;
  WineLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);

    _drawBlurBlob(
      canvas,
      color: AppColors.lightBlue.withValues(alpha: 0.15),
      offset: Offset(size.width * 0.2, size.height * 0.2),
      radius: 150 + (math.sin(progress * math.pi) * 30),
    );

    _drawBlurBlob(
      canvas,
      color: AppColors.lightGreen.withValues(alpha: 0.1),
      offset: Offset(size.width * 0.8, size.height * 0.5),
      radius: 200 + (math.cos(progress * math.pi) * 40),
    );

    final geoPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.darkBlue.withValues(alpha: 0.1);

    canvas.save();
    canvas.translate(center.dx, center.dy * 0.5);
    canvas.rotate(progress * math.pi * 0.2);
    canvas.drawCircle(Offset.zero, 120, geoPaint);
    canvas.drawCircle(Offset.zero, 130, geoPaint);

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(const Offset(0, 110), const Offset(0, 140), geoPaint);
      canvas.rotate(math.pi / 4);
    }
    canvas.restore();

    _drawWave(
      canvas,
      size,
      color: AppColors.darkBlue.withValues(alpha: 0.05),
      amplitude: 20,
      speed: progress * 2 * math.pi,
      yOffset: 0.88,
    );

    _drawWave(
      canvas,
      size,
      color: AppColors.lightBlue.withValues(alpha: 0.08),
      amplitude: 15,
      speed: (progress + 0.5) * 2 * math.pi,
      yOffset: 0.9,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          AppColors.darkBlue.withValues(alpha: 0),
          AppColors.darkBlue.withValues(alpha: 0.2),
          AppColors.darkBlue.withValues(alpha: 0),
        ],
      ).createShader(rect);

    for (int i = 0; i < 2; i++) {
      final path = Path();
      double y = size.height * (0.3 + i * 0.4);
      path.moveTo(-50, y);
      path.cubicTo(
        size.width * 0.5,
        y + (math.sin(progress * 2 * math.pi) * 100),
        size.width * 0.5,
        y - (math.sin(progress * 2 * math.pi) * 100),
        size.width + 50,
        y,
      );
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawBlurBlob(Canvas canvas, {required Color color, required Offset offset, required double radius}) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(offset, radius, paint);
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double amplitude,
    required double speed,
    required double yOffset,
  }) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height * yOffset);

    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, size.height * yOffset + math.sin((x / size.width * 2 * math.pi) + speed) * amplitude);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WineLinesPainter oldDelegate) => oldDelegate.progress != progress;
}
