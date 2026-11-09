import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'motion_clip.dart';

/// Malha de triângulos em 3D com cor por vértice. É montada a cada quadro e
/// desenhada com iluminação, ordenando os triângulos do fundo para a frente.
class Mesh {
  final List<double> _p = []; // x, y, z
  final List<double> _n = []; // normal
  final List<int> _c = []; // cor ARGB
  final List<double> _m = []; // destaque muscular (0 a 1)
  final List<double> _g = []; // brilho especular
  final List<int> _t = []; // índices dos triângulos
  final List<bool> _two = []; // triângulo visível dos dois lados
  final List<int> _part = []; // parte do corpo/aparelho de cada vértice
  final List<double> _ao = []; // oclusão de ambiente (1 = livre, 0 = escuro)

  /// Parte atual: os próximos vértices pertencem a ela (para a oclusão).
  int part = -1;

  int get vertexCount => _c.length;
  int get triangleCount => _two.length;

  int vertex(V3 p, V3 n, Color c, {double muscle = 0, double gloss = 0}) {
    _p..add(p.x)..add(p.y)..add(p.z);
    _n..add(n.x)..add(n.y)..add(n.z);
    _c.add(c.toARGB32());
    _m.add(muscle);
    _g.add(gloss);
    _part.add(part);
    _ao.add(1);
    return _c.length - 1;
  }

  void tri(int a, int b, int c, {bool twoSided = false}) {
    _t..add(a)..add(b)..add(c);
    _two.add(twoSided);
  }

  void quad(int a, int b, int c, int d, {bool twoSided = false}) {
    tri(a, b, c, twoSided: twoSided);
    tri(a, c, d, twoSided: twoSided);
  }

  /// Desenha a malha vista pela câmera [cam]. As coordenadas na tela são as
  /// mesmas de [Camera.project]; o canvas já deve estar escalado.
  ///
  /// O destaque muscular de cada vértice vale 0 (nenhum), de 1 a 2 (músculo
  /// auxiliar, cor [secondary] com intensidade m - 1) ou de 2 a 3 (músculo
  /// principal, cor [highlight] com intensidade m - 2).
  void draw(Canvas canvas, Camera cam,
      {Color highlight = const Color(0xFFFFB400), Color secondary = const Color(0xFFFFE27A)}) {
    final vc = vertexCount;
    if (vc == 0 || triangleCount == 0) return;
    if (vc > 65535) throw StateError('Malha grande demais: $vc vértices');
    final pos = Float32List(vc * 2);
    final cols = Int32List(vc);
    final depth = Float64List(vc);
    final facing = Float64List(vc);
    final tw = cam.toward, rt = cam.right, up = cam.up;
    // luz vinda de cima, da esquerda e da frente de quem vê
    final light = (tw * 0.55 + up * 0.75 - rt * 0.45).unit;
    final half = (light + tw).unit;
    final hr = (highlight.r * 255), hg = (highlight.g * 255), hb = (highlight.b * 255);
    final sr = (secondary.r * 255), sg = (secondary.g * 255), sb = (secondary.b * 255);
    for (var i = 0; i < vc; i++) {
      final x = _p[i * 3], y = _p[i * 3 + 1], z = _p[i * 3 + 2];
      pos[i * 2] = x * rt.x + y * rt.y + z * rt.z;
      pos[i * 2 + 1] = -(x * up.x + y * up.y + z * up.z);
      depth[i] = x * tw.x + y * tw.y + z * tw.z;
      final nx = _n[i * 3], ny = _n[i * 3 + 1], nz = _n[i * 3 + 2];
      final nt = nx * tw.x + ny * tw.y + nz * tw.z;
      facing[i] = nt;
      final diff = math.max(0.0, nx * light.x + ny * light.y + nz * light.z);
      final sky = 0.5 + 0.5 * ny; // luz do ambiente vem mais de cima
      final rim = math.pow(1 - nt.abs().clamp(0.0, 1.0), 3).toDouble();
      final ao = _ao[i];
      final lum = (0.34 + 0.16 * sky) * ao + 0.62 * diff * (0.55 + 0.45 * ao) + 0.10 * rim;
      final spec = _g[i] > 0
          ? _g[i] * math.pow(math.max(0.0, nx * half.x + ny * half.y + nz * half.z), 18).toDouble()
          : 0.0;
      final argb = _c[i];
      final a = (argb >> 24) & 0xFF;
      var r = ((argb >> 16) & 0xFF).toDouble(), g = ((argb >> 8) & 0xFF).toDouble(), b = (argb & 0xFF).toDouble();
      final m = _m[i];
      r *= lum;
      g *= lum;
      b *= lum;
      if (m >= 1) {
        // o destaque quase não escurece com a sombra, para aparecer sempre
        final hl = math.max(lum, 0.82);
        final primary = m >= 2;
        final k = primary ? m - 2 : m - 1;
        r += ((primary ? hr : sr) * hl - r) * k;
        g += ((primary ? hg : sg) * hl - g) * k;
        b += ((primary ? hb : sb) * hl - b) * k;
      }
      int ch(double v) => (v + 255 * spec).round().clamp(0, 255);
      cols[i] = (a << 24) | (ch(r) << 16) | (ch(g) << 8) | ch(b);
    }
    final tc = triangleCount;
    final keep = <int>[];
    final tdepth = Float64List(tc);
    for (var k = 0; k < tc; k++) {
      final a = _t[k * 3], b = _t[k * 3 + 1], c = _t[k * 3 + 2];
      if (!_two[k] && facing[a] < -0.02 && facing[b] < -0.02 && facing[c] < -0.02) continue;
      tdepth[k] = (depth[a] + depth[b] + depth[c]) / 3;
      keep.add(k);
    }
    keep.sort((x, y) => tdepth[x].compareTo(tdepth[y]));
    final idx = Uint16List(keep.length * 3);
    for (var i = 0; i < keep.length; i++) {
      final k = keep[i];
      idx[i * 3] = _t[k * 3];
      idx[i * 3 + 1] = _t[k * 3 + 1];
      idx[i * 3 + 2] = _t[k * 3 + 2];
    }
    canvas.drawVertices(
      Vertices.raw(VertexMode.triangles, pos, colors: cols, indices: idx),
      BlendMode.dst,
      Paint(),
    );
  }

