import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'motion_clip.dart';

/// Cores do cenário (variam com o tema).
class FigurePalette {
  const FigurePalette({
    required this.background,
    required this.floor,
    required this.floorLine,
    required this.equipment,
    required this.equipmentDark,
    required this.pad,
    required this.path,
  });

  final Color background;
  final Color floor;
  final Color floorLine;
  final Color equipment;
  final Color equipmentDark;
  final Color pad;
  final Color path;

  static const light = FigurePalette(
    background: Color(0xFFEEF0F2),
    floor: Color(0xFFDDE1E6),
    floorLine: Color(0xFFC5CBD3),
    equipment: Color(0xFF7A8292),
    equipmentDark: Color(0xFF3B4250),
    pad: Color(0xFF2E3A57),
    path: Color(0xFF1F4FD8),
  );

  static const dark = FigurePalette(
    background: Color(0xFF1A1D23),
    floor: Color(0xFF242830),
    floorLine: Color(0xFF353A44),
    equipment: Color(0xFF8E96A6),
    equipmentDark: Color(0xFF5A6272),
    pad: Color(0xFF3E4C70),
    path: Color(0xFF7FA2FF),
  );
}

/// Como desenhar a pessoa: corpo masculino ou feminino e o que destacar.
class FigureStyle {
  const FigureStyle({
    this.male = false,
    this.primary = const {},
    this.secondary = const {},
    this.showMuscles = true,
    this.showPath = true,
  });

  final bool male;
  final Set<String> primary;
  final Set<String> secondary;
  final bool showMuscles;
  final bool showPath;

  @override
  bool operator ==(Object other) =>
      other is FigureStyle &&
      other.male == male &&
      other.showMuscles == showMuscles &&
      other.showPath == showPath &&
      _sameSet(other.primary, primary) &&
      _sameSet(other.secondary, secondary);

  @override
  int get hashCode => Object.hash(male, showMuscles, showPath, primary.length, secondary.length);

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
}

class _Body {
  const _Body({
    required this.skin,
    required this.skinFar,
    required this.top,
    required this.bottom,
    required this.bottomFar,
    required this.hair,
    required this.upperArm,
    required this.foreArm,
    required this.thigh,
    required this.calf,
    required this.side,
    required this.front,
    required this.male,
  });

  final Color skin, skinFar, top, bottom, bottomFar, hair;
  final List<double> upperArm, foreArm, thigh, calf; // raio no início, no meio e no fim
  final List<List<double>> side, front; // (posição no tronco, frente, costas)
  final bool male;

  static const female = _Body(
    male: false,
    skin: Color(0xFFE0A47E),
    skinFar: Color(0xFFC08562),
    top: Color(0xFF1F4FD8),
    bottom: Color(0xFF2A2F3A),
    bottomFar: Color(0xFF1C2028),
    hair: Color(0xFF3A2416),
    upperArm: [3.2, 3.0, 2.5],
    foreArm: [2.6, 2.4, 1.8],
    thigh: [6.0, 5.7, 4.0],
    calf: [3.8, 4.1, 2.4],
    side: [
      [-0.18, 4.6, 6.8],
      [0.0, 6.6, 9.0],
      [0.16, 6.9, 8.6],
      [0.40, 5.8, 5.8],
      [0.62, 8.4, 6.4],
      [0.84, 7.4, 6.8],
      [1.0, 5.2, 5.4],
    ],
    front: [
      [-0.14, 9.4, 9.4],
      [0.0, 11.2, 11.2],
      [0.2, 10.4, 10.4],
      [0.42, 7.6, 7.6],
      [0.64, 9.2, 9.2],
      [0.86, 10.2, 10.2],
      [1.0, 8.4, 8.4],
    ],
  );

  static const maleBody = _Body(
    male: true,
    skin: Color(0xFFD69A72),
    skinFar: Color(0xFFB57D57),
    top: Color(0xFF1F4FD8),
    bottom: Color(0xFF2A2F3A),
    bottomFar: Color(0xFF1C2028),
    hair: Color(0xFF2A1C14),
    upperArm: [3.9, 3.7, 2.9],
    foreArm: [3.0, 2.8, 2.1],
    thigh: [6.2, 6.0, 4.3],
    calf: [4.0, 4.4, 2.6],
    side: [
      [-0.16, 4.8, 6.2],
      [0.0, 6.8, 7.6],
      [0.18, 6.8, 7.2],
      [0.42, 6.6, 6.6],
      [0.66, 9.0, 7.4],
      [0.86, 8.4, 7.8],
      [1.0, 6.2, 6.6],
    ],
    front: [
      [-0.14, 9.0, 9.0],
      [0.0, 10.0, 10.0],
      [0.22, 9.6, 9.6],
      [0.45, 9.4, 9.4],
      [0.68, 11.6, 11.6],
      [0.88, 13.0, 13.0],
      [1.0, 10.4, 10.4],
    ],
  );
}

