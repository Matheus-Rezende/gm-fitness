import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'figure_painter.dart';
import 'mesh3d.dart';
import 'motion_clip.dart';

/// Boneco em desenho 2D (estilo cartoon: formas chapadas com contorno),
/// visto de ângulos fixos. Reaproveita o movimento, o cenário e os
/// equipamentos do clipe 3D; só o corpo é redesenhado em 2D.
///
/// Os músculos trabalhados aparecem pintados no corpo: laranja pulsando para
/// o principal e amarelo para os auxiliares.
class CartoonPainter extends CustomPainter {
  CartoonPainter({
    required this.clip,
    required this.time,
    required this.palette,
    this.style = const FigureStyle(),
    this.yaw,
    this.showFloor = true,
  });

  final MotionClip clip;
  final double time;
  final FigurePalette palette;
  final FigureStyle style;

  /// Giro da câmera em graus (0 = de lado, 90 = de frente, 270 = de costas).
  final double? yaw;
  final bool showFloor;

  static const primaryColor = Color(0xFFFF8A1F);
  static const secondaryColor = Color(0xFFFFD54A);

  late Camera _cam;
  late Float32List _f;
  late _Look _look;
  double _pulse = 0.5;

  V3 _j(int j) => MotionClip.joint(_f, j);
  V3 _vec(int index) => MotionClip.at(_f, index).unit;
  Offset _p(V3 v) => _cam.project(v);

  @override
  void paint(Canvas canvas, Size size) {
    if (clip.frameCount == 0 || size.isEmpty) return;
    final fp = FigurePainter(clip: clip, time: time, palette: palette, style: style, yaw: yaw, pitch: pitchFor(clip, time))
      ..prepare();
    _cam = fp.camera;
    _f = fp.frame;
    _pulse = fp.pulse;
    _look = style.male ? _Look.man : _Look.woman;

    final bounds = clip.boundsFor(_cam).inflate(4);
    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    if (showFloor) _floor(canvas);
    fp.equipmentMesh().draw(canvas, _cam, cel: true);

    final parts = _bodyParts();
    for (final (depth, mesh) in fp.propMeshes()) {
      parts.add(_Part.mesh(depth, mesh));
    }
    parts.sort((a, b) => a.depth.compareTo(b.depth));
    final outline = Paint()
      ..color = _look.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeJoin = StrokeJoin.round;
    for (final p in parts) {
      if (p.mesh != null) {
        p.mesh!.draw(canvas, _cam, cel: true);
        continue;
      }
      canvas.drawPath(p.path, Paint()..color = p.color);
      p.detail?.call(canvas);
      if (style.showMuscles) {
        for (final m in p.muscles) {
          _patch(canvas, p.path, m);
        }
      }
      p.over?.call(canvas);
      canvas.drawPath(p.path, outline);
    }
    if (style.showMuscles && _wholeBody) _glow(canvas, parts);
    if (style.showPath) _keyPath(canvas);
    canvas.restore();
  }

