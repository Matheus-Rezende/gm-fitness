import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Ponto ou direção em 3D. X = frente da pessoa, Y = para cima, Z = lateral.
class V3 {
  const V3(this.x, this.y, this.z);

  final double x, y, z;

  static const zero = V3(0, 0, 0);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double s) => V3(x * s, y * s, z * s);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);

  V3 get unit {
    final l = length;
    return l < 1e-9 ? const V3(0, 1, 0) : V3(x / l, y / l, z / l);
  }

  static V3 lerp(V3 a, V3 b, double t) => a + (b - a) * t;

  static V3 fromList(List<dynamic> l) =>
      V3((l[0] as num).toDouble(), (l[1] as num).toDouble(), (l[2] as num).toDouble());
}

/// Índices das articulações em cada quadro (x, y, z em sequência).
class Jt {
  static const hip = 0;
  static const neck = 1;
  static const head = 2;
  static const shN = 3;
  static const elbN = 4;
  static const handN = 5;
  static const shF = 6;
  static const elbF = 7;
  static const handF = 8;
  static const hipN = 9;
  static const kneeN = 10;
  static const ankN = 11;
  static const toeN = 12;
  static const hipF = 13;
  static const kneeF = 14;
  static const ankF = 15;
  static const toeF = 16;
  static const count = 17;

  /// Direções: frente do tronco, topo da cabeça e para onde o rosto olha.
  static const torsoFront = count * 3;
  static const headUp = count * 3 + 3;
  static const headFace = count * 3 + 6;

  /// Primeiro valor dos pontos acompanhados pelos equipamentos.
  static const trackedBase = count * 3 + 9;
}

/// Altura do chão (Y para cima).
const double kFloorY = -122.0;

/// Câmera ortográfica que gira em volta da pessoa.
class Camera {
  Camera(this.yawDeg, [this.pitchDeg = 12]) {
    final th = yawDeg * math.pi / 180, ph = pitchDeg * math.pi / 180;
    toward = V3(math.sin(th) * math.cos(ph), math.sin(ph), math.cos(th) * math.cos(ph));
    right = V3(math.cos(th), 0, -math.sin(th));
    up = toward.cross(right).unit;
  }

  final double yawDeg;
  final double pitchDeg;

  /// Direção que aponta da cena para quem está vendo.
  late final V3 toward;
  late final V3 right;
  late final V3 up;

  Offset project(V3 p) => Offset(p.dot(right), -p.dot(up));

  /// Maior = mais perto de quem vê.
  double depth(V3 p) => p.dot(toward);

  /// Direção 3D projetada na tela (sem normalizar).
  Offset projectDir(V3 d) => Offset(d.dot(right), -d.dot(up));
}

class MotionPhase {
  const MotionPhase(this.start, this.end, this.label);
  final int start;
  final int end;
  final String label;
}

/// Equipamento que se move com a pessoa.
class MotionProp {
  MotionProp(this.type, this.params, this.track);

  final String type;
  final Map<String, dynamic> params;
  final List<int> track;

  double val(String key, [double fallback = 0]) {
    final v = params[key];
    return v is num ? v.toDouble() : fallback;
  }
}

/// Equipamento parado: caixa (prisma), cilindro ou disco.
class Prim {
  Prim(this.kind, this.color, {this.face = const [], this.ext = V3.zero, this.a = V3.zero, this.b = V3.zero,
      this.r = 1, this.n = const V3(0, 0, 1), this.opacity = 1});

  final String kind;
  final String color;
  final List<V3> face;
  final V3 ext;
  final V3 a, b, n;
  final double r;
  final double opacity;

  Iterable<V3> get points sync* {
    if (kind == 'box') {
      for (final p in face) {
        yield p;
        yield p + ext;
      }
    } else if (kind == 'cyl') {
      yield a;
      yield b;
    } else {
      yield a;
    }
  }