  /// Escurece os vértices perto de outras partes (axilas, dobra do joelho,
  /// corpo apoiado no banco, pés no chão), como a luz real faz.
  void occlude(List<Occluder> occ, {double floorY = double.negativeInfinity}) {
    final vc = vertexCount;
    for (var i = 0; i < vc; i++) {
      final px = _p[i * 3], py = _p[i * 3 + 1], pz = _p[i * 3 + 2];
      final nx = _n[i * 3], ny = _n[i * 3 + 1], nz = _n[i * 3 + 2];
      final own = _part[i];
      var a = 1.0;
      for (final o in occ) {
        if (o.part == own && own >= 0) continue;
        final (qx, qy, qz) = o.closest(px, py, pz);
        var dx = qx - px, dy = qy - py, dz = qz - pz;
        final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
        final gap = dist - o.radius;
        if (gap >= o.reach) continue;
        if (dist > 1e-6) {
          dx /= dist;
          dy /= dist;
          dz /= dist;
        }
        final facing = nx * dx + ny * dy + nz * dz;
        if (facing <= 0) continue;
        final near = 1 - math.max(0.0, gap) / o.reach;
        a *= 1 - o.strength * facing * near * near;
      }
      if (floorY.isFinite) {
        final gap = py - floorY;
        if (gap < 8 && ny < 0.3) {
          final near = 1 - math.max(0.0, gap) / 8;
          a *= 1 - 0.35 * (0.3 - ny) / 1.3 * near * near;
        }
      }
      _ao[i] = a.clamp(0.45, 1.0);
    }
  }