  /// Percurso do ponto que mais se move (mão, pé...), pontilhado, com a
  /// posição atual e uma seta no sentido do movimento.
  void _keyPath(Canvas c) {
    final path = clip.keyPath;
    if (path.length < 3 || clip.keyPathExtent < 6) return;
    final pts = [for (final p in path) _p(p)];
    final paint = Paint()
      ..color = palette.path.withAlpha(150)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length; i += 2) {
      c.drawLine(pts[i], pts[(i + 1) % pts.length], paint);
    }
    final cur = _p(clip.keyPointAt(time));
    final prev = _p(clip.keyPointAt(time - 0.04));
    final mv = cur - prev;
    c.drawCircle(cur, 2.0, Paint()..color = palette.path);
    c.drawCircle(cur, 2.0, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6);
    if (mv.distance > 0.4) {
      final u = mv / mv.distance;
      final n = Offset(-u.dy, u.dx);
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

  /// Câmera mais alta quando a pessoa está deitada (de barriga para cima ou
  /// para baixo), para o peito ou as costas aparecerem.
  static double pitchFor(MotionClip clip, double time) {
    final f = clip.sample(time);
    final front = MotionClip.at(f, Jt.torsoFront).unit;
    return 7 + 30 * front.y.abs().clamp(0.0, 1.0);
  }

  /// Vista (0 lado, 45 ¾, 90 frente, 270 costas) em que o músculo principal
  /// aparece melhor; empata a favor da vista padrão do exercício.
  static double bestYaw(MotionClip clip, Set<String> primary) {
    const frontG = {'peito', 'abdomen', 'biceps', 'quadriceps', 'antebraco'};
    const backG = {'costas', 'lombar', 'gluteos', 'trapezio', 'triceps', 'posterior', 'panturrilha'};
    final wantFront = primary.any(frontG.contains);
    final wantBack = primary.any(backG.contains);
    if (wantFront == wantBack) return clip.defaultYaw;
    final f = clip.sample(0.3);
    final front = MotionClip.at(f, Jt.torsoFront).unit;
    final pitch = pitchFor(clip, 0.3);
    double vis(double yaw) {
      final t = Camera(yaw, pitch).toward;
      final v = front.dot(t);
      return wantFront ? v : -v;
    }
    final candidates = [clip.defaultYaw, 0.0, 45.0, 90.0, 270.0];
    var best = clip.defaultYaw;
    var bestV = vis(best) + 0.25; // a padrão ganha se não perder por muito
    for (final y in candidates) {
      final v = vis(y);
      if (v > bestV) {
        best = y;
        bestV = v;
      }
    }
    return best;
  }

  bool get _wholeBody => style.primary.contains('corpo_inteiro') || style.primary.contains('cardio');

  // ------------------------------------------------------------ cenário

  void _floor(Canvas c) {
    final hip = _j(Jt.hip);
    const span = 70.0;
    final corners = [
      V3(hip.x - span, kFloorY, hip.z - span),
      V3(hip.x + span, kFloorY, hip.z - span),
      V3(hip.x + span, kFloorY, hip.z + span),
      V3(hip.x - span, kFloorY, hip.z + span),
    ];
    c.drawPath(Path()..addPolygon([for (final p in corners) _p(p)], true), Paint()..color = palette.floor);
    // sombra chapada debaixo do boneco
    final ankN = _j(Jt.ankN), ankF = _j(Jt.ankF);
    final lo = ankN.y < ankF.y ? ankN : ankF;
    final cx = (ankN.x + ankF.x) / 2, cz = (ankN.z + ankF.z) / 2;
    final lift = ((lo.y - kFloorY) / 25).clamp(0.0, 1.0);
    final center = _p(V3(cx, kFloorY, cz));
    final w = 18.0 * (1 - 0.3 * lift), h = 4.5 * (1 - 0.3 * lift);
    c.drawOval(Rect.fromCenter(center: center, width: w * 2, height: h * 2),
        Paint()..color = Colors.black.withAlpha((44 * (1 - 0.5 * lift)).round()));
  }

  // ------------------------------------------------------------ corpo

  /// Direção na tela perpendicular ao segmento a→b (3D), normalizada.
  V3 _perp3(V3 a, V3 b) {
    final axis = b - a;
    final n = axis.cross(_cam.toward);
    return n.length < 1e-3 ? _cam.right : n.unit;
  }

  Offset _dir(V3 d) {
    final o = _cam.projectDir(d);
    return o.distance < 1e-6 ? Offset.zero : o / o.distance;
  }

  double _mw(String g) {
    if (style.primary.contains(g)) return 1;
    if (style.secondary.contains(g)) return 0.5;
    return 0;
  }

  /// Cápsula entre [a] e [b] com raios [ra] e [rb].
  static Path capsule(Offset a, Offset b, double ra, double rb) {
    final d = b - a;
    final len = d.distance;
    if (len < 1e-3) return Path()..addOval(Rect.fromCircle(center: a, radius: math.max(ra, rb)));
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    final ang = math.atan2(u.dy, u.dx);
    return Path()
      ..moveTo(a.dx + n.dx * ra, a.dy + n.dy * ra)
      ..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)
      ..arcTo(Rect.fromCircle(center: b, radius: rb), ang + math.pi / 2, -math.pi, false)
      ..lineTo(a.dx - n.dx * ra, a.dy - n.dy * ra)
      ..arcTo(Rect.fromCircle(center: a, radius: ra), ang - math.pi / 2, -math.pi, false)
      ..close();
  }

  /// Faixa do membro (cápsula p0→p1 de raio [r]) onde a superfície aponta na
  /// direção 3D [dir]: cobre a largura toda quando [dir] olha para quem vê,
  /// metade quando aponta para o lado e nada quando aponta para trás.
  Path? _band(Path base, Offset p0, Offset p1, double r, V3 dir, V3 perp3, {double from = 0.0, double to = 1.0}) {
    final d = p1 - p0;
    final len = d.distance;
    if (len < 1e-3) return null;
    final u = d / len;
    var n = Offset(-u.dy, u.dx);
    // n na tela deve corresponder a perp3 (ambos perpendiculares ao membro)
    final nS = _dir(perp3);
    if (nS.dx * n.dx + nS.dy * n.dy < 0) n = -n;
    final aSide = dir.dot(perp3), aTow = dir.dot(_cam.toward);
    if (aTow < -0.92) return null;
    // superfície do cilindro: ângulo phi em volta do eixo (0 = de frente para quem vê);
    // o músculo cobre onde normal·dir > 0, ou seja, aTow*cos(phi) + aSide*sin(phi) > 0
    final phi0 = math.atan2(-aTow, aSide.abs() < 1e-6 ? 1e-6 : aSide).clamp(-math.pi / 2, math.pi / 2);
    final s0 = r * math.sin(phi0);
    final best = math.atan2(aSide, aTow).clamp(-math.pi / 2, math.pi / 2); // onde dir mais aparece
    final sBest = r * math.sin(best);
    final sgn = sBest >= s0 ? 1.0 : -1.0; // região: do lado de sBest em relação a s0
    final q0 = p0 + d * from, q1 = p0 + d * to;
    final inner = n * s0;
    final outer = n * (sgn * r * 3);
    final rect = Path()..addPolygon([q0 + inner, q1 + inner, q1 + outer, q0 + outer], true);
    final out = Path.combine(PathOperation.intersect, base, rect);
    return out.getBounds().isEmpty ? null : out;
  }