const _shoeColor = Color(0xFFF7F8FA);
const _shoeFarColor = Color(0xFFD5D9E0);
const _sole = Color(0xFF8A93A3);
const _eye = Color(0xFF241812);
const _iron = Color(0xFF262A31);
const _ironLight = Color(0xFF5A606B);
const _cable = Color(0xFF1C1F25);
const _band = Color(0xFF1E9E5A);
const _muscle = Color(0xFFFFB400);
const _plateRim = Color(0xFFE2382F);

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
}

Color _light(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + (1 - hsl.lightness) * amount).clamp(0.0, 1.0)).toColor();
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

Offset _ccw(Offset v) => Offset(v.dy, -v.dx);

const _lightDir = Offset(-0.6, -0.8);

/// Desenha um quadro do movimento: cenário, percurso, pessoa e equipamentos.
class FigurePainter extends CustomPainter {
  FigurePainter({
    required this.clip,
    required this.time,
    required this.palette,
    this.style = const FigureStyle(),
    this.ghost = true,
  });

  final MotionClip clip;
  final double time;
  final FigurePalette palette;
  final FigureStyle style;
  final bool ghost;

  late Float32List _f;
  late _Body _b;
  double _pulse = 0.5;

  Offset _p(int joint) => Offset(_f[joint * 2], _f[joint * 2 + 1]);

  Offset _tp(int index) => Offset(_f[Jt.trackedBase + index * 2], _f[Jt.trackedBase + index * 2 + 1]);

