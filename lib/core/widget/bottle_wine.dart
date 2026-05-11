import 'package:flutter/material.dart';

class AbstractWineBottle extends StatelessWidget {
  final String? type;
  final double size;

  const AbstractWineBottle({super.key, this.type, this.size = 100});

  Color _getWineColor() {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('red')) return const Color(0xFF800020);
    if (t.contains('white')) return const Color(0xFFF3E5AB);
    if (t.contains('rose') || t.contains('rosé')) return const Color(0xFFFF8C94);
    if (t.contains('sparkling')) return const Color(0xFFE5D681);
    return Colors.grey.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.4, size),
      painter: BottlePainter(color: _getWineColor()),
    );
  }
}

class BottlePainter extends CustomPainter {
  final Color color;
  BottlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    double w = size.width;
    double h = size.height;

    path.moveTo(w * 0.35, h * 0.05);
    path.lineTo(w * 0.65, h * 0.05);
    path.lineTo(w * 0.65, h * 0.25);

    path.quadraticBezierTo(w * 0.95, h * 0.35, w, h * 0.5);

    path.lineTo(w, h * 0.9);
    path.quadraticBezierTo(w, h, w * 0.8, h);
    path.lineTo(w * 0.2, h);
    path.quadraticBezierTo(0, h, 0, h * 0.9);

    path.lineTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.05, h * 0.35, w * 0.35, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.1, h * 0.4), highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