  List<_Part> _bodyParts() {
    final look = _look;
    final parts = <_Part>[];
    final hip = _j(Jt.hip), neck = _j(Jt.neck), head = _j(Jt.head);
    final up = (neck - hip).unit;
    var front = perpTo(_vec(Jt.torsoFront), up);
    front = front.length < 1e-3 ? const V3(1, 0, 0) : front.unit;
    final lat = up.cross(front).unit;
    final faceDir = _vec(Jt.headFace);
    final headUp = _vec(Jt.headUp);
    final frontK = front.dot(_cam.toward); // >0: frente virada para quem vê
    final frontScreen = _dir(front);

    double depthOf(V3 a, [V3? b]) => _cam.depth(b == null ? a : (a + b) * 0.5);

    // ---- tronco
    {
      final perp = _perp3(hip, neck);
      double halfW(double aLat, double bFront) =>
          math.sqrt(math.pow(aLat * lat.dot(perp), 2) + math.pow(bFront * front.dot(perp), 2));
      final shW = halfW(look.shoulderW, look.chestD);
      final waistW = halfW(look.waistW, look.waistD);
      final hipW = halfW(look.hipW, look.hipD);
      final axisLen = (neck - hip).length;
      final n = _dir(perp);
      final side = Offset(n.dx, n.dy);
      // largura ao longo do tronco: quadril -> cintura -> ombros (suave)
      double wAt(double t) {
        double mix(double a, double b, double k) => a + (b - a) * (0.5 - 0.5 * math.cos(k.clamp(0.0, 1.0) * math.pi));
        return t < 0.42 ? mix(hipW, waistW, t / 0.42) : mix(waistW, shW, (t - 0.42) / 0.58);
      }
      Offset axisPt(double t) => _p(hip + up * (axisLen * t - 3.0 * (1 - t) - 1.5 * t));
      final pts = <Offset>[];
      const steps = 14;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        pts.add(axisPt(t) + side * wAt(t));
      }
      // ombros arredondados
      final top = axisPt(1.0);
      final uS = _dir(up);
      for (var i = 1; i < 8; i++) {
        final ang = math.pi * i / 8;
        pts.add(top + side * (shW * math.cos(ang)) + uS * (shW * 0.45 * math.sin(ang)));
      }
      for (var i = steps; i >= 0; i--) {
        final t = i / steps;
        pts.add(axisPt(t) - side * wAt(t));
      }
      final bottom = axisPt(0.0);
      for (var i = 1; i < 8; i++) {
        final ang = math.pi * i / 8;
        pts.add(bottom - side * (hipW * math.cos(ang)) - uS * (hipW * 0.55 * math.sin(ang)));
      }
      final path = Path()..addPolygon(pts, true);
      // camiseta em cima, roupa de baixo no quadril
      final topLen = look.male ? 0.32 : 0.46; // onde a camiseta termina (fração do tronco a partir do quadril)
      final muscles = <_Muscle>[];
      final perpT = _perp3(hip, neck);
      // mancha no tronco: faixa do lado que [frontSide] aponta (toda a largura de
      // frente, uma tira na borda de lado, nada de costas), arredondada
      void torsoPatch(String g, double tLo, double tHi, double sideK, bool frontSide) {
        final w = _mw(g);
        if (w == 0) return;
        final dirV = frontSide ? front : front * -1;
        final p0 = axisPt(tLo), p1 = axisPt(tHi);
        final rMid = wAt(((tLo + tHi) / 2).clamp(0.0, 1.0)) * sideK;
        final band = _band(path, p0, p1, rMid, dirV, perpT, from: 0.0, to: 1.0);
        if (band == null) return;
        // arredonda as pontas com uma elipse ao longo do eixo
        final c = (p0 + p1) * 0.5;
        final h = (p1 - p0).distance / 2 + 1.0;
        final ang = math.atan2((p1 - p0).dy, (p1 - p0).dx);
        final oval = Path()..addOval(Rect.fromCenter(center: Offset.zero, width: h * 2, height: rMid * 2.6));
        final m = Matrix4.identity()
          ..translate(c.dx, c.dy)
          ..rotateZ(ang);
        final region = Path.combine(PathOperation.intersect, band, oval.transform(m.storage));
        if (region.getBounds().isEmpty) return;
        final splitDir = frontScreen.distance > 0.3 ? frontScreen : null;
        muscles.add(_Muscle(g, w, region, split: g == 'peito' || g == 'abdomen' || g == 'costas' ? splitDir : null));
      }
      torsoPatch('peito', 0.66, 0.95, 0.95, true);
      torsoPatch('abdomen', 0.3, 0.64, 0.7, true);
      torsoPatch('costas', 0.5, 0.96, 1.0, false);
      torsoPatch('lombar', 0.16, 0.48, 0.75, false);
      if (_mw('gluteos') > 0) {
        // glúteos: dois montes na parte de trás do quadril
        final p0 = axisPt(-0.08), p1 = axisPt(0.16);
        final band = _band(path, p0, p1, hipW, front * -1, perpT, from: -0.4, to: 1.2);
        if (band != null) {
          final c = (p0 + p1) * 0.5;
          final sp = hipW * 0.5;
          for (final sg in const [-1.0, 1.0]) {
            final oval = Path()..addOval(Rect.fromCenter(center: c + side * (sp * sg), width: sp * 2.1, height: (p1 - p0).distance + 3));
            final region = Path.combine(PathOperation.intersect, band, oval);
            if (!region.getBounds().isEmpty) muscles.add(_Muscle('gluteos', _mw('gluteos'), region));
          }
        }
      }
      if (_mw('trapezio') > 0) {
        final c = _p(neck - up * 2);
        muscles.add(_Muscle('trapezio', _mw('trapezio'), Path()..addOval(Rect.fromCenter(center: c, width: shW * 1.5, height: 6))));
      }
      parts.add(_Part(
        depthOf(hip, neck),
        path,
        look.top,
        muscles: muscles,
        detail: (c) {
          // roupa de baixo (short/legging) na parte de baixo do tronco
          final cut = Path()
            ..addRect(Rect.fromCenter(
                center: _p(hip + up * ((neck - hip).length * topLen / 2 - 2)),
                width: 60,
                height: (neck - hip).length * topLen + 4));
          c.save();
          c.clipPath(path);
          c.drawPath(cut, Paint()..color = look.bottom);
          // barra da camiseta
          final y0 = _p(hip + up * ((neck - hip).length * topLen));
          final sx = side * (hipW + 2);
          c.drawLine(y0 + sx, y0 - sx, Paint()
            ..color = look.outline.withAlpha(120)
            ..strokeWidth = 0.7);
          // marca no peito
          if (frontK > 0.3) {
            final m = _p(hip + up * ((neck - hip).length * 0.78)) + frontScreen * 2.5 + side * (shW * 0.35 * (frontScreen.dx >= 0 ? -1 : 1));
            c.drawCircle(m, 1.6, Paint()..color = Colors.white);
            c.drawCircle(m, 0.8, Paint()..color = look.accent);
          }
          // gola
          final g = _p(neck - up * 2.2);
          c.drawOval(Rect.fromCenter(center: g, width: 5.5, height: 2.6), Paint()..color = look.skin);
          c.restore();
        },
      ));
    }

