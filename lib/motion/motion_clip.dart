import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

/// Índices das articulações em cada quadro (x, y em sequência).
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

  /// Posição do ângulo do tronco e da cabeça no vetor do quadro.
  static const torsoAngle = count * 2;
  static const headAngle = count * 2 + 1;

  /// Primeiro valor dos pontos acompanhados pelos equipamentos.
  static const trackedBase = count * 2 + 2;
}

/// Chão do mundo de desenho (unidades do estúdio de movimento).
const double kGroundY = 122.0;

class MotionPhase {
  const MotionPhase(this.start, this.end, this.label);
  final int start;
  final int end;
  final String label;
}

class MotionProp {
  MotionProp(this.type, this.params, this.track);

  final String type;
  final Map<String, dynamic> params;
  final List<int> track;

  double val(String key, [double fallback = 0]) {
    final v = params[key];
    return v is num ? v.toDouble() : fallback;
  }

  bool flag(String key) => params[key] == true;

  List<Offset> points() {
    final raw = params['pts'];
    if (raw is! List) return const [];
    return [
      for (final p in raw)
        if (p is List && p.length >= 2) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
  }
}

class MotionClip {
  MotionClip({
    required this.id,
    required this.name,
    required this.view,
    required this.fps,
    required this.viewport,
    required this.phases,
    required this.props,
    required this.frames,
  });

  final String id;
  final String name;
  final String view;
  final int fps;
  final Rect viewport;
  final List<MotionPhase> phases;
  final List<MotionProp> props;
  final List<Float32List> frames;

  bool get isFront => view == 'front';
  int get frameCount => frames.length;
  int get valuesPerFrame => frames.isEmpty ? 0 : frames.first.length;

  Duration get duration => Duration(milliseconds: (frameCount * 1000 / fps).round());

  double get aspectRatio => viewport.width / viewport.height;

  String phaseAt(double t) {
    if (phases.isEmpty) return '';
    final f = (t * frameCount).floor() % frameCount;
    for (final p in phases) {
      if (f >= p.start && f < p.end) return p.label;
    }
    return phases.last.label;
  }

  /// Amostra o movimento no instante [t] (0 a 1, em loop), interpolando
  /// entre os quadros vizinhos.
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
      if (i == Jt.torsoAngle || i == Jt.headAngle) {
        var diff = (b[i] - a[i]) % 360.0;
        if (diff > 180) diff -= 360;
        res[i] = a[i] + diff * k;
      } else {
        res[i] = a[i] + (b[i] - a[i]) * k;
      }
    }
    return res;
  }

  static MotionClip fromJson(String id, Map<String, dynamic> j) {
    final vp = (j['vp'] as List).map((e) => (e as num).toDouble()).toList();
    final props = <MotionProp>[];
    for (final raw in (j['props'] as List)) {
      final m = Map<String, dynamic>.from(raw as Map);
      final track = (m['track'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const <int>[];
      props.add(MotionProp(m['type'] as String, m, track));
    }
    final phases = <MotionPhase>[
      for (final p in (j['phases'] as List))
        MotionPhase((p[0] as num).toInt(), (p[1] as num).toInt(), p[2] as String),
    ];
    final frames = <Float32List>[
      for (final row in (j['frames'] as List))
        Float32List.fromList([for (final v in (row as List)) (v as num).toDouble()]),
    ];
    return MotionClip(
      id: id,
      name: j['name'] as String,
      view: j['view'] as String,
      fps: (j['fps'] as num).toInt(),
      viewport: Rect.fromLTWH(vp[0], vp[1], vp[2], vp[3]),
      phases: phases,
      props: props,
      frames: frames,
    );
  }
}

class MotionLibrary {
  MotionLibrary(this.clips);

  final Map<String, MotionClip> clips;

  MotionClip? operator [](String? id) => id == null ? null : clips[id];

  /// Lista ordenada por nome, para escolher a animação de um exercício novo.
  List<MotionClip> get sorted => clips.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  static MotionLibrary parse(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final pats = j['patterns'] as Map<String, dynamic>;
    return MotionLibrary({
      for (final e in pats.entries) e.key: MotionClip.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }
}
