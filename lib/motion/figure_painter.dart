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
    floor: Color(0xFFDCE0E6),
    floorLine: Color(0xFFC9CFD8),
    equipment: Color(0xFF8A92A2),
    equipmentDark: Color(0xFF3B4250),
    pad: Color(0xFF2E3A57),
    path: Color(0xFF1F4FD8),
  );

  static const dark = FigurePalette(
    background: Color(0xFF1A1D23),
    floor: Color(0xFF252931),
    floorLine: Color(0xFF323741),
    equipment: Color(0xFF9AA2B2),
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
    required this.top,
    required this.bottom,
    required this.hair,
    required this.upperArm,
    required this.foreArm,
    required this.thigh,
    required this.calf,
    required this.torso,
    required this.male,
  });

  final Color skin, top, bottom, hair;
  final List<double> upperArm, foreArm, thigh, calf; // raio no início, no meio e no fim
  /// Tronco: (posição do quadril ao pescoço, meia largura, frente, costas).
  final List<List<double>> torso;
  final bool male;

  static const female = _Body(
    male: false,
    skin: Color(0xFFE0A47E),
    top: Color(0xFF1F4FD8),
    bottom: Color(0xFF2A2F3A),
    hair: Color(0xFF3A2416),
    upperArm: [3.2, 3.0, 2.5],
    foreArm: [2.6, 2.4, 1.8],
    thigh: [6.0, 5.7, 4.0],
    calf: [3.8, 4.1, 2.4],
    torso: [
      [-0.16, 9.2, 4.6, 6.8],
      [0.0, 11.0, 6.6, 9.0],
      [0.17, 10.4, 6.9, 8.6],
      [0.41, 7.6, 5.8, 5.8],
      [0.63, 9.2, 8.4, 6.4],
      [0.85, 10.2, 7.4, 6.8],
      [1.0, 8.4, 5.2, 5.4],
    ],
  );

  static const maleBody = _Body(
    male: true,
    skin: Color(0xFFD69A72),
    top: Color(0xFF1F4FD8),
    bottom: Color(0xFF2A2F3A),
    hair: Color(0xFF2A1C14),
    upperArm: [3.9, 3.7, 2.9],
    foreArm: [3.0, 2.8, 2.1],
    thigh: [6.2, 6.0, 4.3],
    calf: [4.0, 4.4, 2.6],
    torso: [
      [-0.15, 9.0, 4.8, 6.2],
      [0.0, 10.0, 6.8, 7.6],
      [0.2, 9.6, 6.8, 7.2],
      [0.43, 9.4, 6.6, 6.6],
      [0.67, 11.6, 9.0, 7.4],
      [0.87, 13.0, 8.4, 7.8],
      [1.0, 10.4, 6.2, 6.6],
    ],
  );
}

const _shoeColor = Color(0xFFF7F8FA);
const _sole = Color(0xFF8A93A3);
const _eye = Color(0xFF241812);
const _iron = Color(0xFF262A31);
const _ironLight = Color(0xFF5A606B);
const _chrome = Color(0xFFB9BFC9);
const _cable = Color(0xFF1C1F25);
const _band = Color(0xFF1E9E5A);
const _muscle = Color(0xFFFFB400);
const _plateRed = Color(0xFFE2382F);
const _wood = Color(0xFF9A7B5F);
const _mat = Color(0xFF1E9E5A);

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
}

Color _light(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + (1 - hsl.lightness) * amount).clamp(0.0, 1.0)).toColor();
}

Offset _unit(Offset v) {
  final d = v.distance;
  return d < 1e-6 ? const Offset(0, -1) : v / d;
}

Offset _cw(Offset v) => Offset(-v.dy, v.dx);

