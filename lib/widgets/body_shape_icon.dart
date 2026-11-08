import 'package:flutter/material.dart';

/// Silhueta simples para cada formato de corpo das pré-definições.
class BodyShapeIcon extends StatelessWidget {
  const BodyShapeIcon({super.key, required this.shape, this.size = 56, this.color});

  final String shape;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    if (shape == 'iniciante') {
      return SizedBox(width: size, height: size, child: Icon(Icons.directions_walk_rounded, size: size * 0.8, color: c));
    }
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _ShapePainter(shape, c)));
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);

  final String shape;
  final Color color;

  // ombros, cintura, quadril
  static const _widths = {
    'triangulo_invertido': [1.0, 0.62, 0.56],
    'triangulo': [0.58, 0.6, 1.0],
    'ampulheta': [0.92, 0.5, 0.92],
    'retangulo': [0.8, 0.76, 0.8],
    'oval': [0.72, 0.98, 0.76],
    'm_trapezio': [1.04, 0.66, 0.68],
    'm_triangulo_invertido': [1.1, 0.72, 0.62],
    'm_retangulo': [0.84, 0.82, 0.8],
    'm_triangulo': [0.66, 0.84, 0.92],
    'm_oval': [0.8, 1.04, 0.82],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = _widths[shape] ?? const [0.8, 0.6, 0.8];
    final male = shape.startsWith('m_');
    final s = size.shortestSide;
    final cx = size.width / 2;
    final half = s * 0.3;
    final paint = Paint()..color = color;
    final yHead = s * 0.12, yShoulder = s * 0.26, yWaist = s * 0.5, yHip = s * (male ? 0.66 : 0.7), yBottom = s * 0.78;
    canvas.drawCircle(Offset(cx, yHead), s * 0.085, paint);
    final p = Path()
      ..moveTo(cx - w[0] * half, yShoulder)
      ..lineTo(cx + w[0] * half, yShoulder)
      ..quadraticBezierTo(cx + w[1] * half * 1.05, (yShoulder + yWaist) / 2, cx + w[1] * half, yWaist)
      ..quadraticBezierTo(cx + w[2] * half * (male ? 1.0 : 1.08), (yWaist + yHip) / 2, cx + w[2] * half, yHip)
      ..lineTo(cx + w[2] * half * 0.9, yBottom)
      ..lineTo(cx - w[2] * half * 0.9, yBottom)
      ..lineTo(cx - w[2] * half, yHip)
      ..quadraticBezierTo(cx - w[2] * half * (male ? 1.0 : 1.08), (yWaist + yHip) / 2, cx - w[1] * half, yWaist)
      ..quadraticBezierTo(cx - w[1] * half * 1.05, (yShoulder + yWaist) / 2, cx - w[0] * half, yShoulder)
      ..close();
    canvas.drawPath(p, paint);
    final legPaint = Paint()..color = color.withAlpha(150);
    final legW = shape == 'm_triangulo_invertido' ? 0.6 : 0.85;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(cx - w[2] * half * legW, yBottom, cx - s * 0.03, s * 0.98),
            Radius.circular(s * 0.04)),
        legPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(cx + s * 0.03, yBottom, cx + w[2] * half * legW, s * 0.98),
            Radius.circular(s * 0.04)),
        legPaint);
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.shape != shape || old.color != color;
}
