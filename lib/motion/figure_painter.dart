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

/// Sulco fino em torno de [x0] (1 no centro, some a [w] de distância).
double _line(double x, double x0, double w) {
  final d = (x - x0) / w;
  return d.abs() >= 1 ? 0 : 1 - d * d * (3 - 2 * d.abs());
}

/// Direção [primary] perpendicular a [axis]; quando ela fica curta demais
/// (membro esticado, pé apontado), troca suavemente por [fallback], sem
/// saltos de um quadro para o outro.
V3 _stableDir(V3 primary, V3 fallback, V3 axis, double lo, double hi) {
  final p = perpTo(primary, axis);
  var f = perpTo(fallback, axis);
  if (f.length < 1e-4) f = perpendicular(axis.length < 1e-6 ? const V3(0, 1, 0) : axis.unit);
  f = f.unit;
  final len = p.length;
  if (len < 1e-6) return f;
  var pu = p * (1 / len);
  final w = _smooth((len - lo) / (hi - lo));
  if (w >= 1) return pu;
  // mantém o lado do reserva quando a principal está quase sumindo
  if (pu.dot(f) < 0 && w < 0.5) pu = -pu;
  final mix = pu * w + f * (1 - w);
  return mix.length < 1e-4 ? f : mix.unit;
}

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
    final detail = size.shortestSide < 120 ? 0 : 1;
    final m = Mesh();
    for (final p in clip.prims) {
      m.part = -2;
      _prim(m, p);
    }
    _body(m, highlight: style.showMuscles, detail: detail);
    m.part = 10;
    _props(m);
    m.occlude(_occluders(), floorY: kFloorY);

    _floor(canvas);
    m.drawShadow(canvas, _cam, kFloorY);

    if (ghost && style.showPath) {
      _f = clip.sample(0);
      final g = Mesh();
      _body(g, highlight: false, detail: 0);
      canvas.saveLayer(null, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.16));
      g.draw(canvas, _cam);
      canvas.restore();
      _f = clip.sample(time);
    }

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

  /// Partes que fazem sombra de ambiente umas nas outras.
  List<Occluder> _occluders() {
    final male = _b.male;
    final out = <Occluder>[
      Occluder.capsule(_j(Jt.hip) + _torsoUp * 2, _j(Jt.neck) - _torsoUp * 3, male ? 8.6 : 8.0, part: _pTorso, reach: 6, strength: 0.35),
      Occluder.capsule(_j(Jt.head), _j(Jt.head), 6.4, part: _pHead, reach: 5, strength: 0.4),
      Occluder.capsule(_j(Jt.shN), _j(Jt.elbN), 3.2, part: _pUpperArm, reach: 5, strength: 0.45),
      Occluder.capsule(_j(Jt.shF), _j(Jt.elbF), 3.2, part: _pUpperArm + 2, reach: 5, strength: 0.45),
      Occluder.capsule(_j(Jt.elbN), _j(Jt.handN), 2.5, part: _pUpperArm + 1, reach: 4, strength: 0.45),
      Occluder.capsule(_j(Jt.elbF), _j(Jt.handF), 2.5, part: _pUpperArm + 3, reach: 4, strength: 0.45),
      Occluder.capsule(_j(Jt.hipN), _j(Jt.kneeN), 5.4, part: _pThigh, reach: 6, strength: 0.45),
      Occluder.capsule(_j(Jt.hipF), _j(Jt.kneeF), 5.4, part: _pThigh + 2, reach: 6, strength: 0.45),
      Occluder.capsule(_j(Jt.kneeN), _j(Jt.ankN), 3.6, part: _pThigh + 1, reach: 5, strength: 0.45),
      Occluder.capsule(_j(Jt.kneeF), _j(Jt.ankF), 3.6, part: _pThigh + 3, reach: 5, strength: 0.45),
    ];
    for (final p in clip.prims) {
      if (p.kind == 'box' && p.opacity > 0.5) {
        var lo = const V3(1e9, 1e9, 1e9), hi = const V3(-1e9, -1e9, -1e9);
        for (final q in p.points) {
          lo = V3(math.min(lo.x, q.x), math.min(lo.y, q.y), math.min(lo.z, q.z));
          hi = V3(math.max(hi.x, q.x), math.max(hi.y, q.y), math.max(hi.z, q.z));
        }
        out.add(Occluder.box(lo, hi, strength: 0.4));
      } else if (p.kind == 'cyl') {
        out.add(Occluder.capsule(p.a, p.b, p.r, part: -2, reach: 4, strength: 0.45));
      }
    }
    return out;
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
    // ver Mesh.draw: 2 a 3 = principal, 1 a 2 = auxiliar
    if (style.primary.contains(g)) return 2.72 + 0.24 * _pulse;
    if (style.secondary.contains(g)) return 1.62;
    return 0;
  }

  /// Destaque [base] (de _mw) com intensidade [w] de 0 a 1, para bordas suaves.
  static double _mv(double base, double w) {
    if (base <= 0 || w <= 0.03) return 0;
    final f = base.floorToDouble();
    return f + (base - f) * w.clamp(0.0, 1.0);
  }

  /// 1 dentro de [a, b], caindo suavemente nas bordas (largura [e]).
  static double _soft(double x, double a, double b, [double e = 0.12]) =>
      _smooth((x - a) / e) * _smooth((b - x) / e);

  // ------------------------------------------------------------ corpo

  V3 get _torsoUp => (_j(Jt.neck) - _j(Jt.hip)).unit;

  V3 get _torsoFront {
    final f = perpTo(_vec(Jt.torsoFront), _torsoUp);
    return f.length < 1e-3 ? const V3(1, 0, 0) : f.unit;
  }

  // identificação das partes (para a sombra de ambiente)
  static const _pTorso = 0;
  static const _pHead = 1;
  static const _pUpperArm = 2; // +1 antebraço; +2/+3 o outro braço
  static const _pThigh = 6; // +1 canela; +2/+3 a outra perna

  void _body(Mesh m, {required bool highlight, required int detail}) {
    final sides = detail == 0 ? 9 : 24;
    final hl = highlight;
    m.part = _pTorso;
    _torso(m, hl, detail == 0 ? 12 : 36, detail);
    m.part = _pHead;
    _neckAndHead(m, detail);
    _arm(m, Jt.shN, Jt.elbN, Jt.handN, hl, sides, _pUpperArm, detail);
    _arm(m, Jt.shF, Jt.elbF, Jt.handF, hl, sides, _pUpperArm + 2, detail);
    _leg(m, Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN, hl, sides, _pThigh, detail);
    _leg(m, Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF, hl, sides, _pThigh + 2, detail);
  }

  /// Raio ao longo de um segmento a partir de (início, meio, fim).
  static double _radiusAt(List<double> r, double s) {
    if (s < 0.45) return r[0] + (r[1] - r[0]) * _smooth(s / 0.45);
    return r[1] + (r[2] - r[1]) * _smooth((s - 0.45) / 0.55);
  }

  /// Membro contínuo que passa por [pts] (ombro, cotovelo e mão, por
  /// exemplo). A articulação não tem emenda: os anéis giram suavemente de um
  /// segmento para o outro. Cada segmento tem seu perfil de raio, suas
  /// saliências musculares e suas faixas de cor.
  void _chain(
    Mesh m,
    List<V3> pts,
    V3 ref,
    List<List<double>> radii, {
    required Color Function(int seg, double s, double ang) color,
    double Function(int seg, double s, double ang)? muscle,
    double Function(int seg, double s, double ang)? groove,
    List<List<_Bulge>> bulges = const [],
    List<List<double>> breaks = const [],
    List<List<double>> extraS = const [],
    List<double> flatten = const [],
    List<int> parts = const [],
    int sides = 14,
    int steps = 8,
    bool capA = true,
    bool capB = true,
    double gloss = 0.05,
  }) {
    final segs = pts.length - 1;
    if (segs < 1) return;
    final axes = <V3>[];
    for (var k = 0; k < segs; k++) {
      final d = pts[k + 1] - pts[k];
      axes.add(d.length < 1e-4 ? (k > 0 ? axes[k - 1] : const V3(0, -1, 0)) : d.unit);
    }
    var v0 = perpTo(ref, axes[0]);
    v0 = v0.length < 1e-3 ? perpendicular(axes[0]) : v0.unit;
    final bn = axes[0].cross(v0).unit; // normal do plano em que o membro dobra

    (V3, V3) frame(V3 u) {
      var v = perpTo(bn.cross(u), u);
      v = v.length < 1e-4 ? perpendicular(u) : v.unit;
      return (v, u.cross(v).unit);
    }

    double bulge(int seg, double s, double ang) {
      var k = 1.0;
      if (seg < bulges.length) {
        for (final bl in bulges[seg]) {
          final c = math.cos(ang - bl.angle);
          if (c > 0) k += bl.amount * _window(s, bl.s0, bl.s1) * c * c;
        }
      }
      return k;
    }

    double flat(int seg) => seg < flatten.length ? flatten[seg] : 1.0;
    int partOf(int seg) => seg < parts.length ? parts[seg] : m.part;

    final rings = <List<V3>>[];
    final centers = <V3>[];
    final cols = <List<Color>>[];
    final mus = <List<double>>[];
    final grs = <List<double>>[];
    final ringParts = <int>[];
    final angs = [for (var j = 0; j < sides; j++) 2 * math.pi * j / sides];

    void addRing(V3 center, V3 u, int seg, double s, double rScale, {double? radius, bool joint = false}) {
      final (v, w) = frame(u);
      final r = (radius ?? _radiusAt(radii[seg], s)) * rScale;
      final fl = joint && seg + 1 < segs ? (flat(seg) + flat(seg + 1)) / 2 : flat(seg);
      rings.add([
        for (final ang in angs)
          () {
            final bg = joint ? 1.0 : bulge(seg, s, ang);
            return center + v * (math.cos(ang) * r * bg) + w * (math.sin(ang) * r * fl * bg);
          }(),
      ]);
      centers.add(center);
      cols.add([for (final ang in angs) color(seg, s, ang)]);
      mus.add([for (final ang in angs) joint ? 0.0 : (muscle?.call(seg, s, ang) ?? 0)]);
      grs.add([for (final ang in angs) joint ? 0.0 : (groove?.call(seg, s, ang) ?? 0)]);
      ringParts.add(partOf(seg));
    }

    const capSteps = [0.92, 0.7, 0.38, 0.0]; // cos do ângulo da ponta arredondada
    if (capA) {
      final r0 = _radiusAt(radii[0], 0);
      for (final cs in capSteps.reversed) {
        final sn = math.sqrt(1 - cs * cs);
        addRing(pts[0] - axes[0] * (r0 * sn * 0.85), axes[0], 0, 0, cs);
      }
    }
    for (var k = 0; k < segs; k++) {
      final ss = <double>{for (var i = 0; i <= steps; i++) i / steps};
      if (k < extraS.length) ss.addAll(extraS[k]);
      if (k < breaks.length) {
        for (final br in breaks[k]) {
          ss
            ..add((br - 0.002).clamp(0.0, 1.0))
            ..add((br + 0.002).clamp(0.0, 1.0));
        }
      }
      final list = ss.toList()..sort();
      for (final s in list) {
        if (k > 0 && s < 0.13) continue;
        if (k < segs - 1 && s > 0.87) continue;
        addRing(pts[k] + (pts[k + 1] - pts[k]) * s, axes[k], k, s, 1);
      }
      if (k < segs - 1) {
        // anel da articulação: eixo na bissetriz, um pouco mais largo quando dobra
        final u = (axes[k] + axes[k + 1]);
        final mid = u.length < 1e-3 ? axes[k] : u.unit;
        final cosHalf = mid.dot(axes[k]).clamp(0.5, 1.0);
        final r = (_radiusAt(radii[k], 1) + _radiusAt(radii[k + 1], 0)) / 2;
        addRing(pts[k + 1], mid, k, 1, math.min(1.25, 1 / cosHalf), radius: r, joint: true);
      }
    }
    if (capB) {
      final last = segs - 1;
      final r1 = _radiusAt(radii[last], 1);
      for (final cs in capSteps) {
        final sn = math.sqrt(1 - cs * cs);
        addRing(pts[segs] + axes[last] * (r1 * sn * 0.85), axes[last], last, 1, cs);
      }
    }
    m.rings(rings, centers,
        color: (i, j) => cols[i][j],
        muscle: (i, j) => mus[i][j],
        groove: groove == null ? null : (i, j) => grs[i][j],
        gloss: gloss,
        partOf: (i) => ringParts[i]);
  }

  /// Segmento único (pescoço, rabo de cavalo).
  void _limb(
    Mesh m,
    V3 a,
    V3 b,
    V3 ref,
    List<double> r, {
    required Color Function(double s, double ang) color,
    int sides = 12,
    int steps = 6,
    bool capA = true,
    bool capB = true,
  }) {
    _chain(m, [a, b], ref, [r],
        color: (_, s, ang) => color(s, ang), sides: sides, steps: steps, capA: capA, capB: capB);
  }

  void _arm(Mesh m, int sh, int elb, int hand, bool hl, int sides, int part, int detail) {
    final s3 = _j(sh), e3 = _j(elb), h3 = _j(hand);
    final upper = e3 - s3, fore = h3 - e3;
    // frente do braço: para onde o cotovelo dobra; com o braço esticado, a
    // frente do tronco (troca suave, sem o braço girar de repente)
    final anterior = _stableDir(fore, _torsoFront, upper, 1.0, 4.0);
    final skin = _b.skin;
    final male = _b.male;
    final biceps = hl ? _mw('biceps') : 0.0;
    final triceps = hl ? _mw('triceps') : 0.0;
    final ombros = hl ? _mw('ombros') : 0.0;
    final ante = hl ? _mw('antebraco') : 0.0;
    final ur = _b.upperArm;
    final sleeve = _shade(_b.top, 0.18);
    // músculo trabalhado fica um pouco mais cheio (efeito "pump")
    double pump(double w) => w >= 2 ? 1.0 : (w >= 1 ? 0.5 : 0.0);
    final pb = pump(biceps), pt = pump(triceps), po = pump(ombros), pa = pump(ante);
    final fine = detail > 0;
    _chain(
      m,
      [s3, e3, h3],
      anterior,
      [
        [ur[0] * (1.18 + 0.06 * po), ur[1], ur[2]],
        _b.foreArm,
      ],
      sides: sides,
      steps: fine ? 12 : 8,
      parts: [part, part + 1],
      flatten: const [1.0, 0.86],
      breaks: male ? const [[0.39, 0.43]] : const [],
      extraS: fine
          ? const [
              [0.30, 0.34, 0.62],
              [0.3, 0.55],
            ]
          : const [],
      bulges: [
        [
          _Bulge(0.25, 0.85, 0, 0.16 + 0.10 * pb),
          _Bulge(0.15, 0.8, math.pi, 0.12 + 0.09 * pt),
          _Bulge(0.0, 0.34, math.pi / 2, 0.06 + 0.07 * po),
          _Bulge(0.0, 0.3, -math.pi / 2, 0.03 + 0.05 * po),
        ],
        [_Bulge(0.0, 0.55, 0, 0.12 + 0.07 * pa), _Bulge(0.0, 0.45, math.pi, 0.05 + 0.04 * pa)],
      ],
      groove: !fine
          ? null
          : (seg, s, ang) {
              final c = math.cos(ang), sn = math.sin(ang);
              var g = 0.0;
              if (seg == 0) {
                if (ombros > 0) {
                  // cabeças do deltoide e a borda de baixo dele
                  g = math.max(g, _line(s, 0.32, 0.05) * _smooth((c + 0.9) / 0.4));
                  if (s < 0.32) g = math.max(g, _line(sn.abs(), 0.86, 0.12) * _smooth(c / 0.3) * 0.8);
                }
                if (biceps > 0 || triceps > 0) {
                  // separação entre bíceps e tríceps, dos dois lados
                  if (s > 0.3 && s < 0.92) g = math.max(g, _line(c, 0, 0.2) * _soft(s, 0.32, 0.9, 0.08));
                }
                if (biceps > 0 && s > 0.55 && s < 0.95) {
                  g = math.max(g, _line(c, 0.95, 0.08) * 0.5 * _soft(s, 0.58, 0.92, 0.08));
                }
                if (triceps > 0) {
                  // "ferradura" do tríceps: cabeça lateral e tendão
                  g = math.max(g, _line(s, 0.62, 0.05) * _smooth((-c - 0.55) / 0.25));
                  if (s > 0.3 && s < 0.62) g = math.max(g, _line(c, -0.82, 0.12) * _soft(s, 0.3, 0.62, 0.06) * 0.8);
                }
              } else if (ante > 0) {
                g = math.max(g, _line(c, 0, 0.22) * _soft(s, 0.05, 0.55, 0.08) * 0.8);
              }
              return g;
            },
      color: (seg, s, _) {
        if (seg == 0 && male) {
          if (s < 0.39) return _b.top;
          if (s < 0.43) return sleeve;
        }
        return skin;
      },
      muscle: (seg, s, ang) {
        final c = math.cos(ang);
        var v = 0.0;
        if (seg == 0) {
          v = math.max(v, _mv(biceps, _smooth(c / 0.5) * _soft(s, 0.15, 1.1)));
          v = math.max(v, _mv(triceps, _smooth(-c / 0.5) * _soft(s, 0.08, 1.1)));
          v = math.max(v, _mv(ombros, _soft(s, -1, 0.32)));
        } else {
          v = _mv(ante, _soft(s, -1, 0.85));
        }
        return v;
      },
    );
    // mão fechada: palma e dedos dobrados para dentro
    final fd = fore.length < 1e-3 ? const V3(0, -1, 0) : fore.unit;
    var palm = perpTo(anterior, fd);
    palm = palm.length < 1e-3 ? perpendicular(fd) : palm.unit;
    final side = fd.cross(palm).unit;
    final k = male ? 1.0 : 0.9;
    final lat = detail == 0 ? 5 : 7, lon = detail == 0 ? 8 : 12;
    m.ellipsoid(h3 + fd * (1.3 * k), fd, side, palm, 1.9 * k, 2.0 * k, 1.15 * k,
        color: (_) => skin, lat: lat, lon: lon, gloss: 0.05);
    m.ellipsoid(h3 + fd * (2.9 * k) + palm * (0.55 * k), fd, side, palm, 1.35 * k, 1.85 * k, 1.25 * k,
        color: (_) => skin, lat: lat, lon: lon, gloss: 0.05);
    if (detail > 0) {
      // polegar do lado de dentro (voltado para o corpo)
      final inward = perpTo(_j(Jt.hip) - h3, fd);
      final ts = inward.dot(side) >= 0 ? side : -side;
      m.ellipsoid(h3 + fd * (1.9 * k) + ts * (1.7 * k) + palm * (0.7 * k), fd, ts, palm, 1.3 * k, 0.65 * k, 0.6 * k,
          color: (_) => skin, lat: 4, lon: 8);
    }
  }

  void _leg(Mesh m, int hip, int knee, int ank, int toe, bool hl, int sides, int part, int detail) {
    final h3 = _j(hip), k3 = _j(knee), a3 = _j(ank), t3 = _j(toe);
    final thigh = k3 - h3, shin = a3 - k3;
    // frente da coxa: para onde o joelho aponta; com a perna esticada, a
    // frente do tronco (troca suave, sem a perna girar de repente)
    final anterior = _stableDir(-shin, _torsoFront, thigh, 1.0, 4.0);
    final fine = detail > 0;
    final outward = perpTo(h3 - _j(Jt.hip), thigh);
    final male = _b.male;
    final quad = hl ? _mw('quadriceps') : 0.0;
    final post = hl ? _mw('posterior') : 0.0;
    final adut = hl ? _mw('adutores') : 0.0;
    final abdu = hl ? _mw('abdutores') : 0.0;
    final pant = hl ? _mw('panturrilha') : 0.0;
    final glut = hl ? _mw('gluteos') : 0.0;
    final ta = thigh.length < 1e-3 ? const V3(0, -1, 0) : thigh.unit;
    final w = ta.cross(anterior).unit;
    final outAng = outward.length < 1e-3 ? math.pi / 2 : math.atan2(outward.dot(w), outward.dot(anterior));
    final tr = _b.thigh;
    final hem = _shade(_b.bottom, 0.3);
    // faixa lateral do short/legging
    final stripe = male ? const Color(0xFFE9ECF1) : _shade(_b.top, -0.15);
    double pump(double w) => w >= 2 ? 1.0 : (w >= 1 ? 0.5 : 0.0);
    final pq = pump(quad), pp = pump(post), pc = pump(pant);
    _chain(
      m,
      [h3, k3, a3],
      anterior,
      [
        male ? [tr[0] * 1.08, tr[1] * 1.08, tr[2]] : tr,
        _b.calf,
      ],
      sides: sides,
      steps: fine ? 12 : 8,
      parts: [part, part + 1],
      extraS: fine
          ? const [
              [0.08, 0.8],
              [0.45, 0.5],
            ]
          : const [],
      groove: !fine
          ? null
          : (seg, s, ang) {
              final c = math.cos(ang);
              final o = math.cos(ang - outAng);
              var g = 0.0;
              if (seg == 0) {
                if (quad > 0) {
                  // reto femoral entre os vastos e a "gota" do vasto medial
                  if (s > 0.12 && s < 0.85) g = math.max(g, _line(math.sin(ang).abs(), 0.42, 0.14) * _smooth(c / 0.3));
                  g = math.max(g, _line(s, 0.8, 0.05) * _smooth((-o - 0.1) / 0.3) * _smooth(c / 0.2) * 0.9);
                }
                if (post > 0 && s > 0.15 && s < 0.85) g = math.max(g, _line(c, -1, 0.12) * _soft(s, 0.15, 0.85, 0.08));
                if (glut > 0) g = math.max(g, _line(s, 0.08, 0.05) * _smooth((-c - 0.2) / 0.4) * 0.8);
              } else if (pant > 0) {
                // duas cabeças do gastrocnêmio e onde viram tendão
                if (s < 0.47) g = math.max(g, _line(c, -1, 0.1) * _soft(s, 0.06, 0.47, 0.06));
                g = math.max(g, _line(s, 0.48, 0.05) * _smooth((-c - 0.2) / 0.4) * 0.9);
              }
              return g;
            },
      breaks: male
          ? const [
              [0.70, 0.74],
              [0.86],
            ]
          : const [
              [],
              [0.93],
            ],
      bulges: [
        [_Bulge(0.15, 0.8, 0, 0.09 + 0.07 * pq), _Bulge(0.1, 0.75, math.pi, 0.07 + 0.06 * pp)],
        [_Bulge(0.08, 0.6, math.pi, 0.30 + 0.12 * pc), _Bulge(0.0, 0.25, 0, 0.05)],
      ],
      color: (seg, s, ang) {
        final side = fine && math.cos(ang - outAng) > 0.965;
        if (seg == 0) {
          if (!male) return side ? stripe : _b.bottom;
          if (s < 0.70) return side ? stripe : _b.bottom;
          if (s < 0.74) return hem;
          return _b.skin;
        }
        if (!male && side && s < 0.93) return stripe;
        if (male) return s > 0.86 ? _sock : _b.skin;
        return s > 0.93 ? _b.skin : _b.bottom;
      },
      muscle: (seg, s, ang) {
        final c = math.cos(ang);
        if (seg == 1) return _mv(pant, _smooth((-c - 0.05) / 0.4) * _soft(s, 0.05, 0.72));
        final o = math.cos(ang - outAng);
        var x = 0.0;
        // perto do quadril o destaque some aos poucos, para casar com o tronco
        x = math.max(x, _mv(quad, _smooth(c / 0.45) * _soft(s, 0.1, 0.95, 0.12)));
        x = math.max(x, _mv(post, _smooth(-c / 0.45) * _soft(s, 0.12, 0.95, 0.12)));
        x = math.max(x, _mv(glut, _smooth(-c / 0.4) * _soft(s, -1, 0.2, 0.1)));
        x = math.max(x, _mv(adut, _smooth((-o - 0.2) / 0.4) * _soft(s, -1, 0.75)));
        x = math.max(x, _mv(abdu, _smooth((o - 0.2) / 0.4) * _soft(s, -1, 0.42)));
        return x;
      },
    );
    if (fine) {
      // patela: na frente do joelho, na bissetriz entre coxa e canela
      final shinFront = _stableDir(thigh, anterior, shin, 1.0, 4.0);
      var kf = anterior + shinFront;
      kf = kf.length < 1e-3 ? anterior : kf.unit;
      final ax = (thigh.unit + shin.unit).length < 1e-3 ? thigh.unit : (thigh.unit + shin.unit).unit;
      final kr = (_radiusAt(tr, 1) + _radiusAt(_b.calf, 0)) / 2;
      final kneeCol = male ? _b.skin : _b.bottom;
      m.part = part + 1;
      m.ellipsoid(k3 + kf * (kr * 0.78), ax, kf, ax.cross(kf).unit, 1.9, 1.1, 1.7,
          color: (_) => kneeCol, lat: 5, lon: 8, gloss: 0.05);
    }
    m.part = part + 1;
    _shoe(m, h3, k3, a3, t3, sides, anterior, fine);
  }

  void _shoe(Mesh m, V3 hip, V3 knee, V3 ank, V3 toe, int sides, V3 legFront, bool fine) {
    var fd = toe - ank;
    if (fd.length < 1e-3) fd = const V3(1, 0, 0);
    final footLen = fd.length;
    fd = fd.unit;
    // peito do pé: normalmente do lado do joelho. Com o pé apontado na mesma
    // linha da canela (quatro apoios, deitado de bruços), essa direção some e
    // o pé girava; aí vale a frente da canela.
    final shin = knee - ank;
    final shinFront = _stableDir(knee - hip, legFront, shin, 1.0, 4.0);
    final c = shin.length < 1e-3 ? 0.0 : shin.unit.dot(fd).abs();
    final w = _smooth((c - 0.8) / 0.15);
    var up = perpTo(shin, fd);
    up = up.length < 1e-3 ? perpTo(shinFront, fd) : up.unit;
    final alt = perpTo(shinFront, fd);
    if (alt.length > 1e-3) {
      final au = alt.unit;
      final mixed = up * (1 - w) + (up.dot(au) >= 0 || w > 0.5 ? au : -au) * w;
      if (mixed.length > 1e-3) up = mixed.unit;
    }
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
    if (!fine) return;
    // cadarço: três laços atravessando o peito do pé
    for (final s in const [0.22, 0.34, 0.46]) {
      final (wdt, top, _) = sect(s);
      final p = heel + axis * s + up * (top + 0.12);
      m.tube([p - side * (wdt * 0.42), p + up * 0.18, p + side * (wdt * 0.42)], 0.22, const Color(0xFFDADFE6), sides: 4);
    }
    // reforço do calcanhar na cor de destaque
    m.ellipsoid(heel - fd * 1.2 + up * 0.9, up, -fd, side, 1.3, 0.55, 1.5,
        color: (_) => _shoeAccent, lat: 4, lon: 8, gloss: 0.1);
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

  void _torso(Mesh m, bool hl, int n, int detail) {
    final hip = _j(Jt.hip), neck = _j(Jt.neck);
    final up = _torsoUp, front = _torsoFront;
    final lat = up.cross(front).unit;
    final len = (neck - hip).length;
    final male = _b.male;
    // faixas de roupa (posição ao longo do tronco)
    final breaks = male ? const [0.30, 0.34, 0.38] : const [0.37, 0.40, 0.47, 0.50];
    Color colorAt(double t) {
      if (male) {
        if (t < 0.30) return _b.bottom;
        if (t < 0.34) return _shade(_b.bottom, 0.35);
        if (t < 0.38) return _shade(_b.top, 0.12); // barra da camiseta
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
    // regiões com o formato dos músculos (c = lado, s = frente/costas, t = altura)
    double blob(double dc, double dt, double rc, double rt) => math.exp(-(dc * dc) / (rc * rc) - (dt * dt) / (rt * rt));
    double muscleAt(double t, double c, double s) {
      final ac = c.abs();
      final front = _smooth((s - 0.1) / 0.35), back = _smooth((-s - 0.1) / 0.35);
      var x = 0.0;
      // peitorais: dois volumes acima do abdome
      x = math.max(x, _mv(peito, front * blob(ac - 0.42, t - 0.78, 0.34, 0.14) * 1.4));
      // abdome: faixa central da frente, um pouco mais larga dos lados (oblíquos)
      x = math.max(x, _mv(abd, front * blob(c, t - 0.33, 0.5, 0.24) * 1.3));
      // dorsais: em V nas costas
      x = math.max(x, _mv(costas, back * blob(ac - 0.5 + (t - 0.7) * 0.6, t - 0.68, 0.32, 0.2) * 1.4));
      // lombar: perto da coluna, embaixo
      x = math.max(x, _mv(lombar, back * blob(c, t - 0.27, 0.42, 0.15) * 1.3));
      // trapézio: losango no alto das costas e em cima dos ombros
      x = math.max(x, _mv(trap, _smooth((0.45 - s) / 0.35) * blob(c, t - 0.95, 0.6, 0.13) * 1.3));
      // glúteos: dois volumes atrás do quadril
      x = math.max(x, _mv(glut, back * blob(ac - 0.42, t - 0.02, 0.42, 0.16) * 1.4));
      x = math.max(x, _mv(abdu, _smooth((ac - 0.55) / 0.3) * blob(0, t - 0.03, 1, 0.14) * 1.2));
      return x;
    }

    // músculo trabalhado fica um pouco mais cheio (efeito "pump")
    double pumpAt(double t, double c, double s) {
      final ac = c.abs();
      final front = _smooth((s - 0.1) / 0.35), back = _smooth((-s - 0.1) / 0.35);
      double k(double w) => w >= 2 ? 1.0 : (w >= 1 ? 0.5 : 0.0);
      var x = 0.0;
      x = math.max(x, k(peito) * front * blob(ac - 0.42, t - 0.76, 0.34, 0.13));
      x = math.max(x, k(abd) * 0.6 * front * blob(c, t - 0.33, 0.45, 0.2));
      x = math.max(x, k(costas) * back * blob(ac - 0.55, t - 0.66, 0.3, 0.18));
      x = math.max(x, k(glut) * back * blob(ac - 0.42, t - 0.02, 0.4, 0.15));
      x = math.max(x, k(trap) * _smooth((0.45 - s) / 0.35) * blob(c, t - 0.95, 0.5, 0.1));
      return x;
    }

    // sulcos entre os músculos em destaque (gomos do abdome, linha do peitoral,
    // coluna) e costuras da roupa
    final fine = detail > 0;
    const absRows = [0.24, 0.335, 0.43];
    const pecLine = 0.655;
    double grooveAt(double t, double c, double s) {
      final ac = c.abs();
      final front = _smooth((s - 0.2) / 0.3), back = _smooth((-s - 0.2) / 0.3);
      var g = 0.0;
      if (abd > 0) {
        final inAbs = front * _soft(ac, -1, 0.34, 0.08) * _soft(t, 0.17, 0.52, 0.04);
        g = math.max(g, _line(c, 0, 0.09) * inAbs);
        for (final r in absRows) {
          g = math.max(g, _line(t, r, 0.022) * inAbs * 0.9);
        }
        g = math.max(g, _line(ac, 0.36, 0.08) * front * _soft(t, 0.15, 0.55, 0.05) * 0.7);
      }
      if (peito > 0) {
        final edge = pecLine + 0.05 * ac;
        g = math.max(g, _line(t, edge, 0.025) * front * _soft(ac, -1, 0.82, 0.1));
        g = math.max(g, _line(c, 0, 0.08) * front * _soft(t, pecLine, 0.93, 0.03));
      }
      if (costas > 0 || lombar > 0 || trap > 0) {
        final lo = lombar > 0 ? 0.12 : 0.42, hi = trap > 0 || costas > 0 ? 0.97 : 0.5;
        g = math.max(g, _line(c, 0, 0.08) * back * _soft(t, lo, hi, 0.04));
      }
      if (costas > 0) {
        // borda de baixo das escápulas
        g = math.max(g, _line(t, 0.8 - 0.12 * ac, 0.025) * back * _soft(ac, 0.15, 0.62, 0.08) * 0.8);
      }
      if (glut > 0) {
        g = math.max(g, _line(c, 0, 0.09) * back * _soft(t, -1, 0.13, 0.04));
        g = math.max(g, _line(t, -0.1, 0.03) * back * _soft(ac, 0.12, 0.8, 0.08) * 0.8);
      }
      if (fine && g < 0.5) {
        // costura lateral da camiseta e do short
        g = math.max(g, _line(s, 0, 0.1) * 0.5 * (male || t > 0.5 || t < 0.37 ? 1 : 0));
      }
      return g;
    }

    final t0 = _b.torso.first[0];
    final steps = fine ? 40 : 22;
    final ts = <double>{for (var i = 0; i <= steps; i++) t0 + (1 - t0) * i / steps};
    for (final br in breaks) {
      ts
        ..add(br - 0.003)
        ..add(br + 0.003);
    }
    if (fine) {
      if (abd > 0) ts.addAll(absRows);
      if (peito > 0) ts.addAll(const [pecLine, pecLine + 0.02, pecLine + 0.04]);
      if (glut > 0) ts.add(-0.1);
    }
    final tList = ts.toList()..sort();

    final rings = <List<V3>>[];
    final centers = <V3>[];
    final cols = <List<Color>>[];
    final mus = <List<double>>[];
    final grs = <List<double>>[];
    final angs = [for (var j = 0; j < n; j++) 2 * math.pi * j / n];

    void ring(double t, double scale, double tColor, {double lift = 0}) {
      final (a, bf, bb) = _section(t);
      final center = hip + up * (t * len + lift);
      rings.add([
        for (final ang in angs)
          () {
            final c = math.cos(ang), sn = math.sin(ang);
            final k = scale * (1 + 0.06 * pumpAt(tColor, c, sn));
            return center + lat * (_sgnPow(c, 0.85) * a * k) + front * (_sgnPow(sn, 0.85) * (sn >= 0 ? bf : bb) * k);
          }(),
      ]);
      centers.add(center);
      cols.add([for (final _ in angs) colorAt(tColor)]);
      mus.add([for (final ang in angs) muscleAt(tColor, math.cos(ang), math.sin(ang))]);
      grs.add([for (final ang in angs) scale < 1 ? 0.0 : grooveAt(tColor, math.cos(ang), math.sin(ang))]);
    }

    /// Ponto na superfície do tronco (altura t, ângulo pelo cosseno c).
    V3 surfaceAt(double t, double c, double sn, [double push = 0]) {
      final (a, bf, bb) = _section(t);
      final center = hip + up * (t * len);
      final p = center + lat * (_sgnPow(c, 0.85) * a) + front * (_sgnPow(sn, 0.85) * (sn >= 0 ? bf : bb));
      final out = p - center;
      return out.length < 1e-6 ? p : p + out.unit * push;
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
    m.rings(rings, centers,
        color: (i, j) => cols[i][j], muscle: (i, j) => mus[i][j], groove: (i, j) => grs[i][j], gloss: 0.06);
    if (detail > 0) {
      // marca no peito (lado esquerdo)
      final lc = 0.42, ls = math.sqrt(1 - lc * lc);
      final logo = surfaceAt(male ? 0.8 : 0.83, lc, ls, 0.12);
      final ln = (logo - (hip + up * ((male ? 0.8 : 0.83) * len))).unit;
      m.ellipsoid(logo, up, ln, up.cross(ln).unit, 0.75, 0.18, 1.05,
          color: (_) => const Color(0xFFF2F4F7), lat: 4, lon: 8);
      m.ellipsoid(logo + ln * 0.08, up, ln, up.cross(ln).unit, 0.32, 0.18, 0.55,
          color: (_) => _shoeAccent, lat: 3, lon: 6);
      if (male) {
        // cordão do short
        for (final sg in const [1.0, -1.0]) {
          final a = surfaceAt(0.31, 0.12 * sg, 0.99, 0.15);
          m.tube([a, a - up * 1.6 + lat * (0.25 * sg) + front * 0.3, a - up * 3.0 + lat * (0.35 * sg) + front * 0.35], 0.22,
              const Color(0xFFE9ECF1),
              sides: 4);
        }
      } else {
        // umbigo
        final nb = surfaceAt(0.435, 0, 1, -0.1);
        m.ellipsoid(nb, up, front, lat, 0.45, 0.2, 0.3, color: (_) => _shade(_b.skin, 0.35), lat: 3, lon: 6);
      }
      // gola (camiseta) ou alças do top
      final base = neck + up * 0.6;
      final nr = male ? 3.9 : 3.4;
      m.tube([
        for (var i = 0; i <= 18; i++)
          base + lat * (math.cos(2 * math.pi * i / 18) * nr) + front * (math.sin(2 * math.pi * i / 18) * nr * 0.9) -
              up * (math.sin(2 * math.pi * i / 18) > 0 ? math.sin(2 * math.pi * i / 18) * 1.4 : 0),
      ], 0.55, _shade(_b.top, male ? 0.2 : 0.25), sides: 6);
    }
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
        color: (l) => isHair(l) ? hair : skin, lat: detail == 0 ? 8 : 14, lon: detail == 0 ? 12 : 20, gloss: 0.06);
    if (detail > 0) {
      // volume do cabelo por cima da cabeça
      final k = male ? 1.06 : 1.09;
      m.ellipsoid(hc + up * 0.25 - face * 0.15, -up, face, side, rUp * k, rFace * k, rSide * (k + 0.02),
          color: (_) => hair, lat: 14, lon: 20, gloss: 0.18, include: (l) {
        final uu = -l.x, fu = l.y;
        final thr = fu >= 0 ? 0.30 + 0.42 * fu : 0.30 + (backLimit - 0.12) * (-fu);
        return uu > thr;
      });
    }

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
      _chain(m, [tie, mid, end], face, const [
        [2.5, 2.8, 2.6],
        [2.6, 2.1, 0.9],
      ], sides: detail == 0 ? 8 : 12, steps: 4, color: (_, _, _) => hair, gloss: 0.15);
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
