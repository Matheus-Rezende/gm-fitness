import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'mesh3d.dart';
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

const _shoeColor = Color(0xFFF2F4F7);
const _sole = Color(0xFF7D8696);
const _shoeAccent = Color(0xFFF5B700);
const _eye = Color(0xFF241812);
const _eyeWhite = Color(0xFFF4EEE8);
const _lips = Color(0xFFB5655A);
const _iron = Color(0xFF2B2F37);
const _chrome = Color(0xFFC3C8D0);
const _cable = Color(0xFF1C1F25);
const _band = Color(0xFF1E9E5A);
const _muscle = Color(0xFFFFB400);
const _plateRed = Color(0xFFD9342B);
const _wood = Color(0xFF9A7B5F);
const _mat = Color(0xFF1E9E5A);
const _sock = Color(0xFFF2F2F2);

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
}

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Janela suave: 0 fora de [a, b], 1 no meio.
double _window(double x, double a, double b) {
  if (x <= a || x >= b) return 0;
  return math.sin(math.pi * (x - a) / (b - a));
}

Offset _unit(Offset v) {
  final d = v.distance;
  return d < 1e-6 ? const Offset(0, -1) : v / d;
}

Offset _cw(Offset v) => Offset(-v.dy, v.dx);

double _sgnPow(double v, double e) => v < 0 ? -math.pow(-v, e).toDouble() : math.pow(v, e).toDouble();

/// Saliência de um músculo em uma direção da seção do membro.
class _Bulge {
  const _Bulge(this.s0, this.s1, this.angle, this.amount);
  final double s0, s1;

  /// 0 = na direção de referência (frente do membro), pi = atrás.
  final double angle;
  final double amount;
}