    // ---- pescoço
    parts.add(_Part(depthOf(neck, head) - 0.3, capsule(_p(neck - up * 1.0), _p(head - headUp * 3.0), 2.3, 2.1), look.skin));

    // ---- cabeça
    {
      final r = look.headR;
      final c = _p(head + headUp * 0.6);
      final fx = faceDir.dot(_cam.right); // >0: rosto virado para a direita da tela
      final fz = faceDir.dot(_cam.toward); // >0: rosto virado para quem vê
      final uS = _dir(headUp);
      final rS = Offset(-uS.dy, uS.dx); // direita da tela, no referencial da cabeça
      final nape = -fx; // lado da nuca na tela
      final headDepth = depthOf(head);
      // calota de cabelo: cobre o topo e a nuca; o rosto fica livre
      final hairPath = Path()
        ..addOval(Rect.fromCenter(center: c + uS * (r * 0.12) + rS * (nape * r * 0.14), width: r * 2.08, height: r * 2.08));
      final faceCut = Path()
        ..addOval(Rect.fromCenter(
            center: c - uS * (r * 0.3) + rS * (fx * r * 0.5),
            width: r * 1.9 * (0.5 + 0.5 * fz.clamp(0.0, 1.0)) + r * 0.3 * fx.abs(),
            height: r * 1.85));
      final hair = fz > -0.4 ? Path.combine(PathOperation.difference, hairPath, faceCut) : hairPath;
      // rabo de cavalo (mulher): sai da nuca e cai pelas costas; fica atrás da
      // cabeça quando ela olha para nós e na frente quando está de costas
      if (!look.male) {
        final tailDepth = headDepth - 0.6 - fz * 3.5;
        final base = c + uS * (r * 0.25) + rS * (nape * r * 0.85);
        final tip = base - uS * (r * 1.5) + rS * (nape * r * 0.45);
        parts.add(_Part(tailDepth, capsule(base, tip, r * 0.3, r * 0.18), look.hair,
            over: (cv) => cv.drawCircle(base, r * 0.2, Paint()..color = look.accent)));
      }
      parts.add(_Part(
        headDepth,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        look.skin,
        detail: (cv) {
          cv.drawPath(hair, Paint()..color = look.hair);
          if (look.male) {
            // topete na testa e costeleta
            cv.drawOval(Rect.fromCenter(center: c + uS * (r * 0.93) + rS * (fx * r * 0.25), width: r * 0.8, height: r * 0.42), Paint()..color = look.hair);
          } else {
            // franja caindo para o lado da testa
            cv.drawOval(Rect.fromCenter(center: c + uS * (r * 0.78) + rS * (fx * r * 0.42), width: r * 0.8, height: r * 0.4), Paint()..color = look.hair);
          }
          if (fz > -0.2) _face(cv, c, r, fx, fz, uS, rS);
          // orelha do lado da nuca (some quando o rosto está bem de frente ou bem de costas)
          if (fz.abs() < 0.93 && fx.abs() > 0.15) {
            final e = c + rS * (nape * r * 0.95) - uS * (r * 0.05);
            final ear = Rect.fromCenter(center: e, width: r * 0.36, height: r * 0.5);
            cv.drawOval(ear, Paint()..color = look.skin);
            cv.drawOval(ear, Paint()
              ..color = look.outline
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8);
          }
        },
      ));
    }

