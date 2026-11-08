import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'motion_clip.dart';

/// Cores da pessoa e do cenário.
class FigurePalette {
  const FigurePalette({
    required this.background,
    required this.floor,
    required this.floorLine,
    required this.equipment,
    required this.equipmentDark,
    required this.pad,
  });

  final Color background;
  final Color floor;
  final Color floorLine;
  final Color equipment;
  final Color equipmentDark;
  final Color pad;

  static const light = FigurePalette(
    background: Color(0xFFF4F1EA),
    floor: Color(0xFFE6E0D4),
    floorLine: Color(0xFFCFC7B8),
    equipment: Color(0xFF6B6F80),
    equipmentDark: Color(0xFF3A3D4A),
    pad: Color(0xFF5B4E77),
  );

  static const dark = FigurePalette(
    background: Color(0xFF23242B),
    floor: Color(0xFF2D2E36),
    floorLine: Color(0xFF3E3F49),
    equipment: Color(0xFF8A8FA3),
    equipmentDark: Color(0xFF5C6070),
    pad: Color(0xFF7C6C9E),
  );

  // Pessoa (iguais nos dois temas)
  static const skin = Color(0xFFE2A57F);
  static const skinFar = Color(0xFFC48765);
  static const skinShade = Color(0xFFB97A57);
  static const top = Color(0xFFE0457B);
  static const topFar = Color(0xFFB8335F);
  static const legging = Color(0xFF2F3250);
  static const leggingFar = Color(0xFF20223A);
  static const hair = Color(0xFF3B2416);
  static const shoe = Color(0xFFF7F7F7);
  static const shoeFar = Color(0xFFD9D9DE);
  static const sole = Color(0xFF9A9AA5);
  static const eye = Color(0xFF2A1A12);
  static const iron = Color(0xFF2B2B30);
  static const ironLight = Color(0xFF55555E);
  static const cable = Color(0xFF1F1F24);
  static const band = Color(0xFF43B581);
}

Color _darken(Color c, [double amount = 0.35]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
}

Offset _dir(double deg) {
  final r = deg * math.pi / 180.0;
  return Offset(math.sin(r), -math.cos(r));
}

Offset _unit(Offset v) {
  final d = v.distance;
  return d < 1e-6 ? const Offset(0, -1) : v / d;
}

Offset _cw(Offset v) => Offset(-v.dy, v.dx);

/// Desenha um quadro do movimento: cenário, equipamentos e a pessoa.
class FigurePainter extends CustomPainter {
  FigurePainter({required this.clip, required this.time, required this.palette});

  final MotionClip clip;
  final double time;
  final FigurePalette palette;

  late Float32List _f;

  Offset _p(int joint) => Offset(_f[joint * 2], _f[joint * 2 + 1]);

  Offset _tp(int index) => Offset(_f[Jt.trackedBase + index * 2], _f[Jt.trackedBase + index * 2 + 1]);

  @override
  void paint(Canvas canvas, Size size) {
    if (clip.frameCount == 0 || size.isEmpty) return;
    _f = clip.sample(time);
    final vp = clip.viewport;
    final scale = math.min(size.width / vp.width, size.height / vp.height);
    final dx = (size.width - vp.width * scale) / 2 - vp.left * scale;
    final dy = (size.height - vp.height * scale) / 2 - vp.top * scale;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final left = -dx / scale - 10;
    final right = (size.width - dx) / scale + 10;
    final bottom = (size.height - dy) / scale + 10;
    canvas.drawRect(Rect.fromLTRB(left, kGroundY, right, bottom), Paint()..color = palette.floor);
    canvas.drawLine(Offset(left, kGroundY), Offset(right, kGroundY),
        Paint()
          ..color = palette.floorLine
          ..strokeWidth = 0.8);

    _shadow(canvas);
    for (final pr in clip.props) {
      if (pr.track.isEmpty) _staticProp(canvas, pr);
    }
    for (final pr in clip.props) {
      if (pr.track.isNotEmpty && _behind.contains(pr.type)) _trackedProp(canvas, pr);
    }
    if (clip.isFront) {
      _figureFront(canvas);
    } else {
      _figureSide(canvas);
    }
    for (final pr in clip.props) {
      if (pr.track.isNotEmpty && !_behind.contains(pr.type)) _trackedProp(canvas, pr);
    }
    canvas.restore();
  }