/// Desenha um quadro do movimento em 3D: cenário, percurso, pessoa e
/// equipamentos, vistos de qualquer ângulo em volta da pessoa. A pessoa e os
/// aparelhos são malhas 3D de verdade, com luz e sombra, então não deformam
/// quando a câmera gira.
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
  double _pulse = 0.5;

  V3 _j(int j) => MotionClip.joint(_f, j);

  V3 _vec(int index) => MotionClip.at(_f, index).unit;

  V3 _t3(int i) => MotionClip.at(_f, Jt.trackedBase + i * 3);

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

    _f = clip.sample(time);
    _floor(canvas);
    _shadow(canvas);

    if (ghost && style.showPath) {
      _f = clip.sample(0);
      final g = Mesh();
      _body(g, highlight: false, detail: 0);
      canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.16));
      g.draw(canvas, _cam);
      canvas.restore();
      _f = clip.sample(time);
    }

    final m = Mesh();
    for (final p in clip.prims) {
      _prim(m, p);
    }
    _body(m, highlight: style.showMuscles, detail: size.shortestSide < 120 ? 0 : 1);
    _props(m);
    m.draw(canvas, _cam, highlight: _muscle);
    if (style.showPath) _keyPath(canvas);
    canvas.restore();
  }

  // ------------------------------------------------------------ cenário

  void _floor(Canvas c) {
    final hip = _j(Jt.hip);
    const span = 70.0;
    final x0 = hip.x - span, x1 = hip.x + span, z0 = hip.z - span, z1 = hip.z + span;
    final corners = [V3(x0, kFloorY, z0), V3(x1, kFloorY, z0), V3(x1, kFloorY, z1), V3(x0, kFloorY, z1)];
    final poly = [for (final p in corners) _cam.project(p)];
    c.drawPath(Path()..addPolygon(poly, true), Paint()..color = palette.floor);
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
    for (final (rx, rz, alpha) in const [(18.0, 12.0, 0x14), (13.0, 8.5, 0x18)]) {
      final pts = <Offset>[];
      for (var i = 0; i < 24; i++) {
        final ang = i / 24 * math.pi * 2;
        pts.add(_cam.project(center + V3(math.cos(ang) * rx, 0, math.sin(ang) * rz)));
      }
      c.drawPath(Path()..addPolygon(pts, true), Paint()..color = Color.fromARGB(alpha, 0, 0, 0));
    }
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

  void _prim(Mesh m, Prim p) {
    final col = _primColor(p.color);
    switch (p.kind) {
      case 'box':
        m.box(p.face, p.ext, col.withAlpha((255 * p.opacity).round()));
      case 'cyl':
        m.cylinder(p.a, p.b, p.r, col, cap: _shade(col, 0.1), sides: 12, gloss: 0.15);
      default:
        final n = p.n.unit;
        m.cylinder(p.a - n * 0.3, p.a + n * 0.3, p.r, col.withAlpha(170), sides: 20);
    }
  }

  // ------------------------------------------------------------ destaque muscular

  /// Intensidade do destaque do grupo [g] (0 se não estiver em destaque).
  double _mw(String g) {
    if (style.primary.contains(g)) return 0.40 + 0.26 * _pulse;
    if (style.secondary.contains(g)) return 0.22 + 0.08 * _pulse;
    return 0;
  }

  // ------------------------------------------------------------ corpo

  V3 get _torsoUp => (_j(Jt.neck) - _j(Jt.hip)).unit;

  V3 get _torsoFront {
    final f = perpTo(_vec(Jt.torsoFront), _torsoUp);
    return f.length < 1e-3 ? const V3(1, 0, 0) : f.unit;
  }

  void _body(Mesh m, {required bool highlight, required int detail}) {
    final sides = detail == 0 ? 9 : 14;
    final hl = highlight;
    _torso(m, hl, detail == 0 ? 12 : 20);
    _neckAndHead(m, detail);
    _arm(m, Jt.shN, Jt.elbN, Jt.handN, hl, sides);
    _arm(m, Jt.shF, Jt.elbF, Jt.handF, hl, sides);
    _leg(m, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, hl, sides);
    _leg(m, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, hl, sides);
  }

  /// Membro de [a] a [b] com raio [r] (início, meio, fim), seção que pode
  /// ter saliências musculares e pontas arredondadas.
  void _limb(
    Mesh m,
    V3 a,
    V3 b,
    V3 ref,
    List<double> r, {
    required Color Function(double s, double ang) color,
    double Function(double s, double ang)? muscle,
    List<_Bulge> bulges = const [],
    List<double> breaks = const [],
    double flatten = 1.0,
    int sides = 12,
    int steps = 8,
    bool capA = true,
    bool capB = true,
    double gloss = 0.05,
  }) {
    final axis = b - a;
    final len = axis.length;
    if (len < 0.01) return;
    final u = axis * (1 / len);
    var v = perpTo(ref, u);
    v = v.length < 1e-3 ? perpendicular(u) : v.unit;
    final w = u.cross(v).unit;

    double radius(double s) {
      if (s < 0.45) return r[0] + (r[1] - r[0]) * _smooth(s / 0.45);
      return r[1] + (r[2] - r[1]) * _smooth((s - 0.45) / 0.55);
    }

    double bulge(double s, double ang) {
      var k = 1.0;
      for (final bl in bulges) {
        final c = math.cos(ang - bl.angle);
        if (c > 0) k += bl.amount * _window(s, bl.s0, bl.s1) * c * c;
      }
      return k;
    }

    final ss = <double>{for (var i = 0; i <= steps; i++) i / steps};
    for (final br in breaks) {
      ss
        ..add((br - 0.002).clamp(0.0, 1.0))
        ..add((br + 0.002).clamp(0.0, 1.0));
    }
    final sList = ss.toList()..sort();

    final rings = <List<V3>>[];
    final centers = <V3>[];
    final cols = <List<Color>>[];
    final mus = <List<double>>[];
    final angs = [for (var j = 0; j < sides; j++) 2 * math.pi * j / sides];

    void addRing(V3 center, double s, double rScale, double sForColor) {
      final rs = radius(s) * rScale;
      rings.add([
        for (final ang in angs)
          center + v * (math.cos(ang) * rs * bulge(s, ang)) + w * (math.sin(ang) * rs * flatten * bulge(s, ang)),
      ]);
      centers.add(center);
      cols.add([for (final ang in angs) color(sForColor, ang)]);
      mus.add([for (final ang in angs) muscle?.call(sForColor, ang) ?? 0]);
    }

    const capSteps = [1.0, 0.92, 0.7, 0.38, 0.0]; // cos do ângulo da ponta
    if (capA) {
      for (final cs in capSteps.reversed) {
        if (cs == 1.0) continue;
        final sn = math.sqrt(1 - cs * cs);
        addRing(a - u * (radius(0) * sn * 0.85), 0, cs, 0);
      }
    }
    for (final s in sList) {
      addRing(a + axis * s, s, 1, s);
    }
    if (capB) {
      for (final cs in capSteps) {
        if (cs == 1.0) continue;
        final sn = math.sqrt(1 - cs * cs);
        addRing(b + u * (radius(1) * sn * 0.85), 1, cs, 1);
      }
    }
    m.rings(rings, centers, color: (i, j) => cols[i][j], muscle: (i, j) => mus[i][j], gloss: gloss);
  }

  void _arm(Mesh m, int sh, int elb, int hand, bool hl, int sides) {
    final s3 = _j(sh), e3 = _j(elb), h3 = _j(hand);
    final upper = e3 - s3, fore = h3 - e3;
    var anterior = perpTo(fore, upper);
    if (anterior.length < 2) anterior = _torsoFront;
    anterior = anterior.unit;
    final skin = _b.skin;
    final male = _b.male;
    final biceps = hl ? _mw('biceps') : 0.0;
    final triceps = hl ? _mw('triceps') : 0.0;
    final ombros = hl ? _mw('ombros') : 0.0;
    final ante = hl ? _mw('antebraco') : 0.0;
    final ur = _b.upperArm;
    _limb(
      m,
      s3,
      e3,
      anterior,
      [ur[0] * 1.18, ur[1], ur[2]],
      sides: sides,
      breaks: male ? const [0.42] : const [],
      bulges: const [_Bulge(0.25, 0.85, 0, 0.16), _Bulge(0.15, 0.8, math.pi, 0.12)],
      color: (s, _) => male && s < 0.42 ? _b.top : skin,
      muscle: (s, ang) {
        final c = math.cos(ang);
        var v = 0.0;
        if (biceps > 0 && c > 0.25 && s > 0.2) v = math.max(v, biceps);
        if (triceps > 0 && c < -0.25 && s > 0.12) v = math.max(v, triceps);
        if (ombros > 0 && s < 0.3) v = math.max(v, ombros * (1 - s / 0.3 * 0.5));
        return v;
      },
    );
    final fr = _b.foreArm;
    _limb(
      m,
      e3,
      h3,
      anterior,
      fr,
      sides: sides,
      flatten: 0.86,
      bulges: const [_Bulge(0.0, 0.55, 0, 0.12)],
      color: (_, _) => skin,
      muscle: ante > 0 ? (s, _) => s < 0.85 ? ante : 0 : null,
    );
    // mão: elipsoide apontando na direção do antebraço
    final fd = fore.length < 1e-3 ? const V3(0, -1, 0) : fore.unit;
    var palm = perpTo(anterior, fd);
    palm = palm.length < 1e-3 ? perpendicular(fd) : palm.unit;
    final side = fd.cross(palm).unit;
    m.ellipsoid(h3 + fd * 1.7, fd, side, palm, male ? 2.9 : 2.6, male ? 2.1 : 1.85, male ? 1.35 : 1.2,
        color: (_) => skin, lat: 6, lon: 10, gloss: 0.05);
  }

  void _leg(Mesh m, int hip, int knee, int ank, int toe, bool hl, int sides) {
    final h3 = _j(hip), k3 = _j(knee), a3 = _j(ank), t3 = _j(toe);
    final thigh = k3 - h3, shin = a3 - k3;
    var anterior = perpTo(-shin, thigh);
    if (anterior.length < 2) anterior = _torsoFront;
    anterior = anterior.unit;
    var calfSide = perpTo(h3 - k3, shin);
    if (calfSide.length < 2) calfSide = -_torsoFront;
    calfSide = calfSide.unit;
    // de que lado fica o lado de fora da coxa
    final outward = perpTo(h3 - _j(Jt.hip), thigh);
    final male = _b.male;
    final quad = hl ? _mw('quadriceps') : 0.0;
    final post = hl ? _mw('posterior') : 0.0;
    final adut = hl ? _mw('adutores') : 0.0;
    final abdu = hl ? _mw('abdutores') : 0.0;
    final pant = hl ? _mw('panturrilha') : 0.0;
    // ângulo do lado de fora na seção (frente = 0)
    final thighAxis = thigh.unit;
    final v = anterior;
    final w = thighAxis.cross(v).unit;
    final outAng = outward.length < 1e-3 ? math.pi / 2 : math.atan2(outward.dot(w), outward.dot(v));
    final tr = _b.thigh;
    final shorts = male;
    _limb(
      m,
      h3,
      k3,
      anterior,
      shorts ? [tr[0] * 1.08, tr[1] * 1.08, tr[2]] : tr,
      sides: sides,
      breaks: shorts ? const [0.72] : const [],
      bulges: const [_Bulge(0.15, 0.8, 0, 0.09), _Bulge(0.1, 0.75, math.pi, 0.07)],
      capA: true,
      color: (s, _) => male ? (s < 0.72 ? _b.bottom : _b.skin) : _b.bottom,
      muscle: (s, ang) {
        final c = math.cos(ang);
        final o = math.cos(ang - outAng);
        var x = 0.0;
        if (quad > 0 && c > 0.2) x = math.max(x, quad);
        if (post > 0 && c < -0.2) x = math.max(x, post);
        if (adut > 0 && o < -0.35 && s < 0.75) x = math.max(x, adut);
        if (abdu > 0 && o > 0.35 && s < 0.4) x = math.max(x, abdu);
        return s > 0.95 ? 0 : x;
      },
    );
    final cr = _b.calf;
    // ângulo da panturrilha (para trás da canela)
    final shinAxis = shin.unit;
    final sv = perpTo(-calfSide, shinAxis).unit;
    _limb(
      m,
      k3,
      a3,
      sv,
      cr,
      sides: sides,
      breaks: male ? const [0.86] : const [],
      bulges: const [_Bulge(0.08, 0.6, math.pi, 0.32), _Bulge(0.0, 0.25, 0, 0.05)],
      color: (s, _) => male ? (s > 0.86 ? _sock : _b.skin) : _b.bottom,
      muscle: pant > 0 ? (s, ang) => math.cos(ang) < -0.15 && s > 0.08 && s < 0.7 ? pant : 0 : null,
    );
    _shoe(m, k3, a3, t3, sides);
  }

  void _shoe(Mesh m, V3 knee, V3 ank, V3 toe, int sides) {
    var fd = toe - ank;
    if (fd.length < 1e-3) fd = const V3(1, 0, 0);
    final footLen = fd.length;
    fd = fd.unit;
    var up = perpTo(knee - ank, fd);
    up = up.length < 1e-3 ? const V3(0, 1, 0) : up.unit;
    final side = fd.cross(up).unit;
    final heel = ank - fd * 2.6 - up * 1.0;
    final tip = ank + fd * (math.max(footLen, 6) + 1.2) - up * 1.6;
    final n = math.max(10, sides);
    const steps = 8;
    final rings = <List<V3>>[];
    final centers = <V3>[];
    final cols = <List<Color>>[];
    // seção: largura, altura acima do eixo e abaixo do eixo
    (double, double, double) sect(double s) {
      final wdt = 2.4 + 0.8 * math.sin(math.pi * math.min(1, s * 1.15));
      final top = 2.9 - 1.9 * _smooth(s);
      return (wdt, top, 1.4);
    }

    void ring(double s, double scale, V3 center) {
      final (wdt, top, bot) = sect(s);
      final pts = <V3>[];
      final cl = <Color>[];
      for (var j = 0; j < n; j++) {
        final ang = 2 * math.pi * j / n;
        final cs = math.cos(ang), sn = math.sin(ang);
        final y = sn >= 0 ? _sgnPow(sn, 0.8) * top : _sgnPow(sn, 0.6) * bot;
        pts.add(center + side * (_sgnPow(cs, 0.75) * wdt * scale) + up * (y * scale));
        final isSole = sn < -0.55;
        final stripe = !isSole && cs.abs() > 0.75 && s > 0.3 && s < 0.62;
        cl.add(isSole ? _sole : (stripe ? _shoeAccent : _shoeColor));
      }
      rings.add(pts);
      centers.add(center);
      cols.add(cl);
    }

    final axis = tip - heel;
    for (final cs in const [0.0, 0.5, 0.85]) {
      ring(0, math.max(cs, 0.0), heel - fd * (1.6 * math.sqrt(1 - cs * cs)));
    }
    for (var i = 0; i <= steps; i++) {
      final s = i / steps;
      ring(s, 1, heel + axis * s);
    }
    for (final cs in const [0.8, 0.45, 0.0]) {
      ring(1, cs, tip + fd * (2.0 * math.sqrt(1 - cs * cs)));
    }
    m.rings(rings, centers, color: (i, j) => cols[i][j], gloss: 0.12);
  }

  // ------------------------------------------------------------ tronco

  (double, double, double) _section(double t) {
    final rows = _b.torso;
    if (t <= rows.first[0]) return (rows.first[1], rows.first[2], rows.first[3]);
    if (t >= rows.last[0]) return (rows.last[1], rows.last[2], rows.last[3]);
    for (var i = 0; i < rows.length - 1; i++) {
      final r0 = rows[i], r1 = rows[i + 1];
      if (t >= r0[0] && t <= r1[0]) {
        final k = (1 - math.cos(math.pi * (t - r0[0]) / (r1[0] - r0[0]))) / 2;
        double l(int c) => r0[c] + (r1[c] - r0[c]) * k;
        return (l(1), l(2), l(3));
      }
    }
    return (rows.last[1], rows.last[2], rows.last[3]);
  }

  void _torso(Mesh m, bool hl, int n) {
    final hip = _j(Jt.hip), neck = _j(Jt.neck);
    final up = _torsoUp, front = _torsoFront;
    final lat = up.cross(front).unit;
    final len = (neck - hip).length;
    final male = _b.male;
    // faixas de roupa (posição ao longo do tronco)
    final breaks = male ? const [0.30, 0.34] : const [0.37, 0.40, 0.47, 0.50];
    Color colorAt(double t) {
      if (male) {
        if (t < 0.30) return _b.bottom;
        if (t < 0.34) return _shade(_b.bottom, 0.35);
        return _b.top;
      }
      if (t < 0.37) return _b.bottom;
      if (t < 0.40) return _shade(_b.bottom, 0.35);
      if (t < 0.47) return _b.skin;
      if (t < 0.50) return _shade(_b.top, 0.25);
      return _b.top;
    }

    final peito = hl ? _mw('peito') : 0.0;
    final abd = hl ? _mw('abdomen') : 0.0;
    final costas = hl ? _mw('costas') : 0.0;
    final lombar = hl ? _mw('lombar') : 0.0;
    final trap = hl ? _mw('trapezio') : 0.0;
    final glut = hl ? _mw('gluteos') : 0.0;
    final abdu = hl ? _mw('abdutores') : 0.0;
    double muscleAt(double t, double c, double s) {
      var x = 0.0;
      if (peito > 0 && s > 0.3 && t > 0.6 && t < 0.95 && c.abs() < 0.85) x = math.max(x, peito);
      if (abd > 0 && s > 0.45 && t > 0.08 && t < 0.58 && c.abs() < 0.5) x = math.max(x, abd);
      if (abd > 0 && s > 0.0 && t > 0.15 && t < 0.5 && c.abs() >= 0.5) x = math.max(x, abd * 0.6);
      if (costas > 0 && s < -0.05 && t > 0.45 && t < 0.92) x = math.max(x, costas);
      if (lombar > 0 && s < -0.4 && t > 0.08 && t < 0.45 && c.abs() < 0.6) x = math.max(x, lombar);
      if (trap > 0 && t > 0.82 && s < 0.35 && c.abs() < 0.8) x = math.max(x, trap);
      if (glut > 0 && s < -0.15 && t < 0.16) x = math.max(x, glut);
      if (abdu > 0 && c.abs() > 0.75 && t > -0.12 && t < 0.18) x = math.max(x, abdu);
      return x;
    }

    final t0 = _b.torso.first[0];
    final ts = <double>{for (var i = 0; i <= 16; i++) t0 + (1 - t0) * i / 16};
    for (final br in breaks) {
      ts
        ..add(br - 0.003)
        ..add(br + 0.003);
    }
    final tList = ts.toList()..sort();

    final rings = <List<V3>>[];
    final centers = <V3>[];
    final cols = <List<Color>>[];
    final mus = <List<double>>[];
    final angs = [for (var j = 0; j < n; j++) 2 * math.pi * j / n];

    void ring(double t, double scale, double tColor, {double lift = 0}) {
      final (a, bf, bb) = _section(t);
      final center = hip + up * (t * len + lift);
      rings.add([
        for (final ang in angs)
          center +
              lat * (_sgnPow(math.cos(ang), 0.85) * a * scale) +
              front * (_sgnPow(math.sin(ang), 0.85) * (math.sin(ang) >= 0 ? bf : bb) * scale),
      ]);
      centers.add(center);
      cols.add([for (final _ in angs) colorAt(tColor)]);
      mus.add([for (final ang in angs) muscleAt(tColor, math.cos(ang), math.sin(ang))]);
    }

    // fecha embaixo (entre as pernas) e em cima (ombros)
    ring(t0, 0.0, t0, lift: -3.2);
    ring(t0, 0.45, t0, lift: -2.6);
    ring(t0, 0.82, t0, lift: -1.2);
    for (final t in tList) {
      ring(t, 1, t);
    }
    ring(1.0, 0.8, 1.0, lift: 1.2);
    ring(1.0, 0.45, 1.0, lift: 1.9);
    ring(1.0, 0.0, 1.0, lift: 2.1);
    m.rings(rings, centers, color: (i, j) => cols[i][j], muscle: (i, j) => mus[i][j], gloss: 0.06);
  }

  // ------------------------------------------------------------ cabeça

  void _neckAndHead(Mesh m, int detail) {
    final neck = _j(Jt.neck), head = _j(Jt.head);
    final up = _vec(Jt.headUp);
    final face = perpTo(_vec(Jt.headFace), up).unit;
    final side = up.cross(face).unit;
    final male = _b.male;
    final skin = _b.skin;
    final nr = male ? 3.1 : 2.6;
    _limb(m, neck - _torsoUp * 1.5, neck + (head - neck) * 0.6, face, [nr, nr * 0.95, nr * 0.9],
        sides: detail == 0 ? 8 : 10, steps: 3, capA: false, capB: false, color: (_, _) => skin);

    // cabeça um pouco mais alta que larga; a nuca fica atrás do pescoço
    final rUp = male ? 7.3 : 7.1, rFace = male ? 6.6 : 6.4, rSide = male ? 6.0 : 5.7;
    final hc = head + face * 0.2;
    final hair = _b.hair;
    final backLimit = male ? -0.35 : -0.72;
    bool isHair(V3 l) {
      // l: (ao longo de up, de face, de side) no espaço local da elipsoide
      final uu = -l.x, fu = l.y; // ellipsoid local: x ao longo de ax (= -up), y ao longo de face
      final thr = fu >= 0 ? 0.18 + 0.42 * fu : 0.18 + (backLimit - 0.18) * (-fu);
      return uu > thr;
    }

    m.ellipsoid(hc, -up, face, side, rUp, rFace, rSide,
        color: (l) => isHair(l) ? hair : skin, lat: detail == 0 ? 8 : 12, lon: detail == 0 ? 12 : 18, gloss: 0.06);

    // ponto na superfície da cabeça numa direção (em coordenadas up/face/side)
    V3 surface(double du, double df, double ds, [double push = 0]) {
      final d = (up * du + face * df + side * ds).unit;
      final k = 1 /
          math.sqrt(math.pow(d.dot(up) / rUp, 2) + math.pow(d.dot(face) / rFace, 2) + math.pow(d.dot(side) / rSide, 2));
      return hc + d * (k + push);
    }

    // queixo e mandíbula: dá forma ao rosto
    m.ellipsoid(surface(-0.62, 0.55, 0, -2.4), up, face, side, 3.0, 3.2, male ? 4.4 : 3.9,
        color: (_) => skin, lat: 6, lon: 10);
    if (!male) {
      // rabo de cavalo
      final tie = surface(0.35, -0.9, 0, -0.4);
      final end = tie - face * 3.0 - up * 7.0;
      final mid = V3.lerp(tie, end, 0.5) - face * 1.2;
      _limb(m, tie, mid, face, [2.6, 2.7, 2.4], sides: 9, steps: 3, color: (_, _) => hair);
      _limb(m, mid, end, face, [2.4, 2.2, 1.1], sides: 9, steps: 3, color: (_, _) => hair);
      m.ellipsoid(tie, up, face, side, 1.2, 1.2, 1.6, color: (_) => _b.top, lat: 4, lon: 8);
    }
    if (detail == 0) return;
    // orelhas
    for (final sg in const [1.0, -1.0]) {
      m.ellipsoid(surface(0.0, -0.05, sg, -0.35), up, face, side, 1.9, 1.2, 0.7,
          color: (_) => _shade(skin, 0.08), lat: 5, lon: 8);
    }
    // nariz
    m.ellipsoid(surface(-0.12, 1, 0, -0.1), up, face, side, 1.5, 1.1, 0.95, color: (_) => skin, lat: 5, lon: 8);
    // olhos e sobrancelhas
    for (final sg in const [1.0, -1.0]) {
      final e = surface(0.12, 0.93, sg * 0.4, -0.25);
      m.ellipsoid(e, up, face, side, 0.75, 0.45, 1.0, color: (_) => _eyeWhite, lat: 4, lon: 8);
      m.ellipsoid(e + face * 0.3, up, face, side, 0.6, 0.35, 0.6, color: (_) => _eye, lat: 4, lon: 8);
      final br = surface(0.34, 0.9, sg * 0.42, -0.05);
      m.ellipsoid(br, up, face, side, 0.32, 0.35, 1.15, color: (_) => _shade(hair, 0.1), lat: 4, lon: 8);
    }
    // boca
    m.ellipsoid(surface(-0.42, 0.92, 0, -0.15), up, face, side, 0.38, 0.35, 1.25,
        color: (_) => _lips, lat: 4, lon: 8);
  }

  // ------------------------------------------------------------ equipamentos móveis

  void _props(Mesh m) {
    for (final pr in clip.props) {
      if (pr.track.isEmpty) continue;
      final a3 = _t3(pr.track[0]);
      switch (pr.type) {
        case 'barbell':
          {
            const lat = V3(0, 0, 1);
            m.cylinder(a3 - lat * 38, a3 + lat * 38, 0.75, _chrome, sides: 10, gloss: 0.5);
            for (final sg in const [1.0, -1.0]) {
              m.cylinder(a3 + lat * (25.5 * sg), a3 + lat * (38.5 * sg), 1.25, _chrome, sides: 10, gloss: 0.5);
              m.cylinder(a3 + lat * (25.0 * sg), a3 + lat * (26.2 * sg), 1.9, _chrome, sides: 10, gloss: 0.4);
              m.cylinder(a3 + lat * (27.2 * sg), a3 + lat * (30.4 * sg), 9.4, _plateRed,
                  cap: _shade(_plateRed, 0.08), sides: 26, gloss: 0.2);
              m.cylinder(a3 + lat * (26.6 * sg), a3 + lat * (31.0 * sg), 3.0, _shade(_chrome, 0.1), sides: 12);
            }
          }
        case 'dumbbell':
          {
            if (pr.track.length < 2) continue;
            final axis = (_t3(pr.track[1]) - a3).unit;
            m.cylinder(a3 - axis * 5.4, a3 + axis * 5.4, 0.75, _chrome, sides: 8, gloss: 0.5);
            for (final sg in const [-1.0, 1.0]) {
              m.cylinder(a3 + axis * (4.4 * sg), a3 + axis * (7.4 * sg), 3.5, _iron, sides: 6, flat: true, gloss: 0.25);
            }
          }
        case 'kettlebell':
          {
            if (pr.track.length < 2) continue;
            final elbow = _t3(pr.track[1]);
            final down = (a3 - elbow).unit;
            var side = perpTo(const V3(0, 0, 1), down);
            side = side.length < 1e-3 ? perpendicular(down) : side.unit;
            final front = down.cross(side).unit;
            final bell = a3 + down * 6.2;
            m.ellipsoid(bell, down, side, front, 4.6, 5.0, 5.0, color: (_) => _iron, lat: 8, lon: 14, gloss: 0.3);
            final hc = a3 + down * 1.2;
            m.tube([
              for (var i = 0; i <= 10; i++)
                hc + side * (math.cos(math.pi * i / 10) * 3.0) - down * (math.sin(math.pi * i / 10) * 1.6) +
                    down * (i == 0 || i == 10 ? 2.6 : 0),
            ], 0.75, _iron, gloss: 0.3);
          }
        case 'padcyl':
          {
            if (pr.track.length < 2) continue;
            final b3 = _t3(pr.track[1]);
            m.cylinder(a3, b3, pr.val('r', 4), palette.pad, cap: _shade(palette.pad, 0.15), sides: 14, gloss: 0.1);
          }
        case 'lever':
          {
            if (pr.track.length < 2) continue;
            final b3 = _t3(pr.track[1]);
            m.tube([a3, b3], 1.1, palette.equipmentDark, sides: 8, gloss: 0.2);
            m.ellipsoid(a3, const V3(0, 1, 0), const V3(1, 0, 0), const V3(0, 0, 1), 1.9, 1.9, 1.9,
                color: (_) => palette.equipment, lat: 5, lon: 8);
          }
        case 'quad':
          {
            if (pr.track.length < 4) continue;
            final q = [for (final i in pr.track) _t3(i)];
            m.panel(q[0], q[1], q[2], q[3], palette.equipmentDark);
          }
        case 'cable':
          {
            if (pr.track.length < 2) continue;
            final b3 = _t3(pr.track[1]);
            m.tube([a3, b3], 0.32, _cable, sides: 5);
            m.ellipsoid(b3, const V3(0, 1, 0), const V3(1, 0, 0), const V3(0, 0, 1), 1.2, 1.2, 1.2,
                color: (_) => _cable, lat: 4, lon: 6);
          }
        case 'grip':
          {
            if (pr.track.length < 2) continue;
            final b3 = _t3(pr.track[1]);
            final d = b3 - a3;
            final ext = d.length < 1e-3 ? V3.zero : d.unit * 4;
            m.tube([a3 - ext, b3 + ext], pr.val('r', 1.1), _iron, sides: 8, gloss: 0.3);
          }
        case 'band':
          {
            if (pr.track.length < 2) continue;
            m.tube([a3, _t3(pr.track[1])], 0.8, _band, sides: 6);
          }
        case 'rope':
          {
            if (pr.track.length < 3) continue;
            final b3 = _t3(pr.track[1]);
            final c3 = _t3(pr.track[2]);
            m.tube([
              for (var i = 0; i <= 10; i++)
                () {
                  final t = i / 10;
                  return a3 * ((1 - t) * (1 - t)) + c3 * (2 * t * (1 - t)) + b3 * (t * t);
                }(),
            ], 0.5, _cable, sides: 6);
          }
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