double _dot2(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

const _lightDir = Offset(-0.6, -0.8);
const _light3 = V3(0.35, 0.8, 0.5);

class _Draw {
  _Draw(this.depth, this.paint);
  final double depth;
  final void Function() paint;
}

/// Desenha um quadro do movimento em 3D: cenário, percurso, pessoa e
/// equipamentos, vistos de qualquer ângulo em volta da pessoa.
class FigurePainter extends CustomPainter {
  FigurePainter({
    required this.clip,
    required this.time,
    required this.palette,
    this.style = const FigureStyle(),
    this.ghost = true,
    this.yaw,
    this.pitch = 12,
  });

  final MotionClip clip;
  final double time;
  final FigurePalette palette;
  final FigureStyle style;
  final bool ghost;

  /// Giro da câmera em graus (0 = de lado, 90 = de frente). Nulo usa o ângulo
  /// em que o exercício foi desenhado.
  final double? yaw;
  final double pitch;

  late Camera _cam;
  late Float32List _f;
  late _Body _b;
  late List<Offset> _s; // articulações na tela
  late List<double> _d; // profundidade das articulações
  double _pulse = 0.5;

  V3 _j(int j) => MotionClip.joint(_f, j);

  V3 _vec(int index) => MotionClip.at(_f, index).unit;

  V3 _t3(int i) => MotionClip.at(_f, Jt.trackedBase + i * 3);

  void _load(double t) {
    _f = clip.sample(t);
    _s = List<Offset>.generate(Jt.count, (j) => _cam.project(_j(j)));
    _d = List<double>.generate(Jt.count, (j) => _cam.depth(_j(j)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (clip.frameCount == 0 || size.isEmpty) return;
    _b = style.male ? _Body.maleBody : _Body.female;
    _cam = Camera(yaw ?? clip.defaultYaw, pitch);
    _pulse = 0.5 + 0.5 * math.sin(time * math.pi * 4);

    final bounds = clip.boundsFor(_cam);
    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    _load(time);
    _floor(canvas, bounds);
    _shadow(canvas);

    // aparelhos grandes ficam atrás
    final boxes = clip.prims.where((p) => p.kind == 'box').toList()
      ..sort((a, b) => _primDepth(a).compareTo(_primDepth(b)));
    for (final p in boxes) {
      _box(canvas, p);
    }

    if (ghost && style.showPath) {
      _load(0);
      canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.16));
      for (final d in _bodyDraws(canvas, highlight: false)..sort((a, b) => a.depth.compareTo(b.depth))) {
        d.paint();
      }
      canvas.restore();
      _load(time);
    }

    final draws = <_Draw>[
      ..._bodyDraws(canvas, highlight: style.showMuscles),
      ..._propDraws(canvas),
      for (final p in clip.prims)
        if (p.kind != 'box') _Draw(_primDepth(p), () => p.kind == 'cyl' ? _cyl(canvas, p) : _disc(canvas, p)),
    ]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final d in draws) {
      d.paint();
    }
    if (style.showPath) _keyPath(canvas);
    canvas.restore();
  }

  // ------------------------------------------------------------ cenário

  void _floor(Canvas c, Rect bounds) {
    final hip = _j(Jt.hip);
    const span = 70.0;
    final x0 = hip.x - span, x1 = hip.x + span, z0 = hip.z - span, z1 = hip.z + span;
    final corners = [V3(x0, kFloorY, z0), V3(x1, kFloorY, z0), V3(x1, kFloorY, z1), V3(x0, kFloorY, z1)];
    final poly = [for (final p in corners) _cam.project(p)];
    // estende o chão até as bordas visíveis
    final path = Path()..addPolygon(poly, true);
    c.drawPath(path, Paint()..color = palette.floor);
    final line = Paint()
      ..color = palette.floorLine
      ..strokeWidth = 0.4;
    for (var v = -span; v <= span; v += 17.5) {
      c.drawLine(_cam.project(V3(hip.x + v, kFloorY, z0)), _cam.project(V3(hip.x + v, kFloorY, z1)), line);
      c.drawLine(_cam.project(V3(x0, kFloorY, hip.z + v)), _cam.project(V3(x1, kFloorY, hip.z + v)), line);
    }
  }

  void _shadow(Canvas c) {
    final a = _j(Jt.ankN), b = _j(Jt.ankF), h = _j(Jt.hip);
    final low = math.min(math.min(a.y, b.y), h.y);
    if (low > kFloorY + 30) return;
    final center = V3((a.x + b.x + h.x) / 3, kFloorY, (a.z + b.z + h.z) / 3);
    final pts = <Offset>[];
    for (var i = 0; i < 20; i++) {
      final ang = i / 20 * math.pi * 2;
      pts.add(_cam.project(center + V3(math.cos(ang) * 16, 0, math.sin(ang) * 10)));
    }
    c.drawPath(Path()..addPolygon(pts, true), Paint()..color = const Color(0x22000000));
  }

  Color _primColor(String role) {
    switch (role) {
      case 'pad':
        return palette.pad;
      case 'eq':
        return palette.equipment;
      case 'wood':
        return _wood;
      case 'mat':
        return _mat;
      case 'wall':
        return palette.floorLine;
      case 'belt':
        return _iron;
      default:
        return palette.equipmentDark;
    }
  }

  double _primDepth(Prim p) {
    var sum = 0.0;
    var n = 0;
    for (final q in p.points) {
      sum += _cam.depth(q);
      n++;
    }
    return n == 0 ? 0 : sum / n;
  }

  void _box(Canvas c, Prim p) {
    final base = _primColor(p.color);
    final front = p.face;
    final back = [for (final q in front) q + p.ext];
    final faces = <(List<V3>, double)>[];
    faces.add((front, 0.0));
    faces.add((back, 0.0));
    for (var i = 0; i < front.length; i++) {
      final j = (i + 1) % front.length;
      faces.add(([front[i], front[j], back[j], back[i]], 0.0));
    }
    final sorted = faces.map((f) {
      var dep = 0.0;
      for (final q in f.$1) {
        dep += _cam.depth(q);
      }
      return (f.$1, dep / f.$1.length);
    }).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    for (final f in sorted) {
      final pts = f.$1;
      if (pts.length < 3) continue;
      final nrm = (pts[1] - pts[0]).cross(pts[2] - pts[0]).unit;
      final lit = nrm.dot(_light3).abs();
      final col = Color.lerp(_shade(base, 0.3), _light(base, 0.12), lit) ?? base;
      c.drawPath(Path()..addPolygon([for (final q in pts) _cam.project(q)], true),
          Paint()..color = col.withAlpha((255 * p.opacity).round()));
    }
  }

  void _cyl(Canvas c, Prim p) {
    final a = _cam.project(p.a), b = _cam.project(p.b);
    final col = _primColor(p.color);
    c.drawLine(a, b, Paint()
      ..color = _shade(col, 0.2)
      ..strokeWidth = p.r * 2 + 0.6
      ..strokeCap = StrokeCap.round);
    c.drawLine(a, b, Paint()
      ..color = col
      ..strokeWidth = p.r * 2
      ..strokeCap = StrokeCap.round);
  }

  List<Offset> _circle3(V3 center, V3 normal, double r, [int n = 22]) {
    final nn = normal.unit;
    final helper = nn.y.abs() < 0.9 ? const V3(0, 1, 0) : const V3(1, 0, 0);
    final u = nn.cross(helper).unit;
    final v = nn.cross(u).unit;
    return [
      for (var i = 0; i < n; i++)
        _cam.project(center + u * (math.cos(i / n * math.pi * 2) * r) + v * (math.sin(i / n * math.pi * 2) * r)),
    ];
  }

  void _disc(Canvas c, Prim p) {
    final col = _primColor(p.color);
    final pts = _circle3(p.a, p.n, p.r);
    c.drawPath(Path()..addPolygon(pts, true), Paint()..color = col.withAlpha(150));
    c.drawPath(Path()..addPolygon(pts, true), Paint()
      ..color = _shade(col, 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9);
  }

  // ------------------------------------------------------------ formas 2D

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
    return Path()
      ..moveTo(a.dx + n.dx * ra2, a.dy + n.dy * ra2)
      ..quadraticBezierTo(m.dx + n.dx * rm2 * 1.12, m.dy + n.dy * rm2 * 1.12, b.dx + n.dx * rb2, b.dy + n.dy * rb2)
      ..arcToPoint(Offset(b.dx - n.dx * rb2, b.dy - n.dy * rb2), radius: Radius.circular(rb2), clockwise: false)
      ..quadraticBezierTo(m.dx - n.dx * rm2 * 1.12, m.dy - n.dy * rm2 * 1.12, a.dx - n.dx * ra2, a.dy - n.dy * ra2)
      ..arcToPoint(Offset(a.dx + n.dx * ra2, a.dy + n.dy * ra2), radius: Radius.circular(ra2), clockwise: false)
      ..close();
  }

  Paint _gradientAcross(Offset a, Offset b, double r, Color base) {
    var n = _cw(_unit(b - a));
    if (_dot2(n, _lightDir) < 0) n = -n;
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

  void _limb(Canvas c, Offset a, Offset b, List<double> r, Color color) {
    c.drawPath(_limbPath(a, b, r[0], r[1], r[2], grow: 0.5), Paint()..color = _shade(color, 0.45));
    c.drawPath(_limbPath(a, b, r[0], r[1], r[2]), _gradientAcross(a, b, math.max(r[0], r[1]), color));
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

  /// Metade de um segmento, do lado [side] do eixo na tela.
  Path _halfLimb(Offset a, Offset b, double ra, double rb, Offset side, {double from = 0.08, double to = 0.92}) {
    final d = b - a;
    final p0 = a + d * from, p1 = a + d * to;
    final m = a + d * 0.45;
    final rm = (ra + rb) / 2 * 1.15;
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p0.dx + side.dx * ra * 0.95, p0.dy + side.dy * ra * 0.95)
      ..quadraticBezierTo(m.dx + side.dx * rm, m.dy + side.dy * rm, p1.dx + side.dx * rb * 0.95,
          p1.dy + side.dy * rb * 0.95)
      ..lineTo(p1.dx, p1.dy)
      ..close();
  }

  // ------------------------------------------------------------ destaque muscular

  bool _wants(String g) => style.primary.contains(g) || style.secondary.contains(g);

  Paint _musclePaint(String g, {double factor = 1}) {
    final a = style.primary.contains(g) ? 0.42 + 0.28 * _pulse : 0.24 + 0.08 * _pulse;
    return Paint()..color = _muscle.withAlpha((255 * a * factor).round().clamp(0, 255));
  }

  /// Desenha o destaque de um músculo que fica do lado [dir3] de um segmento.
  void _sideMuscle(Canvas c, String g, Offset a, Offset b, double ra, double rb, V3 dir3,
      {double from = 0.08, double to = 0.92, double factor = 1}) {
    if (!_wants(g)) return;
    final d2 = _cam.projectDir(dir3);
    final n = _cw(_unit(b - a));
    final side = _dot2(d2, n);
    if (side.abs() > 0.3) {
      c.drawPath(_halfLimb(a, b, ra, rb, side > 0 ? n : -n, from: from, to: to), _musclePaint(g, factor: factor));
    } else if (dir3.dot(_cam.toward) > 0) {
      // o músculo está virado para quem vê: destaca o segmento inteiro
      final p0 = a + (b - a) * from, p1 = a + (b - a) * to;
      c.drawPath(_limbPath(p0, p1, ra * 0.8, (ra + rb) / 2 * 0.85, rb * 0.8), _musclePaint(g, factor: factor * 0.9));
    }
  }

  V3 _perp(V3 v, V3 axis) {
    final a = axis.unit;
    return v - a * v.dot(a);
  }

  // ------------------------------------------------------------ corpo

  List<_Draw> _bodyDraws(Canvas c, {required bool highlight}) {
    final hipD = (_d[Jt.hip] + _d[Jt.neck]) / 2;
    double avg(List<int> js) => js.map((j) => _d[j]).reduce((a, b) => a + b) / js.length;
    return [
      _Draw(hipD + 1, () => _torso(c, highlight)),
      _Draw(_d[Jt.head] + 1.5, () => _neckAndHead(c)),
      _Draw(avg([Jt.shN, Jt.elbN, Jt.handN]) + 2, () => _arm(c, Jt.shN, Jt.elbN, Jt.handN, highlight)),
      _Draw(avg([Jt.shF, Jt.elbF, Jt.handF]) + 2, () => _arm(c, Jt.shF, Jt.elbF, Jt.handF, highlight)),
      _Draw(avg([Jt.hipN, Jt.kneeN, Jt.ankN]), () => _leg(c, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, highlight)),
      _Draw(avg([Jt.hipF, Jt.kneeF, Jt.ankF]), () => _leg(c, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, highlight)),
    ];
  }

  V3 get _torsoUp => (_j(Jt.neck) - _j(Jt.hip)).unit;

  V3 get _torsoFront {
    final f = _perp(_vec(Jt.torsoFront), _torsoUp);
    return f.length < 1e-3 ? const V3(1, 0, 0) : f.unit;
  }

  void _arm(Canvas c, int sh, int elb, int hand, bool highlight) {
    final s = _s[sh], e = _s[elb], h = _s[hand];
    final skin = _b.skin;
    // ombro
    _circle(c, s, _b.male ? 4.3 : 3.6, _b.male ? _b.top : skin, outline: 0.4);
    _limb(c, s, e, _b.upperArm, skin);
    if (_b.male) {
      final sleeveEnd = s + (e - s) * 0.42;
      _limb(c, s, sleeveEnd, [_b.upperArm[0] + 0.7, _b.upperArm[0] + 0.6, _b.upperArm[1] + 0.5], _b.top);
    }
    _limb(c, e, h, _b.foreArm, skin);
    final fd = _unit(h - e);
    _circle(c, h + fd * 0.6, _b.male ? 2.5 : 2.2, skin, outline: 0.45);
    _circle(c, h + _cw(fd) * 1.3, 0.95, _shade(skin, 0.06), outline: 0.3);
    if (!highlight || !style.showMuscles) return;
    final s3 = _j(sh), e3 = _j(elb), h3 = _j(hand);
    final upper = e3 - s3, fore = h3 - e3;
    var anterior = _perp(fore, upper);
    if (anterior.length < 2) anterior = _torsoFront;
    final r = _b.upperArm;
    _sideMuscle(c, 'biceps', s, e, r[0], r[2], anterior, from: 0.2);
    _sideMuscle(c, 'triceps', s, e, r[0], r[2], -anterior, from: 0.15);
    if (_wants('antebraco')) {
      c.drawPath(_limbPath(e, h, _b.foreArm[0] * 0.85, _b.foreArm[1] * 0.85, _b.foreArm[2] * 0.7),
          _musclePaint('antebraco'));
    }
    if (_wants('ombros')) c.drawCircle(s, _b.male ? 4.4 : 3.8, _musclePaint('ombros'));
  }

  void _leg(Canvas c, int hip, int knee, int ank, int toe, bool highlight) {
    final hp = _s[hip], k = _s[knee], a = _s[ank], t = _s[toe];
    if (_b.male) {
      _limb(c, hp, k, _b.thigh, _b.skin);
      final shortsEnd = hp + (k - hp) * 0.78;
      _limb(c, hp, shortsEnd, [_b.thigh[0] + 0.6, _b.thigh[1] + 0.7, _b.thigh[1] + 0.3], _b.bottom);
      _limb(c, k, a, _b.calf, _b.skin);
      _limb(c, a - _unit(a - k) * 2.0, a, const [2.6, 2.6, 2.5], const Color(0xFFF2F2F2));
    } else {
      _limb(c, hp, k, _b.thigh, _b.bottom);
      _limb(c, k, a, _b.calf, _b.bottom);
    }
    _shoe(c, k, a, t);
    if (!highlight || !style.showMuscles) return;
    final h3 = _j(hip), k3 = _j(knee), a3 = _j(ank);
    final thigh = k3 - h3, shin = a3 - k3;
    var anterior = _perp(-shin, thigh);
    if (anterior.length < 2) anterior = _torsoFront;
    var calfSide = _perp(h3 - k3, shin);
    if (calfSide.length < 2) calfSide = -_torsoFront;
    final outward = _perp(h3 - _j(Jt.hip), thigh);
    _sideMuscle(c, 'quadriceps', hp, k, 5.7, 4.0, anterior);
    _sideMuscle(c, 'posterior', hp, k, 5.7, 4.0, -anterior);
    if (outward.length > 1) {
      _sideMuscle(c, 'adutores', hp, k, 5.6, 3.8, -outward, to: 0.7);
      _sideMuscle(c, 'abdutores', hp, k, 5.8, 4.0, outward, to: 0.35);
    }
    _sideMuscle(c, 'panturrilha', k, a, 3.9, 2.4, calfSide, from: 0.12, to: 0.7);
  }

  void _shoe(Canvas c, Offset knee, Offset ank, Offset toe) {
    final fd = _unit(toe - ank);
    final footLen = (toe - ank).distance;
    final heel = footLen < 3 ? ank : ank - fd * 2.8;
    var n = _cw(fd);
    if (_dot2(n, knee - ank) > 0) n = -n;
    _limb(c, heel, toe, const [2.8, 2.9, 2.4], _shoeColor);
    c.drawPath(_limbPath(heel + n * 2.0, toe + n * 1.7, 1.0, 1.0, 0.9), Paint()..color = _sole);
    c.drawPath(_limbPath(heel - n * 0.2 + fd * 1.4, heel - n * 0.6 + fd * 4.0, 0.6, 0.6, 0.5),
        Paint()..color = const Color(0xFFF5B700));
  }

  void _torso(Canvas c, bool highlight) {
    final hip = _s[Jt.hip], neck = _s[Jt.neck];
    final axis = neck - hip;
    final len = axis.distance;
    final u = _unit(axis);
    final n = _cw(u);
    final up3 = _torsoUp;
    final f3 = _torsoFront;
    final l3 = up3.cross(f3).unit;
    final fn = _dot2(_cam.projectDir(f3), n);
    final ln = _dot2(_cam.projectDir(l3), n);

    final plus = <Offset>[], minus = <Offset>[];
    for (final r in _b.torso) {
      final t = r[0], a = r[1], bf = r[2], bb = r[3];
      final bPlus = fn >= 0 ? bf : bb;
      final bMinus = fn >= 0 ? bb : bf;
      final ePlus = math.sqrt(math.pow(a * ln, 2) + math.pow(bPlus * fn, 2));
      final eMinus = math.sqrt(math.pow(a * ln, 2) + math.pow(bMinus * fn, 2));
      final p = hip + u * (t * len);
      plus.add(p + n * math.max(ePlus, 4.5));
      minus.add(p - n * math.max(eMinus, 4.5));
    }
    final body = _smoothClosed([...plus, ...minus.reversed]);

    c.drawPath(body, Paint()
      ..color = _shade(_b.bottom, 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1);
    c.drawPath(body, Paint()..color = _b.skin);
    c.save();
    c.clipPath(body);
    Path band(double t0, double t1, [double s0 = 30, double s1 = -30]) {
      final a = hip + u * (t0 * len);
      final b = hip + u * (t1 * len);
      return Path()
        ..moveTo(a.dx + n.dx * s0, a.dy + n.dy * s0)
        ..lineTo(b.dx + n.dx * s0, b.dy + n.dy * s0)
        ..lineTo(b.dx + n.dx * s1, b.dy + n.dy * s1)
        ..lineTo(a.dx + n.dx * s1, a.dy + n.dy * s1)
        ..close();
    }

    c.drawPath(band(-0.6, _b.male ? 0.34 : 0.40), Paint()..color = _b.bottom);
    c.drawPath(band(_b.male ? 0.30 : 0.47, 1.4), _gradientAcross(hip + u * (0.6 * len), neck, 12, _b.top));
    c.drawPath(band(_b.male ? 0.30 : 0.37, _b.male ? 0.34 : 0.40), Paint()..color = _shade(_b.bottom, 0.35));
    if (!_b.male) c.drawPath(band(0.47, 0.50), Paint()..color = _shade(_b.top, 0.25));
    // volume: sombra no lado oposto à luz
    final shadowSide = _dot2(n, _lightDir) > 0 ? -1.0 : 1.0;
    c.drawPath(band(-0.6, 1.4, shadowSide * 3, shadowSide * 30), Paint()..color = const Color(0x1C000000));

    if (highlight && style.showMuscles) {
      final facing = f3.dot(_cam.toward);
      final frontSide = fn >= 0 ? 1.0 : -1.0;
      if (fn.abs() > 0.35) {
        // de lado: frente e costas aparecem nas bordas
        final fs = frontSide;
        if (_wants('peito')) c.drawPath(band(0.6, 0.95, fs * 0.5, fs * 14), _musclePaint('peito'));
        if (_wants('abdomen')) c.drawPath(band(0.1, 0.56, fs * 0.5, fs * 14), _musclePaint('abdomen'));
        if (_wants('costas')) c.drawPath(band(0.46, 0.92, -fs * 0.5, -fs * 14), _musclePaint('costas'));
        if (_wants('lombar')) c.drawPath(band(0.1, 0.44, -fs * 0.5, -fs * 14), _musclePaint('lombar'));
        if (_wants('trapezio')) c.drawPath(band(0.86, 1.15, fs * 1.5, -fs * 14), _musclePaint('trapezio'));
        if (_wants('gluteos')) c.drawPath(band(-0.3, 0.16, -fs * 1.0, -fs * 14), _musclePaint('gluteos'));
      } else if (facing >= 0) {
        // de frente
        if (_wants('peito')) {
          c.drawOval(Rect.fromCenter(center: hip + u * (0.74 * len) + n * 4.2, width: 8, height: 6.5), _musclePaint('peito'));
          c.drawOval(Rect.fromCenter(center: hip + u * (0.74 * len) - n * 4.2, width: 8, height: 6.5), _musclePaint('peito'));
        }
        if (_wants('abdomen')) c.drawPath(band(0.12, 0.6, -4.2, 4.2), _musclePaint('abdomen'));
        if (_wants('costas')) {
          c.drawPath(band(0.45, 0.84, 7.5, 14), _musclePaint('costas', factor: 0.8));
          c.drawPath(band(0.45, 0.84, -7.5, -14), _musclePaint('costas', factor: 0.8));
        }
        if (_wants('trapezio')) c.drawPath(band(0.9, 1.1, -8, 8), _musclePaint('trapezio'));
      } else {
        // de costas
        if (_wants('costas')) c.drawPath(band(0.46, 0.92, -14, 14), _musclePaint('costas'));
        if (_wants('lombar')) c.drawPath(band(0.12, 0.44, -6, 6), _musclePaint('lombar'));
        if (_wants('trapezio')) c.drawPath(band(0.84, 1.1, -10, 10), _musclePaint('trapezio'));
        if (_wants('gluteos')) c.drawPath(band(-0.3, 0.12, -14, 14), _musclePaint('gluteos'));
      }
    }
    c.restore();
  }

  void _neckAndHead(Canvas c) {
    final neck = _s[Jt.neck];
    final head = _s[Jt.head];
    final up3 = _vec(Jt.headUp);
    final face3 = _perp(_vec(Jt.headFace), up3).unit;
    final side3 = up3.cross(face3).unit;
    final up = _unit(_cam.projectDir(up3));
    final face2 = _cam.projectDir(face3); // comprimento = quanto o rosto está de perfil
    final side2 = _cam.projectDir(side3);
    final facing = face3.dot(_cam.toward); // 1 = de frente para quem vê, -1 = de costas

    _limb(c, neck, neck + (head - neck) * 0.55, [_b.male ? 3.0 : 2.5, _b.male ? 2.9 : 2.4, 2.3], _b.skin);
    final hairPaint = Paint()..color = _b.hair;

    // rabo de cavalo atrás da cabeça (desenhado antes quando o rosto está de frente)
    void ponytail() {
      if (_b.male) return;
      final tie = head - face2 * 6.4 + up * 2.6 - _unit(face2.distance < 0.2 ? up : face2) * 0.4;
      c.drawPath(_limbPath(tie, tie - face2 * 3.2 - up * 5.6, 2.6, 2.3, 1.3), hairPaint);
    }

    if (facing > 0) ponytail();
    // cabeça: cabelo atrás, rosto na frente
    _circle(c, head - face2 * 0.8 + up * 0.5, _b.male ? 7.0 : 7.4, _b.hair, outline: 0.4);
    if (facing > -0.35) {
      final skinCenter = head + face2 * 0.9 - up * 0.3;
      _circle(c, skinCenter, 6.5 - (1 - face2.distance) * 0.1, _b.skin, outline: 0);
      // cabelo no topo da testa
      c.drawCircle(head - face2 * 0.4 + up * (_b.male ? 3.3 : 2.8), _b.male ? 4.6 : 5.2, hairPaint);
      // orelha quando de perfil
      if (face2.distance > 0.35) {
        _circle(c, head - face2 * 0.6 - up * 0.3, 1.5, _shade(_b.skin, 0.12), outline: 0);
      }
      // olhos (dois de frente, um de perfil)
      final eyeBase = head + face2 * 4.0 + up * 0.5;
      final spread = side2 * 2.4;
      c.drawCircle(eyeBase + spread, 0.78, Paint()..color = _eye);
      if (spread.distance > 0.6) c.drawCircle(eyeBase - spread, 0.78, Paint()..color = _eye);
      // sobrancelhas
      final brow = Paint()
        ..color = _shade(_b.hair, 0.1)
        ..strokeWidth = 0.55
        ..strokeCap = StrokeCap.round;
      for (final sgn in const [1.0, -1.0]) {
        final e = eyeBase + spread * sgn + up * 1.7;
        c.drawLine(e - _unit(side2.distance > 0.3 ? side2 : face2) * 0.9, e + _unit(side2.distance > 0.3 ? side2 : face2) * 0.9, brow);
        if (spread.distance <= 0.6) break;
      }
      // nariz de perfil
      if (face2.distance > 0.45) {
        final f = _unit(face2);
        final nose = head + f * 6.6 - up * 0.6;
        c.drawPath(
            Path()
              ..moveTo(nose.dx + up.dx * 1.6, nose.dy + up.dy * 1.6)
              ..lineTo(nose.dx + f.dx * 1.3 - up.dx * 0.4, nose.dy + f.dy * 1.3 - up.dy * 0.4)
              ..lineTo(nose.dx - up.dx * 1.0, nose.dy - up.dy * 1.0)
              ..close(),
            Paint()..color = _b.skin);
      }
      // boca
      final mouth = head + face2 * 4.6 - up * 3.0;
      final mDir = side2.distance > 0.3 ? _unit(side2) : _unit(face2);
      c.drawLine(mouth - mDir * 1.0, mouth + mDir * 1.0,
          Paint()
            ..color = _shade(_b.skin, 0.38)
            ..strokeWidth = 0.6
            ..strokeCap = StrokeCap.round);
    } else {
      // de costas: só cabelo
      _circle(c, head, _b.male ? 6.8 : 7.3, _b.hair, outline: 0);
    }
    if (facing <= 0) ponytail();
  }

  // ------------------------------------------------------------ equipamentos móveis

  List<_Draw> _propDraws(Canvas c) {
    final out = <_Draw>[];
    for (final pr in clip.props) {
      if (pr.track.isEmpty) continue;
      final a3 = _t3(pr.track[0]);
      switch (pr.type) {
        case 'barbell': {
          const lat = V3(0, 0, 1);
          final pN = a3 + lat * 29, pF = a3 - lat * 29;
          out.add(_Draw(_cam.depth(pF), () => _plate(c, pF, lat)));
          out.add(_Draw(_cam.depth(a3) + 1.8, () {
            final b0 = _cam.project(a3 - lat * 38), b1 = _cam.project(a3 + lat * 38);
            c.drawLine(b0, b1, Paint()
              ..color = _chrome
              ..strokeWidth = 1.5
              ..strokeCap = StrokeCap.round);
          }));
          out.add(_Draw(_cam.depth(pN), () => _plate(c, pN, lat)));
        }
        case 'dumbbell': {
          if (pr.track.length < 2) continue;
          final axis = (_t3(pr.track[1]) - a3).unit;
          out.add(_Draw(_cam.depth(a3) + 2.5, () => _dumbbell(c, a3, axis)));
        }
        case 'kettlebell': {
          if (pr.track.length < 2) continue;
          final elbow = _t3(pr.track[1]);
          final down = (a3 - elbow).unit;
          out.add(_Draw(_cam.depth(a3) + 2.5, () {
            final bell = a3 + down * 5.8;
            final hp = _cam.project(a3 + down * 1.4);
            c.drawCircle(hp, 2.5, Paint()
              ..color = _iron
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
            final bp = _cam.project(bell);
            c.drawCircle(bp, 4.9, Paint()..color = _iron);
            c.drawCircle(bp - const Offset(1.4, 1.4), 1.2, Paint()..color = _ironLight);
          }));
        }
        case 'padcyl': {
          if (pr.track.length < 2) continue;
          final b3 = _t3(pr.track[1]);
          final r = pr.val('r', 4);
          out.add(_Draw((_cam.depth(a3) + _cam.depth(b3)) / 2, () {
            final pa = _cam.project(a3), pb = _cam.project(b3);
            c.drawLine(pa, pb, Paint()
              ..color = _shade(palette.pad, 0.25)
              ..strokeWidth = r * 2 + 0.6
              ..strokeCap = StrokeCap.round);
            c.drawLine(pa, pb, Paint()
              ..color = palette.pad
              ..strokeWidth = r * 2
              ..strokeCap = StrokeCap.round);
          }));
        }
        case 'lever': {
          if (pr.track.length < 2) continue;
          final b3 = _t3(pr.track[1]);
          out.add(_Draw((_cam.depth(a3) + _cam.depth(b3)) / 2, () {
            c.drawLine(_cam.project(a3), _cam.project(b3), Paint()
              ..color = palette.equipmentDark
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round);
            c.drawCircle(_cam.project(a3), 1.8, Paint()..color = palette.equipment);
          }));
        }
        case 'quad': {
          if (pr.track.length < 4) continue;
          final pts3 = [for (final i in pr.track) _t3(i)];
          final dep = pts3.map(_cam.depth).reduce((a, b) => a + b) / 4;
          out.add(_Draw(dep - 3, () {
            c.drawPath(Path()..addPolygon([for (final p in pts3) _cam.project(p)], true),
                Paint()..color = palette.equipmentDark);
          }));
        }
        case 'cable': {
          if (pr.track.length < 2) continue;
          final b3 = _t3(pr.track[1]);
          out.add(_Draw(math.min(_cam.depth(a3), _cam.depth(b3)) - 1, () {
            c.drawLine(_cam.project(a3), _cam.project(b3), Paint()
              ..color = _cable
              ..strokeWidth = 0.6);
            c.drawCircle(_cam.project(b3), 1.3, Paint()..color = _cable);
          }));
        }
        case 'grip': {
          if (pr.track.length < 2) continue;
          final b3 = _t3(pr.track[1]);
          final w = pr.val('r', 1.1) * 2;
          out.add(_Draw((_cam.depth(a3) + _cam.depth(b3)) / 2 + 2.5, () {
            final pa = _cam.project(a3), pb = _cam.project(b3);
            final ext = _unit(pb - pa) * 4;
            c.drawLine(pa - ext, pb + ext, Paint()
              ..color = _iron
              ..strokeWidth = w
              ..strokeCap = StrokeCap.round);
          }));
        }
        case 'band': {
          if (pr.track.length < 2) continue;
          final b3 = _t3(pr.track[1]);
          out.add(_Draw(math.max(_cam.depth(a3), _cam.depth(b3)) + 1, () {
            c.drawLine(_cam.project(a3), _cam.project(b3), Paint()
              ..color = _band
              ..strokeWidth = 1.6
              ..strokeCap = StrokeCap.round);
          }));
        }
        case 'rope': {
          if (pr.track.length < 3) continue;
          final b3 = _t3(pr.track[1]);
          final ctrl3 = _t3(pr.track[2]);
          out.add(_Draw(_cam.depth(ctrl3), () {
            final pa = _cam.project(a3), pb = _cam.project(b3), pc = _cam.project(ctrl3);
            c.drawPath(
                Path()
                  ..moveTo(pa.dx, pa.dy)
                  ..quadraticBezierTo(pc.dx, pc.dy, pb.dx, pb.dy),
                Paint()
                  ..color = _cable
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 0.9);
          }));
        }
      }
    }
    return out;
  }

  void _plate(Canvas c, V3 center, V3 axis) {
    final outer = _circle3(center, axis, 9.4);
    c.drawPath(Path()..addPolygon(outer, true), Paint()..color = _plateRed);
    c.drawPath(Path()..addPolygon(_circle3(center, axis, 7.8), true), Paint()..color = _shade(_plateRed, 0.18));
    c.drawPath(Path()..addPolygon(_circle3(center, axis, 2.0, 12), true), Paint()..color = _chrome);
    c.drawPath(Path()..addPolygon(outer, true), Paint()
      ..color = _shade(_plateRed, 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6);
  }

  void _dumbbell(Canvas c, V3 center, V3 axis) {
    final a = _cam.project(center - axis * 5.4), b = _cam.project(center + axis * 5.4);
    c.drawLine(a, b, Paint()
      ..color = _chrome
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round);
    for (final sgn in const [-1.0, 1.0]) {
      final hc = center + axis * (5.6 * sgn);
      for (final off in const [-1.0, 1.0]) {
        final pts = _circle3(hc + axis * off, axis, 3.5, 14);
        c.drawPath(Path()..addPolygon(pts, true), Paint()..color = off * sgn > 0 ? _iron : _ironLight);
      }
    }
  }

  // ------------------------------------------------------------ percurso

  void _keyPath(Canvas c) {
    final path = clip.keyPath;
    if (path.length < 3 || clip.keyPathExtent < 6) return;
    final pts = [for (final p in path) _cam.project(p)];
    final paint = Paint()
      ..color = palette.path.withAlpha(150)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length; i += 2) {
      c.drawLine(pts[i], pts[(i + 1) % pts.length], paint);
    }
    final cur = _cam.project(clip.keyPointAt(time));
    final prev = _cam.project(clip.keyPointAt(time - 0.04));
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

  @override
  bool shouldRepaint(FigurePainter old) =>
      old.time != time ||
      old.clip != clip ||
      old.palette != palette ||
      old.style != style ||
      old.ghost != ghost ||
      old.yaw != yaw ||
      old.pitch != pitch;
}