  static Prim fromJson(Map<String, dynamic> j) {
    final k = j['k'] as String;
    if (k == 'box') {
      return Prim('box', j['c'] as String,
          face: [for (final p in (j['face'] as List)) V3.fromList(p as List)],
          ext: V3.fromList(j['ext'] as List),
          opacity: (j['op'] as num?)?.toDouble() ?? 1);
    }
    if (k == 'cyl') {
      return Prim('cyl', j['c'] as String,
          a: V3.fromList(j['a'] as List), b: V3.fromList(j['b'] as List), r: (j['r'] as num).toDouble());
    }
    return Prim('disc', (j['col'] as String?) ?? 'eq',
        a: V3.fromList(j['c'] as List), n: V3.fromList(j['n'] as List), r: (j['r'] as num).toDouble());
  }
}

class MotionClip {
  MotionClip({
    required this.id,
    required this.name,
    required this.plane,
    required this.defaultYaw,
    required this.fps,
    required this.phases,
    required this.prims,
    required this.props,
    required this.frames,
  });

  final String id;
  final String name;

  /// Plano em que o movimento foi desenhado: side, front ou top.
  final String plane;

  /// Ângulo inicial da câmera (0 = de lado, 90 = de frente).
  final double defaultYaw;
  final int fps;
  final List<MotionPhase> phases;
  final List<Prim> prims;
  final List<MotionProp> props;
  final List<Float32List> frames;

  int get frameCount => frames.length;
  int get valuesPerFrame => frames.isEmpty ? 0 : frames.first.length;

  Duration get duration => Duration(milliseconds: (frameCount * 1000 / fps).round());

  /// Proporção usada para o quadro da animação.
  double get aspectRatio => 160 / 130;

  String phaseAt(double t) {
    if (phases.isEmpty) return '';
    final f = (t * frameCount).floor() % frameCount;
    for (final p in phases) {
      if (f >= p.start && f < p.end) return p.label;
    }
    return phases.last.label;
  }

  /// Amostra o movimento no instante [t] (0 a 1, em loop).
  Float32List sample(double t, [Float32List? out]) {
    final n = frameCount;
    final res = out ?? Float32List(valuesPerFrame);
    if (n == 0) return res;
    var pos = (t % 1.0) * n;
    if (pos < 0) pos += n;
    final i0 = pos.floor() % n;
    final i1 = (i0 + 1) % n;
    final k = pos - pos.floor();
    final a = frames[i0];
    final b = frames[i1];
    for (var i = 0; i < res.length; i++) {
      res[i] = a[i] + (b[i] - a[i]) * k;
    }
    return res;
  }

  static V3 at(Float32List f, int index) => V3(f[index], f[index + 1], f[index + 2]);

  static V3 joint(Float32List f, int j) => at(f, j * 3);

  // ------------------------------------------------------------ enquadramento

  final Map<int, Rect> _bounds = {};

  /// Retângulo (na tela, em unidades do mundo) que contém a pessoa e o que ela
  /// move durante todo o loop, para a câmera [cam].
  Rect boundsFor(Camera cam) {
    final key = (cam.yawDeg.round() % 360) * 1000 + cam.pitchDeg.round();
    return _bounds.putIfAbsent(key, () {
      var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
      void add(V3 p) {
        final s = cam.project(p);
        if (s.dx < minX) minX = s.dx;
        if (s.dx > maxX) maxX = s.dx;
        if (s.dy < minY) minY = s.dy;
        if (s.dy > maxY) maxY = s.dy;
      }

      for (var i = 0; i < frames.length; i += 2) {
        final f = frames[i];
        for (var j = 0; j < Jt.count; j++) {
          add(joint(f, j));
        }
        for (var idx = Jt.trackedBase; idx + 2 < f.length; idx += 3) {
          add(at(f, idx));
        }
      }
      // garante que o chão sob os pés aparece
      final f0 = frames.first;
      add(V3(joint(f0, Jt.ankN).x, kFloorY, joint(f0, Jt.ankN).z));
      const m = 13.0;
      return Rect.fromLTRB(minX - m, minY - m - 4, maxX + m, maxY + m);
    });
  }

  // ------------------------------------------------------------ ponto-chave

  late final int _keyIndex = _pickKeyIndex();