  /// Sombra projetada no chão (luz vinda de cima, levemente inclinada).
  void drawShadow(Canvas canvas, Camera cam, double floorY, {Color color = const Color(0x2E000000)}) {
    final vc = vertexCount;
    if (vc == 0) return;
    const lx = 0.25, lz = 0.18; // direção da luz: (lx, -1, lz)
    final pos = Float32List(vc * 2);
    final rt = cam.right, up = cam.up;
    for (var i = 0; i < vc; i++) {
      var x = _p[i * 3], y = _p[i * 3 + 1], z = _p[i * 3 + 2];
      final h = math.max(0.0, y - floorY);
      x += lx * h;
      z += lz * h;
      y = floorY + 0.05;
      pos[i * 2] = x * rt.x + y * rt.y + z * rt.z;
      pos[i * 2 + 1] = -(x * up.x + y * up.y + z * up.z);
    }
    final idx = Uint16List.fromList(_t);
    canvas.saveLayer(
        null,
        Paint()
          ..color = color
          ..imageFilter = ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6));
    canvas.drawVertices(
      Vertices.raw(VertexMode.triangles, pos, indices: idx),
      BlendMode.src,
      Paint()..color = const Color(0xFF000000),
    );
    canvas.restore();
  }

  // ------------------------------------------------------------ formas

  /// Superfície em anéis (tubo, tronco, sapato). [rings] tem a mesma
  /// quantidade de pontos em cada anel; [centers] é o centro de cada anel e
  /// serve para orientar as normais para fora. Anéis com raio zero fecham as
  /// pontas.
  void rings(
    List<List<V3>> rings,
    List<V3> centers, {
    required Color Function(int ring, int j) color,
    double Function(int ring, int j)? muscle,
    double gloss = 0,
    int Function(int ring)? partOf,
  }) {
    final nr = rings.length;
    final keepPart = part;
    if (nr < 2) return;
    final n = rings.first.length;
    final base = vertexCount;
    for (var i = 0; i < nr; i++) {
      if (partOf != null) part = partOf(i);
      final prev = rings[i == 0 ? 0 : i - 1], next = rings[i == nr - 1 ? nr - 1 : i + 1];
      for (var j = 0; j < n; j++) {
        final p = rings[i][j];
        final dI = next[j] - prev[j];
        final dJ = rings[i][(j + 1) % n] - rings[i][(j - 1 + n) % n];
        var nrm = dI.cross(dJ);
        if (nrm.length < 1e-6) {
          // ponta do tubo: a normal aponta ao longo do eixo, para fora
          nrm = i == 0 ? centers[0] - centers[math.min(1, nr - 1)] : centers[nr - 1] - centers[nr - 2];
          if (nrm.length < 1e-6) nrm = p - centers[i];
        } else if (nrm.dot(p - centers[i]) < 0) {
          nrm = -nrm;
        }
        vertex(p, nrm.unit, color(i, j), muscle: muscle?.call(i, j) ?? 0, gloss: gloss);
      }
    }
    part = keepPart;
    for (var i = 0; i < nr - 1; i++) {
      for (var j = 0; j < n; j++) {
        final a = base + i * n + j, b = base + i * n + (j + 1) % n;
        final c = base + (i + 1) * n + (j + 1) % n, d = base + (i + 1) * n + j;
        quad(a, b, c, d);
      }
    }
  }

  /// Elipsoide com eixos [ax] (raio [r1]), [ay] ([r2]) e [az] ([r3]).
  void ellipsoid(
    V3 c,
    V3 ax,
    V3 ay,
    V3 az,
    double r1,
    double r2,
    double r3, {
    required Color Function(V3 dirLocal) color,
    double Function(V3 dirLocal)? muscle,
    int lat = 8,
    int lon = 12,
    double gloss = 0,
    bool Function(V3 dirLocal)? include,
  }) {
    final base = vertexCount;
    final inc = <bool>[];
    for (var i = 0; i <= lat; i++) {
      final th = math.pi * i / lat;
      final ct = math.cos(th), st = math.sin(th);
      for (var j = 0; j < lon; j++) {
        final ph = 2 * math.pi * j / lon;
        final l1 = -ct, l2 = st * math.cos(ph), l3 = st * math.sin(ph);
        final p = c + ax * (l1 * r1) + ay * (l2 * r2) + az * (l3 * r3);
        final nrm = (ax * (l1 / r1) + ay * (l2 / r2) + az * (l3 / r3)).unit;
        final local = V3(l1, l2, l3);
        vertex(p, nrm, color(local), muscle: muscle?.call(local) ?? 0, gloss: gloss);
        inc.add(include?.call(local) ?? true);
      }
    }
    for (var i = 0; i < lat; i++) {
      for (var j = 0; j < lon; j++) {
        final a = i * lon + j, b = i * lon + (j + 1) % lon;
        final cc = (i + 1) * lon + (j + 1) % lon, d = (i + 1) * lon + j;
        if (include != null && !(inc[a] && inc[b] && inc[cc] && inc[d])) continue;
        quad(base + a, base + b, base + cc, base + d);
      }
    }
  }

  /// Cilindro de [a] a [b] com tampas planas.
  void cylinder(V3 a, V3 b, double r, Color side, {Color? cap, int sides = 14, bool flat = false, double gloss = 0}) {
    final axis = b - a;
    if (axis.length < 1e-6) return;
    final u = axis.unit;
    final v = perpendicular(u);
    final w = u.cross(v).unit;
    V3 rad(double ang) => v * math.cos(ang) + w * math.sin(ang);
    final capCol = cap ?? side;
    // tampas
    for (final (center, nrm) in [(a, -u), (b, u)]) {
      final c0 = vertex(center, nrm, capCol, gloss: gloss);
      final ring = [for (var j = 0; j < sides; j++) vertex(center + rad(2 * math.pi * j / sides) * r, nrm, capCol)];
      for (var j = 0; j < sides; j++) {
        tri(c0, ring[j], ring[(j + 1) % sides]);
      }
    }
    // lateral
    if (flat) {
      for (var j = 0; j < sides; j++) {
        final a0 = 2 * math.pi * j / sides, a1 = 2 * math.pi * (j + 1) / sides;
        final nrm = rad((a0 + a1) / 2);
        final p0 = vertex(a + rad(a0) * r, nrm, side, gloss: gloss);
        final p1 = vertex(a + rad(a1) * r, nrm, side, gloss: gloss);
        final p2 = vertex(b + rad(a1) * r, nrm, side, gloss: gloss);
        final p3 = vertex(b + rad(a0) * r, nrm, side, gloss: gloss);
        quad(p0, p1, p2, p3);
      }
    } else {
      final base = vertexCount;
      for (var j = 0; j < sides; j++) {
        final d = rad(2 * math.pi * j / sides);
        vertex(a + d * r, d, side, gloss: gloss);
        vertex(b + d * r, d, side, gloss: gloss);
      }
      for (var j = 0; j < sides; j++) {
        final k = (j + 1) % sides;
        quad(base + j * 2, base + k * 2, base + k * 2 + 1, base + j * 2 + 1);
      }
    }
  }

  /// Tubo fino que segue uma linha (cabo, corda, elástico, alça).
  void tube(List<V3> pts, double r, Color color, {int sides = 7, double gloss = 0}) {
    if (pts.length < 2) return;
    final rings = <List<V3>>[];
    var ref = perpendicular((pts[1] - pts[0]).unit);
    for (var i = 0; i < pts.length; i++) {
      final t = (pts[math.min(i + 1, pts.length - 1)] - pts[math.max(i - 1, 0)]).unit;
      var v = ref - t * ref.dot(t);
      if (v.length < 1e-4) v = perpendicular(t);
      v = v.unit;
      ref = v;
      final w = t.cross(v).unit;
      rings.add([
        for (var j = 0; j < sides; j++)
          pts[i] + v * (math.cos(2 * math.pi * j / sides) * r) + w * (math.sin(2 * math.pi * j / sides) * r),
      ]);
    }
    this.rings(rings, pts, color: (_, _) => color, gloss: gloss);
  }

  /// Caixa a partir de uma face (polígono convexo) estendida por [ext]. As
  /// faces grandes são divididas em pedaços para a ordenação funcionar bem.
  void box(List<V3> face, V3 ext, Color color, {double cell = 7}) {
    if (face.length < 3) return;
    final back = [for (final p in face) p + ext];
    var center = V3.zero;
    for (final p in face) {
      center = center + p;
    }
    center = center * (1 / face.length) + ext * 0.5;
    void flatFace(List<V3> pts) {
      var fc = V3.zero;
      for (final p in pts) {
        fc = fc + p;
      }
      fc = fc * (1 / pts.length);
      var nrm = (pts[1] - pts[0]).cross(pts[2] - pts[0]);
      if (nrm.length < 1e-9) return;
      nrm = nrm.unit;
      if (nrm.dot(fc - center) < 0) nrm = -nrm;
      if (pts.length == 4) {
        _grid(pts[0], pts[1], pts[2], pts[3], nrm, color, cell);
      } else {
        final c0 = vertex(fc, nrm, color);
        final ids = [for (final p in pts) vertex(p, nrm, color)];
        for (var j = 0; j < ids.length; j++) {
          tri(c0, ids[j], ids[(j + 1) % ids.length]);
        }
      }
    }

    flatFace(face);
    flatFace(back);
    for (var i = 0; i < face.length; i++) {
      final j = (i + 1) % face.length;
      flatFace([face[i], face[j], back[j], back[i]]);
    }
  }

  /// Quadrilátero dividido em grade, com a mesma normal.
  void _grid(V3 p00, V3 p10, V3 p11, V3 p01, V3 nrm, Color color, double cell, {bool twoSided = false}) {
    final nu = math.max(1, math.min(24, ((p10 - p00).length / cell).ceil()));
    final nv = math.max(1, math.min(24, ((p01 - p00).length / cell).ceil()));
    final base = vertexCount;
    for (var i = 0; i <= nv; i++) {
      final s = i / nv;
      final l = V3.lerp(p00, p01, s), r = V3.lerp(p10, p11, s);
      for (var j = 0; j <= nu; j++) {
        vertex(V3.lerp(l, r, j / nu), nrm, color);
      }
    }
    for (var i = 0; i < nv; i++) {
      for (var j = 0; j < nu; j++) {
        final a = base + i * (nu + 1) + j;
        quad(a, a + 1, a + nu + 2, a + nu + 1, twoSided: twoSided);
      }
    }
  }

  /// Placa fina vista dos dois lados (plataforma).
  void panel(V3 p00, V3 p10, V3 p11, V3 p01, Color color) {
    final nrm = (p10 - p00).cross(p01 - p00).unit;
    _grid(p00, p10, p11, p01, nrm, color, 6, twoSided: true);
  }
}