  @override
  void paint(Canvas canvas, Size size) {
    if (clip.frameCount == 0 || size.isEmpty) return;
    _b = style.male ? _Body.maleBody : _Body.female;
    _pulse = 0.5 + 0.5 * math.sin(time * math.pi * 2 * 2);
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

    _f = clip.sample(time);
    _shadow(canvas);
    for (final pr in clip.props) {
      if (pr.track.isEmpty) _staticProp(canvas, pr);
    }

    if (ghost && style.showPath) {
      _f = clip.sample(0);
      canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.16));
      _figure(canvas, highlight: false);
      canvas.restore();
      _f = clip.sample(time);
    }

    for (final pr in clip.props) {
      if (pr.track.isNotEmpty && _behind.contains(pr.type)) _trackedProp(canvas, pr);
    }
    _figure(canvas, highlight: style.showMuscles);
    for (final pr in clip.props) {
      if (pr.track.isNotEmpty && !_behind.contains(pr.type)) _trackedProp(canvas, pr);
    }
    if (style.showPath) _keyPath(canvas);
    canvas.restore();
  }

  static const _behind = {'cable', 'cablev', 'lever', 'pad', 'sled'};

  void _figure(Canvas c, {required bool highlight}) {
    if (clip.isFront) {
      _figureFront(c, highlight);
    } else {
      _figureSide(c, highlight);
    }
  }

  // ------------------------------------------------------------ formas

  /// Segmento com volume: contorno, preenchimento com sombreado lateral e
  /// barriga no meio (músculo).
  Path _limbPath(Offset a, Offset b, double ra, double rm, double rb, {double grow = 0}) {
    final d = b - a;
    final len = d.distance;
    if (len < 0.01) {
      return Path()..addOval(Rect.fromCircle(center: a, radius: math.max(ra, rb) + grow));
    }
    final u = d / len;
    final n = _cw(u);
    final m = a + d * 0.42;
    final ra2 = ra + grow, rm2 = rm + grow, rb2 = rb + grow;
    final p = Path()
      ..moveTo(a.dx + n.dx * ra2, a.dy + n.dy * ra2)
      ..quadraticBezierTo(m.dx + n.dx * rm2 * 1.12, m.dy + n.dy * rm2 * 1.12, b.dx + n.dx * rb2, b.dy + n.dy * rb2)
      ..arcToPoint(Offset(b.dx - n.dx * rb2, b.dy - n.dy * rb2), radius: Radius.circular(rb2), clockwise: false)
      ..quadraticBezierTo(m.dx - n.dx * rm2 * 1.12, m.dy - n.dy * rm2 * 1.12, a.dx - n.dx * ra2, a.dy - n.dy * ra2)
      ..arcToPoint(Offset(a.dx + n.dx * ra2, a.dy + n.dy * ra2), radius: Radius.circular(ra2), clockwise: false)
      ..close();
    return p;
  }

  void _limb(Canvas c, Offset a, Offset b, List<double> r, Color color, {double scale = 1}) {
    final ra = r[0] * scale, rm = r[1] * scale, rb = r[2] * scale;
    c.drawPath(_limbPath(a, b, ra, rm, rb, grow: 0.5), Paint()..color = _shade(color, 0.45));
    final shader = _gradientAcross(a, b, math.max(ra, rm), color);
    c.drawPath(_limbPath(a, b, ra, rm, rb), shader);
  }

  Paint _gradientAcross(Offset a, Offset b, double r, Color base) {
    var n = _cw(_unit(b - a));
    if (n.dx * _lightDir.dx + n.dy * _lightDir.dy < 0) n = -n;
    final mid = (a + b) / 2;
    return Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        mid + n * r,
        mid - n * r,
        [_light(base, 0.2), base, _shade(base, 0.25)],
        const [0.0, 0.5, 1.0],
      );
  }

  void _circle(Canvas c, Offset center, double r, Color color, {double outline = 0.5}) {
    if (outline > 0) c.drawCircle(center, r + outline, Paint()..color = _shade(color, 0.45));
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

  // ------------------------------------------------------------ destaque muscular

  bool _isPrimary(String g) => style.primary.contains(g);

  bool _wants(String g) => style.primary.contains(g) || style.secondary.contains(g);

  Paint _musclePaint(String g, {double factor = 1}) {
    final a = _isPrimary(g) ? 0.42 + 0.28 * _pulse : 0.24 + 0.08 * _pulse;
    return Paint()..color = _muscle.withAlpha((255 * a * factor).round().clamp(0, 255));
  }

  /// Metade de um segmento, do lado [side] do eixo (para músculos da frente
  /// ou de trás de um membro).
  Path _halfLimb(Offset a, Offset b, double ra, double rb, Offset side, {double from = 0.08, double to = 0.92}) {
    final d = b - a;
    final p0 = a + d * from, p1 = a + d * to;
    final s = side;
    final m = a + d * 0.45;
    final rm = (ra + rb) / 2 * 1.15;
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p0.dx + s.dx * ra * 0.95, p0.dy + s.dy * ra * 0.95)
      ..quadraticBezierTo(m.dx + s.dx * rm, m.dy + s.dy * rm, p1.dx + s.dx * rb * 0.95, p1.dy + s.dy * rb * 0.95)
      ..lineTo(p1.dx, p1.dy)
      ..close();
  }

  void _legMuscles(Canvas c, int hip, int knee, int ank, {required bool front, double factor = 1}) {
    if (!style.showMuscles) return;
    final h = _p(hip), k = _p(knee), a = _p(ank);
    final ut = _unit(k - h);
    final us = _unit(a - k);
    if (front) {
      if (_wants('quadriceps')) c.drawPath(_limbPath(h, k, 4.6, 4.6, 3.0), _musclePaint('quadriceps', factor: factor));
      final mid = _p(Jt.hip);
      final inward = _unit(mid - h);
      final lateral = -inward;
      final hasLat = (inward.dx.abs() > 0.05 || inward.dy.abs() > 0.05);
      if (hasLat && _wants('adutores')) {
        final n = _cw(ut);
        final side = (n.dx * inward.dx + n.dy * inward.dy) > 0 ? n : -n;
        c.drawPath(_halfLimb(h, k, 5.6, 3.8, side, to: 0.7), _musclePaint('adutores', factor: factor));
      }
      if (hasLat && _wants('abdutores')) {
        c.drawOval(Rect.fromCenter(center: h + lateral * 3.2 - ut * 1.0, width: 6.5, height: 8),
            _musclePaint('abdutores', factor: factor));
      }
      if (_wants('panturrilha')) c.drawPath(_limbPath(k, a, 3.0, 3.4, 2.0), _musclePaint('panturrilha', factor: factor));
      return;
    }
    if (_wants('quadriceps')) c.drawPath(_halfLimb(h, k, 5.7, 4.0, _ccw(ut)), _musclePaint('quadriceps', factor: factor));
    if (_wants('posterior')) c.drawPath(_halfLimb(h, k, 5.7, 4.0, _cw(ut)), _musclePaint('posterior', factor: factor));
    if (_wants('adutores')) c.drawPath(_limbPath(h + (k - h) * 0.15, h + (k - h) * 0.6, 2.4, 2.6, 2.0),
        _musclePaint('adutores', factor: factor * 0.8));
    if (_wants('panturrilha')) {
      c.drawPath(_halfLimb(k, a, 3.9, 2.4, _cw(us), from: 0.12, to: 0.7), _musclePaint('panturrilha', factor: factor));
    }
  }

  void _armMuscles(Canvas c, int sh, int elb, int hand, {required bool front, double factor = 1}) {
    if (!style.showMuscles) return;
    final s = _p(sh), e = _p(elb), h = _p(hand);
    final uu = _unit(e - s);
    final r = _b.upperArm;
    if (front) {
      if (_wants('biceps') || _wants('triceps')) {
        final g = _wants('biceps') ? 'biceps' : 'triceps';
        c.drawPath(_limbPath(s + (e - s) * 0.18, e, r[0] * 0.8, r[1] * 0.85, r[2] * 0.8), _musclePaint(g, factor: factor));
      }
    } else {
      if (_wants('biceps')) c.drawPath(_halfLimb(s, e, r[0], r[2], _ccw(uu), from: 0.2), _musclePaint('biceps', factor: factor));
      if (_wants('triceps')) c.drawPath(_halfLimb(s, e, r[0], r[2], _cw(uu), from: 0.15), _musclePaint('triceps', factor: factor));
    }
    if (_wants('antebraco')) {
      c.drawPath(_limbPath(e, h, _b.foreArm[0] * 0.85, _b.foreArm[1] * 0.85, _b.foreArm[2] * 0.7),
          _musclePaint('antebraco', factor: factor));
    }
    if (_wants('ombros')) c.drawCircle(s, (_b.male ? 4.4 : 3.8), _musclePaint('ombros', factor: factor));
  }

  void _torsoMuscles(Canvas c, Path body, {required bool front}) {
    if (!style.showMuscles) return;
    final hip = _p(Jt.hip), neck = _p(Jt.neck);
    final len = (neck - hip).distance;
    final u = _unit(neck - hip);
    final f = _cw(u);
    Path band(double t0, double t1, double s0, double s1) {
      final a = hip + u * (t0 * len), b = hip + u * (t1 * len);
      return Path()
        ..moveTo(a.dx + f.dx * s0, a.dy + f.dy * s0)
        ..lineTo(b.dx + f.dx * s0, b.dy + f.dy * s0)
        ..lineTo(b.dx + f.dx * s1, b.dy + f.dy * s1)
        ..lineTo(a.dx + f.dx * s1, a.dy + f.dy * s1)
        ..close();
    }

    c.save();
    c.clipPath(body);
    if (front) {
      if (_wants('peito')) {
        c.drawOval(Rect.fromCenter(center: hip + u * (0.74 * len) + f * 4.2, width: 8, height: 6.5), _musclePaint('peito'));
        c.drawOval(Rect.fromCenter(center: hip + u * (0.74 * len) - f * 4.2, width: 8, height: 6.5), _musclePaint('peito'));
      }
      if (_wants('abdomen')) c.drawPath(band(0.12, 0.6, -4.2, 4.2), _musclePaint('abdomen'));
      if (_wants('costas')) {
        c.drawPath(band(0.45, 0.84, 7.0, 14), _musclePaint('costas'));
        c.drawPath(band(0.45, 0.84, -7.0, -14), _musclePaint('costas'));
      }
      if (_wants('trapezio')) c.drawPath(band(0.9, 1.1, -8, 8), _musclePaint('trapezio'));
      if (_wants('gluteos')) {
        c.drawPath(band(-0.2, 0.12, 6.5, 14), _musclePaint('gluteos', factor: 0.8));
        c.drawPath(band(-0.2, 0.12, -6.5, -14), _musclePaint('gluteos', factor: 0.8));
      }
    } else {
      if (_wants('peito')) c.drawPath(band(0.6, 0.95, 0.5, 14), _musclePaint('peito'));
      if (_wants('abdomen')) c.drawPath(band(0.1, 0.56, 0.5, 14), _musclePaint('abdomen'));
      if (_wants('costas')) c.drawPath(band(0.46, 0.92, -0.5, -14), _musclePaint('costas'));
      if (_wants('lombar')) c.drawPath(band(0.1, 0.44, -0.5, -14), _musclePaint('lombar'));
      if (_wants('trapezio')) c.drawPath(band(0.86, 1.15, 1.5, -14), _musclePaint('trapezio'));
      if (_wants('gluteos')) c.drawPath(band(-0.3, 0.16, -1.0, -14), _musclePaint('gluteos'));
      if (_wants('abdutores')) {
        c.drawOval(Rect.fromCenter(center: hip + u * (0.06 * len) - f * 3.0, width: 7, height: 7), _musclePaint('abdutores'));
      }
    }
    c.restore();
  }

  // ------------------------------------------------------------ partes do corpo

  void _arm(Canvas c, int sh, int elb, int hand, Color skin, {required bool front, bool highlight = false, double factor = 1}) {
    final s = _p(sh), e = _p(elb), h = _p(hand);
    _limb(c, s, e, _b.upperArm, skin);
    if (_b.male) {
      // manga da camiseta
      final sleeveEnd = s + (e - s) * 0.42;
      _limb(c, s, sleeveEnd, [_b.upperArm[0] + 0.7, _b.upperArm[0] + 0.6, _b.upperArm[1] + 0.5], _b.top);
    }
    _limb(c, e, h, _b.foreArm, skin);
    // mão: palma e polegar
    final fd = _unit(h - e);
    _circle(c, h + fd * 0.6, _b.male ? 2.5 : 2.2, skin, outline: 0.45);
    _circle(c, h + _cw(fd) * 1.3, 0.95, _shade(skin, 0.06), outline: 0.3);
    if (highlight) _armMuscles(c, sh, elb, hand, front: front, factor: factor);
  }

  void _leg(Canvas c, int hip, int knee, int ank, int toe, Color fabric, Color skin, Color shoe,
      {required bool front, bool highlight = false, double factor = 1}) {
    final hp = _p(hip), k = _p(knee), a = _p(ank), t = _p(toe);
    if (_b.male) {
      // bermuda até acima do joelho, perna à mostra
      _limb(c, hp, k, _b.thigh, skin);
      final shortsEnd = hp + (k - hp) * 0.78;
      _limb(c, hp, shortsEnd, [_b.thigh[0] + 0.6, _b.thigh[1] + 0.7, _b.thigh[1] + 0.3], fabric);
      _limb(c, k, a, _b.calf, skin);
      _limb(c, a - _unit(a - k) * 2.0, a, const [2.6, 2.6, 2.5], const Color(0xFFF2F2F2));
    } else {
      _limb(c, hp, k, _b.thigh, fabric);
      _limb(c, k, a, _b.calf, fabric);
    }
    _shoe(c, k, a, t, shoe, front: front);
    if (highlight) _legMuscles(c, hip, knee, ank, front: front, factor: factor);
  }

  void _shoe(Canvas c, Offset knee, Offset ank, Offset toe, Color color, {required bool front}) {
    final fd = _unit(toe - ank);
    final heel = front ? ank : ank - fd * 2.8;
    var n = _cw(fd);
    final towardKnee = knee - ank;
    if (n.dx * towardKnee.dx + n.dy * towardKnee.dy > 0) n = -n;
    _limb(c, heel, toe, const [2.8, 2.9, 2.4], color);
    c.drawPath(_limbPath(heel + n * 2.0, toe + n * 1.7, 1.0, 1.0, 0.9), Paint()..color = _sole);
    c.drawPath(_limbPath(heel - n * 0.2 + fd * 1.4, heel - n * 0.6 + fd * 4.0, 0.6, 0.6, 0.5),
        Paint()..color = const Color(0xFFF5B700));
  }

  Path _torsoPath({required bool front}) {
    final hip = _p(Jt.hip);
    final neck = _p(Jt.neck);
    final axis = neck - hip;
    final len = axis.distance;
    final u = _unit(axis);
    final f = _cw(u);
    final prof = front ? _b.front : _b.side;
    final pts = <Offset>[];
    for (final r in prof) {
      pts.add(hip + u * (r[0] * len) + f * r[1]);
    }
    for (final r in prof.reversed) {
      pts.add(hip + u * (r[0] * len) - f * r[2]);
    }
    return _smoothClosed(pts);
  }

  void _torso(Canvas c, {required bool front, bool highlight = false}) {
    final hip = _p(Jt.hip);
    final neck = _p(Jt.neck);
    final len = (neck - hip).distance;
    final u = _unit(neck - hip);
    final f = _cw(u);
    final body = _torsoPath(front: front);

    c.drawPath(body, Paint()
      ..color = _shade(_b.bottom, 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1);
    c.drawPath(body, Paint()..color = _b.skin);
    c.save();
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

    final topStart = _b.male ? 0.30 : 0.47;
    c.drawPath(band(-0.6, _b.male ? 0.34 : 0.40), Paint()..color = _b.bottom);
    c.drawPath(band(topStart, 1.4), _gradientAcross(hip + u * (0.6 * len), neck, 12, _b.top));
    // cós e detalhes da roupa
    c.drawPath(band(_b.male ? 0.30 : 0.37, _b.male ? 0.34 : 0.40), Paint()..color = _shade(_b.bottom, 0.35));
    if (!_b.male) {
      c.drawPath(band(0.47, 0.50), Paint()..color = _shade(_b.top, 0.25));
    }
    // sombreado lateral do tronco (volume)
    final edge = front ? f : -f;
    c.drawPath(
        Path()
          ..moveTo(hip.dx + edge.dx * 4, hip.dy + edge.dy * 4)
          ..lineTo(neck.dx + edge.dx * 4, neck.dy + edge.dy * 4)
          ..lineTo(neck.dx + edge.dx * 30, neck.dy + edge.dy * 30)
          ..lineTo(hip.dx + edge.dx * 30, hip.dy + edge.dy * 30)
          ..close(),
        Paint()..color = const Color(0x1A000000));
    c.restore();
    if (highlight) _torsoMuscles(c, body, front: front);
  }

  void _neckAndHead(Canvas c, {required bool front}) {
    final neck = _p(Jt.neck);
    final head = _p(Jt.head);
    final up = _dir(_f[Jt.headAngle]);
    final face = _cw(up);
    _limb(c, neck, neck + (head - neck) * 0.55, [_b.male ? 3.0 : 2.5, _b.male ? 2.9 : 2.4, 2.3], _b.skin);
    final hairPaint = Paint()..color = _b.hair;
    if (front) {
      if (!_b.male) _circle(c, head + up * 0.4, 7.7, _b.hair, outline: 0.4);
      _circle(c, head - up * 0.3, 6.5, _b.skin, outline: _b.male ? 0.45 : 0);
      final cap = Path()
        ..addArc(Rect.fromCircle(center: head + up * 0.6, radius: _b.male ? 7.0 : 7.4),
            math.atan2(up.dy, up.dx) - (_b.male ? 1.0 : 1.2), _b.male ? 2.0 : 2.4);
      c.drawPath(cap, hairPaint);
      final eyeY = head - up * 0.3;
      c.drawCircle(eyeY + face * 2.4, 0.75, Paint()..color = _eye);
      c.drawCircle(eyeY - face * 2.4, 0.75, Paint()..color = _eye);
      c.drawLine(eyeY + face * 1.6 + up * 1.6, eyeY + face * 3.2 + up * 1.7,
          Paint()
            ..color = _shade(_b.hair, 0.1)
            ..strokeWidth = 0.5);
      c.drawLine(eyeY - face * 1.6 + up * 1.6, eyeY - face * 3.2 + up * 1.7,
          Paint()
            ..color = _shade(_b.hair, 0.1)
            ..strokeWidth = 0.5);
      final mouth = head - up * 3.2;
      c.drawLine(mouth - face * 1.1, mouth + face * 1.1,
          Paint()
            ..color = _shade(_b.skin, 0.38)
            ..strokeWidth = 0.6
            ..strokeCap = StrokeCap.round);
      return;
    }
    if (!_b.male) {
      final tie = head - face * 6.6 + up * 2.4;
      c.drawPath(_limbPath(tie, tie - face * 3.4 - up * 5.4, 2.5, 2.2, 1.2), hairPaint);
    }
    _circle(c, head - face * 0.8 + up * 0.4, _b.male ? 7.0 : 7.4, _b.hair, outline: 0.4);
    _circle(c, head + face * 0.9 - up * 0.3, 6.5, _b.skin, outline: 0);
    // nariz
    final nose = head + face * 6.9 - up * 0.6;
    c.drawPath(
        Path()
          ..moveTo(nose.dx + up.dx * 1.6, nose.dy + up.dy * 1.6)
          ..lineTo(nose.dx + face.dx * 1.3 - up.dx * 0.4, nose.dy + face.dy * 1.3 - up.dy * 0.4)
          ..lineTo(nose.dx - up.dx * 1.0, nose.dy - up.dy * 1.0)
          ..close(),
        Paint()..color = _b.skin);
    // cabelo cobrindo o topo
    c.drawCircle(head - face * 0.2 + up * (_b.male ? 3.2 : 2.6), _b.male ? 4.4 : 5.0, hairPaint);
    _circle(c, head - face * 0.5 - up * 0.4, 1.5, _shade(_b.skin, 0.12), outline: 0);
    c.drawCircle(head + face * 4.3 + up * 0.6, 0.8, Paint()..color = _eye);
    c.drawLine(head + face * 3.4 + up * 2.1, head + face * 5.3 + up * 2.0,
        Paint()
          ..color = _shade(_b.hair, 0.1)
          ..strokeWidth = 0.55);
    final mouth = head + face * 5.2 - up * 2.9;
    c.drawLine(mouth - face * 0.8, mouth + face * 0.7,
        Paint()
          ..color = _shade(_b.skin, 0.38)
          ..strokeWidth = 0.55
          ..strokeCap = StrokeCap.round);
  }

  void _figureSide(Canvas c, bool hl) {
    _arm(c, Jt.shF, Jt.elbF, Jt.handF, _b.skinFar, front: false, highlight: hl, factor: 0.6);
    _leg(c, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, _b.bottomFar, _b.skinFar, _shoeFarColor,
        front: false, highlight: hl, factor: 0.6);
    _torso(c, front: false, highlight: hl);
    _leg(c, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, _b.bottom, _b.skin, _shoeColor, front: false, highlight: hl);
    _neckAndHead(c, front: false);
    _circle(c, _p(Jt.shN), _b.male ? 4.3 : 3.6, _b.male ? _b.top : _b.skin, outline: 0.4);
    _arm(c, Jt.shN, Jt.elbN, Jt.handN, _b.skin, front: false, highlight: hl);
  }

  void _figureFront(Canvas c, bool hl) {
    _leg(c, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, _b.bottom, _b.skin, _shoeColor, front: true, highlight: hl);
    _leg(c, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, _b.bottom, _b.skin, _shoeColor, front: true, highlight: hl);
    final shW = _b.male ? 4.6 : 3.8;
    _limb(c, _p(Jt.shF), _p(Jt.shN), [shW, shW, shW], _b.male ? _b.top : _b.skin);
    _torso(c, front: true, highlight: hl);
    _neckAndHead(c, front: true);
    _arm(c, Jt.shF, Jt.elbF, Jt.handF, _b.skin, front: true, highlight: hl);
    _arm(c, Jt.shN, Jt.elbN, Jt.handN, _b.skin, front: true, highlight: hl);
  }

  void _shadow(Canvas c) {
    final a = _p(Jt.ankN), b = _p(Jt.ankF);
    final low = math.max(a.dy, b.dy);
    if (low < kGroundY - 14) return;
    final cx = (a.dx + b.dx) / 2;
    final w = (a.dx - b.dx).abs() + 24;
    c.drawOval(Rect.fromCenter(center: Offset(cx, kGroundY + 0.6), width: w, height: 3.4),
        Paint()..color = const Color(0x26000000));
  }

  // ------------------------------------------------------------ percurso

  void _keyPath(Canvas c) {
    final path = clip.keyPath;
    if (path.length < 3 || clip.keyPathExtent < 6) return;
    final paint = Paint()
      ..color = palette.path.withAlpha(150)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < path.length; i += 2) {
      final a = path[i];
      final b = path[(i + 1) % path.length];
      c.drawLine(a, b, paint);
    }
    final cur = clip.keyPointAt(time);
    final prev = clip.keyPointAt(time - 0.04);
    final mv = cur - prev;
    c.drawCircle(cur, 2.0, Paint()..color = palette.path);
    c.drawCircle(cur, 2.0, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6);
    if (mv.distance > 0.4) {
      final u = _unit(mv);
      final n = _cw(u);
      final tip = cur + u * 6.5;
      final base = cur + u * 3.0;
      c.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(base.dx + n.dx * 2.4, base.dy + n.dy * 2.4)
            ..lineTo(base.dx - n.dx * 2.4, base.dy - n.dy * 2.4)
            ..close(),
          Paint()..color = palette.path);
    }
  }

  // ------------------------------------------------------------ equipamentos

  Paint get _eq => Paint()..color = palette.equipment;

  Paint get _eqDark => Paint()..color = palette.equipmentDark;

  void _staticProp(Canvas c, MotionProp pr) {
    switch (pr.type) {
      case 'bench':
        {
          final x = pr.val('x'), y = pr.val('y'), w = pr.val('w'), h = pr.val('h', 5);
          for (final lx in [x + 3, x + w - 5]) {
            c.drawRect(Rect.fromLTRB(lx, y + h, lx + 2.2, kGroundY), _eqDark);
          }
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(1.8)),
              Paint()..color = palette.pad);
          c.drawRect(Rect.fromLTWH(x + 1, y + 0.6, w - 2, 0.8), Paint()..color = _light(palette.pad, 0.25));
        }
      case 'box':
        {
          final r = Rect.fromLTWH(pr.val('x'), pr.val('y'), pr.val('w'), pr.val('h'));
          c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.2)), Paint()..color = const Color(0xFF9A7B5F));
          c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 1.6), Paint()..color = const Color(0xFF7A5D44));
        }
      case 'rect':
        {
          final op = pr.val('op', 1.0);
          final r = Rect.fromLTWH(pr.val('x'), pr.val('y'), pr.val('w'), pr.val('h'));
          c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.6)),
              Paint()..color = palette.pad.withAlpha((255 * op).round()));
        }
      case 'poly':
        {
          final pts = pr.points();
          if (pts.length < 3) return;
          c.drawPath(Path()..addPolygon(pts, true), Paint()..color = palette.pad);
        }
      case 'line':
        c.drawLine(Offset(pr.val('x1'), pr.val('y1')), Offset(pr.val('x2'), pr.val('y2')),
            _eqDark
              ..strokeWidth = pr.val('w', 2)
              ..strokeCap = StrokeCap.round);
      case 'rail':
        c.drawLine(Offset(pr.val('x'), pr.val('y1')), Offset(pr.val('x'), pr.val('y2')), _eq..strokeWidth = 1.6);
      case 'tower':
        {
          final x = pr.val('x');
          c.drawRect(Rect.fromLTRB(x, clip.viewport.top - 20, x + 6, kGroundY), _eqDark);
          c.drawRect(Rect.fromLTRB(x + 1.5, clip.viewport.top - 20, x + 2.3, kGroundY), _eq);
        }
      case 'pulley':
        {
          final o = Offset(pr.val('x'), pr.val('y'));
          c.drawCircle(o, 3.0, _eq);
          c.drawCircle(o, 1.1, _eqDark);
        }
      case 'bars':
        {
          final x1 = pr.val('x1'), x2 = pr.val('x2'), y = pr.val('y');
          for (final px in [x1 + 4, x2 - 4]) {
            c.drawRect(Rect.fromLTRB(px - 1.2, y, px + 1.2, kGroundY), _eqDark);
          }
          c.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTRB(x1, y - 1.6, x2, y + 1.6), const Radius.circular(1.6)), _eq);
        }
      case 'pullbar':
        {
          final x1 = pr.val('x1'), x2 = pr.val('x2'), y = pr.val('y');
          for (final px in [x1, x2]) {
            c.drawRect(Rect.fromLTRB(px - 1.4, clip.viewport.top - 20, px + 1.4, kGroundY), _eqDark);
          }
          c.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTRB(x1, y - 1.3, x2, y + 1.3), const Radius.circular(1.3)), _eq);
        }
      case 'mat':
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(pr.val('x'), kGroundY - 1.6, pr.val('x2'), kGroundY + 0.4),
                const Radius.circular(0.8)),
            Paint()..color = const Color(0xFF1E9E5A));
      case 'wall':
        {
          final x = pr.val('x');
          c.drawRect(Rect.fromLTRB(x - 30, clip.viewport.top - 20, x, kGroundY), Paint()..color = palette.floorLine);
        }
      case 'treadmill':
        {
          final x1 = pr.val('x1'), x2 = pr.val('x2');
          c.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTRB(x1, kGroundY - 4.5, x2, kGroundY), const Radius.circular(2)),
              _eqDark);
          c.drawLine(Offset(x2 - 3, kGroundY - 4), Offset(x2 + 6, 62), _eqDark..strokeWidth = 2.4);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x2 + 1, 56, 12, 6), const Radius.circular(1.5)),
              Paint()..color = palette.pad);
        }
      case 'circle':
        {
          final o = Offset(pr.val('x'), pr.val('y'));
          final r = pr.val('r', 10);
          c.drawCircle(o, r, Paint()..color = palette.pad.withAlpha(90));
          c.drawCircle(o, r, _eqDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2);
        }
      case 'bike':
        {
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
          c.drawRRect(
              RRect.fromRectAndRadius(Rect.fromCenter(center: seat, width: 14, height: 3.4), const Radius.circular(1.7)),
              Paint()..color = palette.pad);
          c.drawLine(Offset(bar.dx - 2, bar.dy + 6), bar, s);
          c.drawCircle(crank, 5, Paint()..color = palette.equipment);
        }
    }
  }

  void _trackedProp(Canvas c, MotionProp pr) {
    final p0 = _tp(pr.track[0]);
    switch (pr.type) {
      case 'plate':
        c.drawCircle(p0, 9.4, Paint()..color = _plateRim);
        c.drawCircle(p0, 8.0, Paint()..color = _shade(_plateRim, 0.18));
        c.drawCircle(p0, 5.6, Paint()
          ..color = _shade(_plateRim, 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7);
        c.drawCircle(p0, 1.9, Paint()..color = const Color(0xFFC9CDD4));
      case 'db_end':
        c.drawCircle(p0, 4.0, Paint()..color = _iron);
        c.drawCircle(p0, 2.6, Paint()
          ..color = _ironLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
        c.drawCircle(p0, 1.2, Paint()..color = const Color(0xFFC9CDD4));
      case 'db_side':
        {
          Offset axis;
          if (pr.flag('along') && pr.track.length > 1) {
            axis = _cw(_unit(p0 - _tp(pr.track[1])));
          } else {
            axis = _dir(pr.val('angle'));
          }
          final n = _cw(axis);
          void head(Offset center) {
            final path = Path()
              ..moveTo(center.dx + axis.dx * 1.9 + n.dx * 3.5, center.dy + axis.dy * 1.9 + n.dy * 3.5)
              ..lineTo(center.dx - axis.dx * 1.9 + n.dx * 3.5, center.dy - axis.dy * 1.9 + n.dy * 3.5)
              ..lineTo(center.dx - axis.dx * 1.9 - n.dx * 3.5, center.dy - axis.dy * 1.9 - n.dy * 3.5)
              ..lineTo(center.dx + axis.dx * 1.9 - n.dx * 3.5, center.dy + axis.dy * 1.9 - n.dy * 3.5)
              ..close();
            c.drawPath(path, Paint()..color = _iron);
          }

          c.drawLine(p0 - axis * 5, p0 + axis * 5, Paint()
            ..color = _ironLight
            ..strokeWidth = 1.5);
          head(p0 + axis * 5.3);
          head(p0 - axis * 5.3);
        }
      case 'kb':
        {
          final hand = _p(Jt.handN);
          final elbow = _p(Jt.elbN);
          final down = _unit(hand - elbow);
          final bell = hand + down * 5.8;
          c.drawCircle(hand + down * 1.4, 2.5, Paint()
            ..color = _iron
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
          c.drawCircle(bell, 4.8, Paint()..color = _iron);
          c.drawCircle(bell - Offset(1.4, 1.4), 1.2, Paint()..color = _ironLight);
        }
      case 'pad':
        {
          final r = pr.val('r', 4);
          c.drawCircle(p0, r, Paint()..color = palette.pad);
          c.drawCircle(p0, r * 0.35, Paint()..color = _shade(palette.pad, 0.3));
        }
      case 'lever':
        c.drawLine(Offset(pr.val('x'), pr.val('y')), p0, _eqDark
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
        c.drawCircle(Offset(pr.val('x'), pr.val('y')), 1.8, _eq);
      case 'sled':
        {
          final a = _dir(pr.val('angle') + 90);
          final half = pr.val('len', 30) / 2;
          c.drawLine(p0 - a * half, p0 + a * half, _eqDark
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round);
        }
      case 'cable':
        {
          final from = Offset(pr.val('x'), pr.val('y'));
          c.drawLine(from, p0, Paint()
            ..color = _cable
            ..strokeWidth = 0.6);
          c.drawCircle(p0, 1.4, Paint()..color = _cable);
        }
      case 'cablev':
        c.drawLine(Offset(p0.dx, pr.val('y')), p0, Paint()
          ..color = _cable
          ..strokeWidth = 0.6);
      case 'seg':
        if (pr.track.length < 2) return;
        c.drawLine(p0, _tp(pr.track[1]), Paint()
          ..color = _iron
          ..strokeWidth = pr.val('w', 2)
          ..strokeCap = StrokeCap.round);
      case 'band':
        if (pr.track.length < 2) return;
        c.drawLine(p0, _tp(pr.track[1]), Paint()
          ..color = _band
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);
      case 'rope':
        {
          if (pr.track.length < 3) return;
          final b = _tp(pr.track[1]);
          final ctrl = _tp(pr.track[2]);
          final path = Path()
            ..moveTo(p0.dx, p0.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
          c.drawPath(path, Paint()
            ..color = _cable
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
        }
    }
  }

  @override
  bool shouldRepaint(FigurePainter old) =>
      old.time != time || old.clip != clip || old.palette != palette || old.style != style || old.ghost != ghost;
}