    // ---- braços e pernas
    void limb(int sh, int el, int ha, String upperFront, String upperBack, String foreG, double ru0, double ru1, double rf0, double rf1, V3 fallbackFront, bool shoulder) {
      final a = _j(sh), b = _j(el), h = _j(ha);
      final upperV = b - a, foreV = h - b;
      // lado da frente do braço (onde o cotovelo dobra); esticado, a frente do tronco
      var ant = perpTo(foreV, upperV);
      ant = ant.length < 1.5 ? perpTo(fallbackFront, upperV) : ant;
      ant = ant.length < 1e-3 ? _cam.right : ant.unit;
      final pa = _p(a), pb = _p(b), ph = _p(h);
      final perpU = _perp3(a, b);
      final upper = capsule(pa, pb, ru0, ru1);
      final ms = <_Muscle>[];
      void band(String g, V3 dir, {double from = 0.05, double to = 0.95}) {
        final w = _mw(g);
        if (w == 0) return;
        final pth = _band(upper, pa, pb, ru1, dir, perpU, from: from, to: to);
        if (pth != null) ms.add(_Muscle(g, w, pth));
      }
      band(upperFront, ant, from: 0.18, to: 0.95);
      band(upperBack, ant * -1, from: 0.12, to: 0.95);
      if (shoulder && _mw('ombros') > 0) {
        ms.add(_Muscle('ombros', _mw('ombros'), Path()..addOval(Rect.fromCircle(center: pa + (pb - pa) * 0.1, radius: ru0 * 1.05))));
      }
      final fore = capsule(pb, ph, rf0, rf1);
      final fm = <_Muscle>[];
      if (_mw(foreG) > 0) {
        fm.add(_Muscle(foreG, _mw(foreG), Path.combine(PathOperation.intersect, fore, capsule(pb + (ph - pb) * 0.1, pb + (ph - pb) * 0.75, rf0 * 1.2, rf1 * 1.1))));
      }
      final sleeve = shoulder;
      parts.add(_Part(depthOf(a, b), upper, sleeve ? look.skin : look.bottom, muscles: ms, detail: sleeve
          ? (cv) {
              // manga curta
              cv.save();
              cv.clipPath(upper);
              cv.drawPath(capsule(pa - (pb - pa) * 0.1, pa + (pb - pa) * (look.male ? 0.3 : 0.2), ru0 * 1.25, ru0 * 1.1), Paint()..color = look.top);
              cv.restore();
            }
          : null));
      parts.add(_Part(depthOf(b, h), fore, shoulder ? look.skin : look.bottom, muscles: fm));
      if (shoulder) {
        // mão: bolinha com polegar
        final hd = (ph - pb);
        final hu = hd.distance < 1e-3 ? const Offset(0, 1) : hd / hd.distance;
        parts.add(_Part(depthOf(h) + 0.2, Path()..addOval(Rect.fromCircle(center: ph + hu * (rf1 * 0.6), radius: rf1 * 1.25)), look.skin));
      }
    }
    limb(Jt.shN, Jt.elbN, Jt.handN, 'biceps', 'triceps', 'antebraco', look.armR, look.armR * 0.86, look.armR * 0.82, look.armR * 0.7, front, true);
    limb(Jt.shF, Jt.elbF, Jt.handF, 'biceps', 'triceps', 'antebraco', look.armR, look.armR * 0.86, look.armR * 0.82, look.armR * 0.7, front, true);