/// Algo que faz sombra de ambiente: um segmento com raio (cápsula) ou uma
/// caixa alinhada aos eixos.
class Occluder {
  Occluder.capsule(V3 a, V3 b, this.radius, {required this.part, this.reach = 6, this.strength = 0.6})
      : _ax = a.x, _ay = a.y, _az = a.z, _bx = b.x, _by = b.y, _bz = b.z, _box = false;

  Occluder.box(V3 min, V3 max, {this.part = -2, this.reach = 5, this.strength = 0.5})
      : radius = 0, _ax = min.x, _ay = min.y, _az = min.z, _bx = max.x, _by = max.y, _bz = max.z, _box = true;

  final double radius;
  final int part;

  /// Distância (a partir da superfície) até onde a sombra chega.
  final double reach;
  final double strength;
  final double _ax, _ay, _az, _bx, _by, _bz;
  final bool _box;

  /// Ponto do eixo (ou da caixa) mais perto de (x, y, z).
  (double, double, double) closest(double x, double y, double z) {
    if (_box) {
      return (x.clamp(_ax, _bx), y.clamp(_ay, _by), z.clamp(_az, _bz));
    }
    final dx = _bx - _ax, dy = _by - _ay, dz = _bz - _az;
    final len2 = dx * dx + dy * dy + dz * dz;
    var t = len2 < 1e-9 ? 0.0 : ((x - _ax) * dx + (y - _ay) * dy + (z - _az) * dz) / len2;
    t = t.clamp(0.0, 1.0);
    return (_ax + dx * t, _ay + dy * t, _az + dz * t);
  }
}

/// Um vetor qualquer perpendicular a [u].
V3 perpendicular(V3 u) {
  final helper = u.y.abs() < 0.9 ? const V3(0, 1, 0) : const V3(1, 0, 0);
  return u.cross(helper).unit;
}

/// Parte de [v] perpendicular a [axis].
V3 perpTo(V3 v, V3 axis) {
  final a = axis.unit;
  return v - a * v.dot(a);
}
