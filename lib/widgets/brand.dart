import 'package:flutter/material.dart';

import '../theme/gm_theme.dart';

/// Marca do GM Fitness: uma anilha vista de frente com as letras GM.
class GmLogo extends StatelessWidget {
  const GmLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _LogoPainter()));
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, s * 0.5, Paint()..color = GmColors.blue);
    canvas.drawCircle(
        c,
        s * 0.40,
        Paint()
          ..color = GmColors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.07);
    final tp = TextPainter(
      text: TextSpan(
        text: 'GM',
        style: TextStyle(
          fontFamily: display,
          fontWeight: FontWeight.w800,
          fontSize: s * 0.42,
          color: Colors.white,
          letterSpacing: -s * 0.01,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2 - s * 0.01));
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

/// Logo com o nome, para cabeçalhos.
class GmWordmark extends StatelessWidget {
  const GmWordmark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GmLogo(size: size),
        SizedBox(width: size * 0.3),
        Text(
          'GM Fitness',
          style: TextStyle(
            fontFamily: display,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.75,
            color: ink,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Faixa colorida com as cores das anilhas, usada como assinatura visual.
class PlateStripe extends StatelessWidget {
  const PlateStripe({super.key, this.height = 6});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final (i, c) in GmColors.cycle.indexed) Expanded(flex: i == 0 ? 3 : 1, child: ColoredBox(color: c)),
          ],
        ),
      ),
    );
  }
}