    void leg(int hj, int kn, int an, int to) {
      final h = _j(hj), k = _j(kn), a = _j(an), t = _j(to);
      final thighV = k - h, shinV = a - k;
      var ant = perpTo(shinV * -1, thighV);
      ant = ant.length < 1.5 ? perpTo(front, thighV) : ant;
      ant = ant.length < 1e-3 ? _cam.right : ant.unit;
      final ph = _p(h), pk = _p(k), pa = _p(a), pt = _p(t);
      final perpT = _perp3(h, k);
      final thigh = capsule(ph, pk, look.thighR, look.thighR * 0.72);
      final ms = <_Muscle>[];
      void band(String g, V3 dir, {double from = 0.05, double to = 0.95}) {
        final w = _mw(g);
        if (w == 0) return;
        final pth = _band(thigh, ph, pk, look.thighR * 0.86, dir, perpT, from: from, to: to);
        if (pth != null) ms.add(_Muscle(g, w, pth));
      }
      band('quadriceps', ant, from: 0.1, to: 0.92);
      band('posterior', ant * -1, from: 0.08, to: 0.9);
      // adutores (parte de dentro) e abdutores (parte de fora)
      final otherHip = _j(hj == Jt.hipN ? Jt.hipF : Jt.hipN);
      final inward = perpTo(otherHip - h, thighV);
      if (inward.length > 1.0) {
        band('adutores', inward.unit, from: 0.15, to: 0.85);
        band('abdutores', inward.unit * -1, from: -0.05, to: 0.5);
      } else if (_mw('abdutores') > 0) {
        ms.add(_Muscle('abdutores', _mw('abdutores'), Path()..addOval(Rect.fromCircle(center: ph + (pk - ph) * 0.12, radius: look.thighR * 1.0))));
      }
      final calf = capsule(pk, pa, look.calfR, look.calfR * 0.62);
      final cm = <_Muscle>[];
      if (_mw('panturrilha') > 0) {
        var back = perpTo(h - k, shinV); // atrás da canela: oposto à coxa dobrada
        back = back.length < 1.5 ? perpTo(front * -1, shinV) : back;
        if (back.length > 1e-3) {
          final pth = _band(calf, pk, pa, look.calfR * 0.9, back.unit, _perp3(k, a), from: 0.05, to: 0.7);
          if (pth != null) cm.add(_Muscle('panturrilha', _mw('panturrilha'), pth));
        }
      }
      parts.add(_Part(depthOf(h, k), thigh, look.bottom, muscles: ms, detail: (cv) {
        // faixa lateral da roupa
        final d = pk - ph;
        final len = d.distance;
        if (len < 1e-3) return;
        final u = d / len;
        final n = Offset(-u.dy, u.dx);
        final outward = _dir(perpTo(h - otherHip, thighV));
        final sg = (outward.dx * n.dx + outward.dy * n.dy) >= 0 ? 1.0 : -1.0;
        cv.save();
        cv.clipPath(thigh);
        cv.drawLine(ph + n * (look.thighR * 0.8 * sg), pk + n * (look.thighR * 0.62 * sg), Paint()
          ..color = look.accent
          ..strokeWidth = 1.0);
        cv.restore();
      }));
      parts.add(_Part(depthOf(k, a), calf, look.male ? look.skin : look.bottom, muscles: cm, detail: (cv) {
        if (look.male) return;
        // legging: faixa continua na canela
        final d = pa - pk;
        final len = d.distance;
        if (len < 1e-3) return;
        final u = d / len;
        final n = Offset(-u.dy, u.dx);
        final outward = _dir(perpTo(h - otherHip, shinV));
        final sg = (outward.dx * n.dx + outward.dy * n.dy) >= 0 ? 1.0 : -1.0;
        cv.save();
        cv.clipPath(calf);
        cv.drawLine(pk + n * (look.calfR * 0.7 * sg), pa + n * (look.calfR * 0.5 * sg), Paint()
          ..color = look.accent
          ..strokeWidth = 0.9);
        cv.restore();
      }));
      // tênis
      final fd = pt - pa;
      final fl = fd.distance;
      final fu = fl < 1e-3 ? const Offset(1, 0) : fd / fl;
      final shoe = capsule(pa - fu * 1.5, pt + fu * 0.5, look.calfR * 0.72, look.calfR * 0.6);
      parts.add(_Part(depthOf(a, t) + 0.1, shoe, Colors.white, detail: (cv) {
        cv.save();
        cv.clipPath(shoe);
        final n = Offset(-fu.dy, fu.dx);
        // sola: lado do chão (para baixo na tela)
        final down = n.dy > 0 ? n : -n;
        cv.drawLine(pa - fu * 2 + down * (look.calfR * 0.45), pt + fu * 1 + down * (look.calfR * 0.45), Paint()
          ..color = look.accent
          ..strokeWidth = 1.2);
        cv.restore();
      }));
    }
    leg(Jt.hipN, Jt.kneeN, Jt.ankN, Jt.toeN);
    leg(Jt.hipF, Jt.kneeF, Jt.ankF, Jt.toeF);
    return parts;
  }

  void _face(Canvas cv, Offset c, double r, double fx, double fz, Offset uS, Offset rS) {
    final look = _look;
    final fzc = fz.clamp(0.0, 1.0);
    // quanto o rosto está de frente (1) ou de perfil (0)
    final frontal = math.sqrt(math.max(0.0, 1 - fx * fx)) * fzc;
    final eyeLine = c + uS * (r * 0.05);
    final spread = r * 0.38 * (0.25 + 0.75 * frontal);
    final shift = rS * (fx * r * 0.42); // os traços andam para o lado que o rosto olha
    final eyeW = r * 0.3 * (0.6 + 0.4 * frontal), eyeH = r * 0.34;
    for (final sg in const [-1.0, 1.0]) {
      // de perfil só aparece o olho da frente (o do lado para onde olha)
      final isFrontEye = sg * fx >= 0;
      if (fx.abs() > 0.6 && !isFrontEye) continue;
      final e = eyeLine + shift + rS * (spread * sg);
      cv.drawOval(Rect.fromCenter(center: e, width: eyeW, height: eyeH), Paint()..color = Colors.white);
      cv.drawOval(Rect.fromCenter(center: e, width: eyeW, height: eyeH), Paint()
        ..color = look.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45);
      final iris = e + rS * (fx * eyeW * 0.22);
      cv.drawCircle(iris, eyeH * 0.3, Paint()..color = look.male ? const Color(0xFF4A3421) : const Color(0xFF2F6B3A));
      cv.drawCircle(iris, eyeH * 0.16, Paint()..color = look.outline);
      cv.drawCircle(iris + rS * (eyeH * 0.1) + uS * (eyeH * 0.1), eyeH * 0.07, Paint()..color = Colors.white);
      // sobrancelha
      final bw = eyeW * 0.6;
      final b0 = e + uS * (eyeH * 0.85) - rS * (bw * sg), b1 = e + uS * (eyeH * (look.male ? 0.9 : 1.0)) + rS * (bw * sg);
      cv.drawLine(b0, b1, Paint()
        ..color = look.hair
        ..strokeWidth = look.male ? 0.9 : 0.6
        ..strokeCap = StrokeCap.round);
      if (!look.male) {
        // cílio no canto de fora
        final tip = e + uS * (eyeH * 0.45) + rS * (eyeW * 0.55 * sg);
        cv.drawLine(tip, tip + uS * (eyeH * 0.3) + rS * (eyeW * 0.25 * sg), Paint()
          ..color = look.outline
          ..strokeWidth = 0.5
          ..strokeCap = StrokeCap.round);
      }
    }
    // nariz: no meio do rosto, de perfil fica na borda do lado para onde olha
    final noseTop = c - uS * (r * 0.1) + rS * (fx * r * (0.35 + 0.55 * (1 - frontal)));
    final noseTip = noseTop - uS * (r * 0.26) + rS * (fx.sign * r * 0.1 * (1 - frontal) + fx * r * 0.05);
    cv.drawLine(noseTop, noseTip, Paint()
      ..color = look.outline.withAlpha(170)
      ..strokeWidth = 0.65
      ..strokeCap = StrokeCap.round);
    // boca: sorriso leve; na parte pesada do movimento, boca apertada
    final mouth = c - uS * (r * 0.5) + rS * (fx * r * 0.4);
    final mw = r * 0.3 * (0.35 + 0.65 * frontal) + r * 0.08;
    final effort = _pulse > 0.72 && style.showMuscles && style.primary.isNotEmpty;
    final curve = r * (effort ? 0.04 : 0.14);
    final m0 = mouth - rS * mw, m1 = mouth + rS * mw;
    final ctrl = mouth - uS * curve;
    cv.drawPath(Path()
      ..moveTo(m0.dx, m0.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, m1.dx, m1.dy), Paint()
      ..color = look.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round);
    if (!look.male) {
      // bochechas coradas
      for (final sg in const [-1.0, 1.0]) {
        if (fx.abs() > 0.6 && sg * fx < 0) continue;
        cv.drawCircle(c - uS * (r * 0.28) + shift + rS * (spread * 1.15 * sg), r * 0.12, Paint()..color = const Color(0x55FF6B81));
      }
    } else if (fz > 0.1) {
      // barba por fazer no queixo
      cv.save();
      cv.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      cv.drawOval(Rect.fromCenter(center: c - uS * (r * 0.66) + rS * (fx * r * 0.3), width: r * 1.4 * (0.5 + 0.5 * frontal), height: r * 0.7),
          Paint()..color = look.hair.withAlpha(40));
      cv.restore();
    }
    // gota de suor na têmpora, na parte pesada do movimento
    if (effort) {
      final d = c + uS * (r * 0.5) + rS * (-fx.sign * r * 0.95);
      cv.drawPath(
          Path()
            ..moveTo(d.dx, d.dy - r * 0.35)
            ..quadraticBezierTo(d.dx + r * 0.3, d.dy + r * 0.1, d.dx, d.dy + r * 0.2)
            ..quadraticBezierTo(d.dx - r * 0.3, d.dy + r * 0.1, d.dx, d.dy - r * 0.35)
            ..close(),
          Paint()..color = const Color(0xFF6EC1FF));
    }
  }

  void _patch(Canvas c, Path part, _Muscle m) {
    final primary = m.weight >= 1;
    final base = primary ? _shadeC(primaryColor, 0.10 * _pulse) : secondaryColor;
    c.save();
    c.clipPath(part);
    final region = m.path;
    c.drawPath(region, Paint()..color = base.withAlpha(primary ? 245 : 225));
    // linha de separação no meio (peitoral, abdome, costas)
    if (m.split != null) {
      final b = region.getBounds();
      final n = Offset(-m.split!.dy, m.split!.dx);
      c.drawLine(b.center + n * b.height, b.center - n * b.height, Paint()
        ..color = _shadeC(base, -0.22).withAlpha(160)
        ..strokeWidth = 0.6);
    }
    c.drawPath(region, Paint()
      ..color = _shadeC(base, -0.25).withAlpha(primary ? 200 : 140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55);
    c.restore();
  }

  /// Corpo inteiro / cardio: brilho pulsante em volta do boneco.
  void _glow(Canvas c, List<_Part> parts) {
    final all = Path();
    for (final p in parts) {
      if (p.mesh == null) all.addPath(p.path, Offset.zero);
    }
    c.drawPath(all, Paint()
      ..color = primaryColor.withAlpha((120 + 100 * _pulse).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + 1.2 * _pulse
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
  }

  static Color _shadeC(Color c, double k) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + k).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant CartoonPainter old) =>
      old.time != time || old.clip != clip || old.yaw != yaw || old.style != style || old.palette != palette || old.showFloor != showFloor;
}