  static const _behind = {'cable', 'cablev', 'lever', 'pad', 'sled'};

  // ------------------------------------------------------------ formas básicas

  void _capsule(Canvas c, Offset a, Offset b, double ra, double rb, Color color, {double outline = 0.55}) {
    if (outline > 0) {
      _capsuleFill(c, a, b, ra + outline, rb + outline, _darken(color, 0.4));
    }
    _capsuleFill(c, a, b, ra, rb, color);
  }

  void _capsuleFill(Canvas c, Offset a, Offset b, double ra, double rb, Color color) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final d = b - a;
    final len = d.distance;
    if (len > 0.01) {
      final u = d / len;
      final n = _cw(u);
      final path = Path()
        ..moveTo(a.dx + n.dx * ra, a.dy + n.dy * ra)
        ..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)
        ..lineTo(b.dx - n.dx * rb, b.dy - n.dy * rb)
        ..lineTo(a.dx - n.dx * ra, a.dy - n.dy * ra)
        ..close();
      c.drawPath(path, paint);
    }
    c.drawCircle(a, ra, paint);
    c.drawCircle(b, rb, paint);
  }

  void _circle(Canvas c, Offset center, double r, Color color, {double outline = 0.55}) {
    if (outline > 0) c.drawCircle(center, r + outline, Paint()..color = _darken(color, 0.4));
    c.drawCircle(center, r, Paint()..color = color);
  }

  Path _smoothClosed(List<Offset> pts) {
    final path = Path();
    final n = pts.length;
    Offset mid(int i, int j) => (pts[i % n] + pts[j % n]) / 2;
    final start = mid(0, 1);
    path.moveTo(start.dx, start.dy);
    for (var i = 1; i <= n; i++) {
      final ctrl = pts[i % n];
      final end = mid(i, i + 1);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }

  // ------------------------------------------------------------ partes do corpo

  void _arm(Canvas c, int sh, int elb, int hand, Color skin) {
    final s = _p(sh), e = _p(elb), h = _p(hand);
    _capsule(c, s, e, 3.3, 2.6, skin);
    _capsule(c, e, h, 2.6, 1.9, skin);
    _circle(c, h, 2.25, skin);
  }

  void _leg(Canvas c, int hip, int knee, int ank, int toe, Color fabric, Color shoe, {required bool front}) {
    final hp = _p(hip), k = _p(knee), a = _p(ank), t = _p(toe);
    _capsule(c, hp, k, front ? 5.2 : 5.6, 4.0, fabric);
    _capsule(c, k, a, 3.9, 2.5, fabric);
    _shoe(c, k, a, t, shoe, front: front);
  }

  void _shoe(Canvas c, Offset knee, Offset ank, Offset toe, Color color, {required bool front}) {
    final fd = _unit(toe - ank);
    final heel = front ? ank : ank - fd * 2.6;
    var n = _cw(fd);
    final towardKnee = knee - ank;
    if (n.dx * towardKnee.dx + n.dy * towardKnee.dy > 0) n = -n;
    _capsule(c, heel, toe, 2.7, 2.4, color, outline: 0.45);
    _capsuleFill(c, heel + n * 1.9, toe + n * 1.6, 1.0, 0.9, FigurePalette.sole);
    _capsuleFill(c, heel - n * 0.3 + fd * 1.2, heel - n * 0.3 + fd * 3.0, 0.7, 0.7, FigurePalette.top);
  }

  void _torso(Canvas c, {required bool front}) {
    final hip = _p(Jt.hip);
    final neck = _p(Jt.neck);
    final axis = neck - hip;
    final len = axis.distance;
    final u = _unit(axis);
    final f = _cw(u);

    // (posição ao longo do tronco, largura na frente, largura atrás)
    const side = [
      [-0.16, 4.6, 6.6],
      [0.0, 6.6, 8.6],
      [0.18, 6.8, 8.0],
      [0.40, 6.0, 6.0],
      [0.62, 8.3, 6.6],
      [0.84, 7.4, 6.8],
      [1.0, 5.4, 5.6],
    ];
    const frontW = [
      [-0.14, 9.0, 9.0],
      [0.0, 10.6, 10.6],
      [0.2, 10.0, 10.0],
      [0.42, 7.8, 7.8],
      [0.64, 9.4, 9.4],
      [0.86, 10.6, 10.6],
      [1.0, 8.6, 8.6],
    ];
    final prof = front ? frontW : side;
    final pts = <Offset>[];
    for (final r in prof) {
      pts.add(hip + u * (r[0] * len) + f * r[1]);
    }
    for (final r in prof.reversed) {
      pts.add(hip + u * (r[0] * len) - f * r[2]);
    }
    final body = _smoothClosed(pts);

    // contorno
    c.save();
    c.drawPath(body, Paint()
      ..color = _darken(FigurePalette.legging, 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    c.drawPath(body, Paint()..color = FigurePalette.skin);
    c.clipPath(body);
    Path band(double t0, double t1) {
      final a = hip + u * (t0 * len);
      final b = hip + u * (t1 * len);
      return Path()
        ..moveTo(a.dx + f.dx * 30, a.dy + f.dy * 30)
        ..lineTo(b.dx + f.dx * 30, b.dy + f.dy * 30)
        ..lineTo(b.dx - f.dx * 30, b.dy - f.dy * 30)
        ..lineTo(a.dx - f.dx * 30, a.dy - f.dy * 30)
        ..close();
    }

    c.drawPath(band(-0.5, 0.40), Paint()..color = FigurePalette.legging);
    c.drawPath(band(0.47, 1.4), Paint()..color = FigurePalette.top);
    // faixa do cós e detalhe do top
    c.drawPath(band(0.37, 0.40), Paint()..color = _darken(FigurePalette.legging, 0.3));
    c.drawPath(band(0.47, 0.50), Paint()..color = _darken(FigurePalette.top, 0.2));
    c.restore();
  }

  void _neckAndHead(Canvas c, {required bool front}) {
    final neck = _p(Jt.neck);
    final head = _p(Jt.head);
    final up = _dir(_f[Jt.headAngle]);
    final face = _cw(up);
    _capsule(c, neck, neck + (head - neck) * 0.55, 2.6, 2.4, FigurePalette.skin, outline: 0.4);
    if (front) {
      _circle(c, head + up * 0.9, 7.5, FigurePalette.hair, outline: 0.4);
      _circle(c, head - up * 0.4, 6.4, FigurePalette.skin, outline: 0);
      final hairCap = Path()
        ..addArc(Rect.fromCircle(center: head + up * 0.9, radius: 7.5),
            math.atan2(up.dy, up.dx) - 1.15, 2.3);
      c.drawPath(hairCap, Paint()..color = FigurePalette.hair);
      final eyeY = head - up * 0.2;
      c.drawCircle(eyeY + face * 2.4, 0.8, Paint()..color = FigurePalette.eye);
      c.drawCircle(eyeY - face * 2.4, 0.8, Paint()..color = FigurePalette.eye);
      final mouth = head - up * 3.0;
      c.drawLine(mouth - face * 1.1, mouth + face * 1.1,
          Paint()
            ..color = _darken(FigurePalette.skin, 0.35)
            ..strokeWidth = 0.6
            ..strokeCap = StrokeCap.round);
      return;
    }
    // rabo de cavalo
    final tie = head - face * 6.6 + up * 2.4;
    _capsule(c, tie, tie - face * 3.2 - up * 5.2, 2.5, 1.3, FigurePalette.hair, outline: 0.3);
    _circle(c, head - face * 0.8 + up * 0.4, 7.4, FigurePalette.hair, outline: 0.4);
    _circle(c, head + face * 0.8 - up * 0.2, 6.5, FigurePalette.skin, outline: 0);
    // franja cobrindo o topo da testa
    c.drawCircle(head - face * 0.2 + up * 2.6, 5.0, Paint()..color = FigurePalette.hair);
    _circle(c, head - face * 0.6 - up * 0.4, 1.5, FigurePalette.skinShade, outline: 0);
    c.drawCircle(head + face * 4.2 + up * 0.6, 0.8, Paint()..color = FigurePalette.eye);
    final mouth = head + face * 5.0 - up * 2.8;
    c.drawLine(mouth - face * 0.8, mouth + face * 0.6,
        Paint()
          ..color = _darken(FigurePalette.skin, 0.35)
          ..strokeWidth = 0.55
          ..strokeCap = StrokeCap.round);
  }

  void _figureSide(Canvas c) {
    _arm(c, Jt.shF, Jt.elbF, Jt.handF, FigurePalette.skinFar);
    _leg(c, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, FigurePalette.leggingFar, FigurePalette.shoeFar, front: false);
    _torso(c, front: false);
    _leg(c, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, FigurePalette.legging, FigurePalette.shoe, front: false);
    _neckAndHead(c, front: false);
    _circle(c, _p(Jt.shN), 3.6, FigurePalette.skin, outline: 0.4);
    _arm(c, Jt.shN, Jt.elbN, Jt.handN, FigurePalette.skin);
  }

  void _figureFront(Canvas c) {
    _leg(c, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, FigurePalette.legging, FigurePalette.shoe, front: true);
    _leg(c, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, FigurePalette.legging, FigurePalette.shoe, front: true);
    _capsule(c, _p(Jt.shF), _p(Jt.shN), 3.8, 3.8, FigurePalette.skin);
    _torso(c, front: true);
    _neckAndHead(c, front: true);
    _arm(c, Jt.shF, Jt.elbF, Jt.handF, FigurePalette.skin);
    _arm(c, Jt.shN, Jt.elbN, Jt.handN, FigurePalette.skin);
  }

  void _shadow(Canvas c) {
    final a = _p(Jt.ankN), b = _p(Jt.ankF);
    final low = math.max(a.dy, b.dy);
    if (low < kGroundY - 14) return;
    final cx = (a.dx + b.dx) / 2;
    final w = (a.dx - b.dx).abs() + 22;
    c.drawOval(Rect.fromCenter(center: Offset(cx, kGroundY + 0.6), width: w, height: 3.2),
        Paint()..color = const Color(0x22000000));
  }

  // ------------------------------------------------------------ equipamentos

  Paint get _eq => Paint()..color = palette.equipment;

  Paint get _eqDark => Paint()..color = palette.equipmentDark;

  void _staticProp(Canvas c, MotionProp pr) {
    switch (pr.type) {
      case 'bench': {
        final x = pr.val('x'), y = pr.val('y'), w = pr.val('w'), h = pr.val('h', 5);
        for (final lx in [x + 3, x + w - 5]) {
          c.drawRect(Rect.fromLTRB(lx, y + h, lx + 2.2, kGroundY), _eq);
        }
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(1.6)),
            Paint()..color = palette.pad);
      }
      case 'box': {
        final r = Rect.fromLTWH(pr.val('x'), pr.val('y'), pr.val('w'), pr.val('h'));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.2)), Paint()..color = const Color(0xFF8C6F55));
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 1.4), Paint()..color = const Color(0xFF6E5440));
      }
      case 'rect': {
        final op = pr.val('op', 1.0);
        final r = Rect.fromLTWH(pr.val('x'), pr.val('y'), pr.val('w'), pr.val('h'));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.4)),
            Paint()..color = palette.pad.withAlpha((255 * op).round()));
      }
      case 'poly': {
        final pts = pr.points();
        if (pts.length < 3) return;
        c.drawPath(Path()..addPolygon(pts, true), Paint()..color = palette.pad);
      }
      case 'line': {
        c.drawLine(Offset(pr.val('x1'), pr.val('y1')), Offset(pr.val('x2'), pr.val('y2')),
            _eq
              ..strokeWidth = pr.val('w', 2)
              ..strokeCap = StrokeCap.round);
      }
      case 'rail': {
        c.drawLine(Offset(pr.val('x'), pr.val('y1')), Offset(pr.val('x'), pr.val('y2')),
            _eq..strokeWidth = 1.6);
      }
      case 'tower': {
        final x = pr.val('x');
        c.drawRect(Rect.fromLTRB(x, clip.viewport.top - 20, x + 6, kGroundY), _eqDark);
      }
      case 'pulley': {
        final o = Offset(pr.val('x'), pr.val('y'));
        c.drawCircle(o, 3.0, _eq);
        c.drawCircle(o, 1.1, _eqDark);
      }
      case 'bars': {
        final x1 = pr.val('x1'), x2 = pr.val('x2'), y = pr.val('y');
        for (final px in [x1 + 4, x2 - 4]) {
          c.drawRect(Rect.fromLTRB(px - 1.2, y, px + 1.2, kGroundY), _eqDark);
        }
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x1, y - 1.6, x2, y + 1.6), const Radius.circular(1.6)), _eq);
      }
      case 'pullbar': {
        final x1 = pr.val('x1'), x2 = pr.val('x2'), y = pr.val('y');
        for (final px in [x1, x2]) {
          c.drawRect(Rect.fromLTRB(px - 1.4, clip.viewport.top - 20, px + 1.4, kGroundY), _eqDark);
        }
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x1, y - 1.3, x2, y + 1.3), const Radius.circular(1.3)), _eq);
      }
      case 'mat': {
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(pr.val('x'), kGroundY - 1.6, pr.val('x2'), kGroundY + 0.4),
                const Radius.circular(0.8)),
            Paint()..color = const Color(0xFF3E8E9C));
      }
      case 'wall': {
        final x = pr.val('x');
        c.drawRect(Rect.fromLTRB(x - 30, clip.viewport.top - 20, x, kGroundY), Paint()..color = palette.floorLine);
      }
      case 'treadmill': {
        final x1 = pr.val('x1'), x2 = pr.val('x2');
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x1, kGroundY - 4.5, x2, kGroundY), const Radius.circular(2)),
            _eqDark);
        c.drawLine(Offset(x2 - 3, kGroundY - 4), Offset(x2 + 6, 62), _eq..strokeWidth = 2.4);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x2 + 1, 56, 12, 6), const Radius.circular(1.5)), _eqDark);
      }
      case 'circle': {
        final o = Offset(pr.val('x'), pr.val('y'));
        final r = pr.val('r', 10);
        c.drawCircle(o, r, Paint()..color = palette.pad.withAlpha(90));
        c.drawCircle(o, r, _eqDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
      }
      case 'bike': {
        final crank = Offset(pr.val('x'), pr.val('y'));
        final seat = Offset(pr.val('sx'), pr.val('sy'));
        final bar = Offset(pr.val('hx'), pr.val('hy'));
        final s = _eqDark
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(crank.dx - 34, kGroundY - 1), Offset(crank.dx + 30, kGroundY - 1), s);
        c.drawLine(crank, Offset(crank.dx - 20, kGroundY - 1), s);
        c.drawLine(crank, seat, s);
        c.drawLine(crank, Offset(bar.dx - 2, bar.dy + 6), s);
        c.drawLine(Offset(crank.dx + 18, kGroundY - 1), Offset(bar.dx - 2, bar.dy + 6), s);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: seat, width: 14, height: 3.4), const Radius.circular(1.7)),
            Paint()..color = palette.pad);
        c.drawLine(Offset(bar.dx - 2, bar.dy + 6), bar, s);
        c.drawCircle(crank, 5, Paint()..color = palette.equipment);
      }
    }
  }

  void _trackedProp(Canvas c, MotionProp pr) {
    final p0 = _tp(pr.track[0]);
    switch (pr.type) {
      case 'plate': {
        c.drawCircle(p0, 9.2, Paint()..color = FigurePalette.iron);
        c.drawCircle(p0, 6.4, Paint()
          ..color = FigurePalette.ironLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
        c.drawCircle(p0, 1.8, Paint()..color = const Color(0xFFB0B0B8));
      }
      case 'db_end': {
        c.drawCircle(p0, 3.9, Paint()..color = FigurePalette.iron);
        c.drawCircle(p0, 1.6, Paint()..color = FigurePalette.ironLight);
      }
      case 'db_side': {
        Offset axis;
        if (pr.flag('along') && pr.track.length > 1) {
          final forearm = _unit(p0 - _tp(pr.track[1]));
          axis = _cw(forearm);
        } else {
          axis = _dir(pr.val('angle'));
        }
        final n = _cw(axis);
        void head(Offset center) {
          final path = Path()
            ..moveTo(center.dx + axis.dx * 1.8 + n.dx * 3.4, center.dy + axis.dy * 1.8 + n.dy * 3.4)
            ..lineTo(center.dx - axis.dx * 1.8 + n.dx * 3.4, center.dy - axis.dy * 1.8 + n.dy * 3.4)
            ..lineTo(center.dx - axis.dx * 1.8 - n.dx * 3.4, center.dy - axis.dy * 1.8 - n.dy * 3.4)
            ..lineTo(center.dx + axis.dx * 1.8 - n.dx * 3.4, center.dy + axis.dy * 1.8 - n.dy * 3.4)
            ..close();
          c.drawPath(path, Paint()..color = FigurePalette.iron);
        }
        c.drawLine(p0 - axis * 5, p0 + axis * 5, Paint()
          ..color = FigurePalette.ironLight
          ..strokeWidth = 1.4);
        head(p0 + axis * 5.2);
        head(p0 - axis * 5.2);
      }
      case 'kb': {
        final hand = _p(Jt.handN);
        final elbow = _p(Jt.elbN);
        final down = _unit(hand - elbow);
        final bell = hand + down * 5.6;
        c.drawCircle(hand + down * 1.4, 2.4, Paint()
          ..color = FigurePalette.iron
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);
        c.drawCircle(bell, 4.6, Paint()..color = FigurePalette.iron);
      }
      case 'pad': {
        final r = pr.val('r', 4);
        c.drawCircle(p0, r, Paint()..color = palette.pad);
        c.drawCircle(p0, r * 0.35, Paint()..color = _darken(palette.pad, 0.3));
      }
      case 'lever': {
        c.drawLine(Offset(pr.val('x'), pr.val('y')), p0, _eqDark
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
        c.drawCircle(Offset(pr.val('x'), pr.val('y')), 1.8, _eq);
      }
      case 'sled': {
        final a = _dir(pr.val('angle') + 90);
        final half = pr.val('len', 30) / 2;
        c.drawLine(p0 - a * half, p0 + a * half, _eqDark
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round);
      }
      case 'cable': {
        final from = Offset(pr.val('x'), pr.val('y'));
        c.drawLine(from, p0, Paint()
          ..color = FigurePalette.cable
          ..strokeWidth = 0.6);
        c.drawCircle(p0, 1.4, Paint()..color = FigurePalette.cable);
      }
      case 'cablev': {
        c.drawLine(Offset(p0.dx, pr.val('y')), p0, Paint()
          ..color = FigurePalette.cable
          ..strokeWidth = 0.6);
      }
      case 'seg': {
        if (pr.track.length < 2) return;
        c.drawLine(p0, _tp(pr.track[1]), Paint()
          ..color = FigurePalette.iron
          ..strokeWidth = pr.val('w', 2)
          ..strokeCap = StrokeCap.round);
      }
      case 'band': {
        if (pr.track.length < 2) return;
        c.drawLine(p0, _tp(pr.track[1]), Paint()
          ..color = FigurePalette.band
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
      }
      case 'rope': {
        if (pr.track.length < 3) return;
        final b = _tp(pr.track[1]);
        final ctrl = _tp(pr.track[2]);
        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
        c.drawPath(path, Paint()
          ..color = FigurePalette.cable
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9);
      }
    }
  }

  @override
  bool shouldRepaint(FigurePainter old) => old.time != time || old.clip != clip || old.palette != palette;
}