  /// Posição 3D do ponto-chave em cada quadro (para desenhar o percurso).
  late final List<V3> keyPath = [for (final f in frames) at(f, _keyIndex)];

  late final double keyPathExtent = _extent(keyPath);

  V3 keyPointAt(double t) {
    final s = sample(t);
    return at(s, _keyIndex);
  }

  /// Instantes das poses-chave: início, meio do caminho e ponto mais distante.
  late final List<double> keyTimes = _computeKeyTimes();

  static double _extent(List<V3> pts) {
    if (pts.isEmpty) return 0;
    var best = 0.0;
    for (final p in pts) {
      final d = (p - pts.first).length;
      if (d > best) best = d;
    }
    return best;
  }

  int _pickKeyIndex() {
    if (frames.isEmpty) return Jt.hip * 3;
    double extentOf(int idx) => _extent([for (final f in frames) at(f, idx)]);
    const loadTypes = {'barbell', 'dumbbell', 'kettlebell', 'grip'};
    for (final p in props) {
      if (p.track.isNotEmpty && loadTypes.contains(p.type)) {
        final idx = Jt.trackedBase + p.track.first * 3;
        if (idx + 2 < valuesPerFrame && extentOf(idx) > 6) return idx;
      }
    }
    const candidates = [Jt.handN, Jt.ankN, Jt.kneeN, Jt.hip, Jt.head, Jt.handF, Jt.ankF];
    var best = Jt.hip * 3;
    var bestExt = -1.0;
    for (final j in candidates) {
      final e = extentOf(j * 3);
      if (e > bestExt + 0.5) {
        bestExt = e;
        best = j * 3;
      }
    }
    return best;
  }

  List<double> _computeKeyTimes() {
    final n = frameCount;
    if (n < 3) return const [0.0, 0.5, 0.5];
    final first = frames.first;
    double diff(Float32List f) {
      var s = 0.0;
      for (var i = 0; i < Jt.count * 3; i++) {
        final d = f[i] - first[i];
        s += d * d;
      }
      return s;
    }

    var far = 0;
    var farD = -1.0;
    for (var i = 0; i < n; i++) {
      final d = diff(frames[i]);
      if (d > farD) {
        farD = d;
        far = i;
      }
    }
    var mid = far ~/ 2;
    var bestGap = double.infinity;
    for (var i = 0; i <= far; i++) {
      final gap = (diff(frames[i]) - farD / 4).abs();
      if (gap < bestGap) {
        bestGap = gap;
        mid = i;
      }
    }
    return [0.0, mid / n, far / n];
  }

  static MotionClip fromJson(String id, Map<String, dynamic> j) {
    final props = <MotionProp>[];
    for (final raw in (j['props'] as List)) {
      final m = Map<String, dynamic>.from(raw as Map);
      final track = (m['track'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const <int>[];
      props.add(MotionProp(m['type'] as String, m, track));
    }
    return MotionClip(
      id: id,
      name: j['name'] as String,
      plane: (j['plane'] as String?) ?? 'side',
      defaultYaw: (j['yaw'] as num?)?.toDouble() ?? 0,
      fps: (j['fps'] as num).toInt(),
      phases: [
        for (final p in (j['phases'] as List))
          MotionPhase((p[0] as num).toInt(), (p[1] as num).toInt(), p[2] as String),
      ],
      prims: [for (final p in (j['prims'] as List)) Prim.fromJson(Map<String, dynamic>.from(p as Map))],
      props: props,
      frames: [
        for (final row in (j['frames'] as List))
          Float32List.fromList([for (final v in (row as List)) (v as num).toDouble()]),
      ],
    );
  }
}

class MotionLibrary {
  MotionLibrary(this.clips);

  final Map<String, MotionClip> clips;

  MotionClip? operator [](String? id) => id == null ? null : clips[id];

  List<MotionClip> get sorted => clips.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  static MotionLibrary parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final pats = j['patterns'] as Map<String, dynamic>;
    return MotionLibrary({
      for (final e in pats.entries) e.key: MotionClip.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }
}