class _Muscle {
  const _Muscle(this.group, this.weight, this.path, {this.split});
  final String group;
  final double weight; // 1 principal, 0.5 auxiliar
  final Path path;
  final Offset? split;
}

class _Part {
  _Part(this.depth, this.path, this.color, {this.muscles = const [], this.detail, this.over}) : mesh = null;
  _Part.mesh(this.depth, this.mesh)
      : path = Path(),
        color = Colors.transparent,
        muscles = const [],
        detail = null,
        over = null;

  final double depth;
  final Path path;
  final Color color;
  final List<_Muscle> muscles;
  final void Function(Canvas)? detail;
  final void Function(Canvas)? over;
  final Mesh? mesh;
}

/// Aparência do boneco (medidas em unidades da cena, como o modelo 3D).
class _Look {
  const _Look({
    required this.male,
    required this.skin,
    required this.top,
    required this.bottom,
    required this.hair,
    required this.accent,
    required this.outline,
    required this.headR,
    required this.shoulderW,
    required this.chestD,
    required this.waistW,
    required this.waistD,
    required this.hipW,
    required this.hipD,
    required this.armR,
    required this.thighR,
    required this.calfR,
  });

  final bool male;
  final Color skin, top, bottom, hair, accent, outline;
  final double headR, shoulderW, chestD, waistW, waistD, hipW, hipD, armR, thighR, calfR;

  static const man = _Look(
    male: true,
    skin: Color(0xFFD69A72),
    top: Color(0xFF2458E6),
    bottom: Color(0xFF2A2F3A),
    hair: Color(0xFF2A1C14),
    accent: Color(0xFFF5B700),
    outline: Color(0xFF23252B),
    headR: 7.6,
    shoulderW: 12.4,
    chestD: 6.4,
    waistW: 9.0,
    waistD: 5.6,
    hipW: 8.8,
    hipD: 6.0,
    armR: 3.5,
    thighR: 4.6,
    calfR: 3.5,
  );

  static const woman = _Look(
    male: false,
    skin: Color(0xFFE0A47E),
    top: Color(0xFF2458E6),
    bottom: Color(0xFF2A2F3A),
    hair: Color(0xFF3A2416),
    accent: Color(0xFFF5B700),
    outline: Color(0xFF23252B),
    headR: 7.4,
    shoulderW: 10.2,
    chestD: 6.2,
    waistW: 7.2,
    waistD: 5.2,
    hipW: 9.6,
    hipD: 6.4,
    armR: 2.9,
    thighR: 4.4,
    calfR: 3.2,
  );
}
