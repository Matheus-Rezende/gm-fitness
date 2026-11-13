import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/motion/cartoon_painter.dart';
import 'package:gm_fitness/motion/figure_painter.dart';
import 'package:gm_fitness/motion/motion_clip.dart';

/// Quadros grandes de alguns exercícios em build/hires/ (só com
/// RENDER_PREVIEWS=1), para conferir detalhes do boneco.
void main() {
  final enabled = Platform.environment['RENDER_PREVIEWS'] == '1';
  test('quadros grandes', () async {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    final catalog = jsonDecode(File('assets/exercises.json').readAsStringSync()) as Map<String, dynamic>;
    final groups = <String, (String, List<String>)>{};
    for (final e in (catalog['exercises'] as List)) {
      final m = e as Map<String, dynamic>;
      groups.putIfAbsent(
          m['anim'] as String, () => (m['group'] as String, [for (final g in m['secondary'] as List) g as String]));
    }
    const picks = [
      ('squat_bb', true), ('bench_press', false), ('deadlift', true), ('push_up', false), ('curl', true),
      ('hip_thrust', false), ('lunge_db', true), ('lat_pulldown', false), ('bench_dip', true), ('plank', false),
      ('crunch', true), ('bird_dog', false), ('superman', true), ('one_arm_row', true), ('donkey_kick', false),
      ('calf_raise', true),
    ];
    const w = 360.0, h = 292.0;
    Directory('build/hires').createSync(recursive: true);
    for (final (id, male) in picks) {
      final clip = lib[id]!;
      final g = groups[id];
      final style = FigureStyle(male: male, primary: g == null ? const {} : {g.$1}, secondary: g?.$2.toSet() ?? const {});
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final y0 = clip.defaultYaw;
      final shots = [(clip.keyTimes[2], y0), (clip.keyTimes[1], y0 + 40), (clip.keyTimes[2], y0 == 0 ? 120.0 : 200.0)];
      for (var c = 0; c < 3; c++) {
        canvas.save();
        canvas.translate(c * w, 0);
        FigurePainter(clip: clip, time: shots[c].$1, palette: FigurePalette.light, style: style, yaw: shots[c].$2)
            .paint(canvas, const Size(w, h));
        canvas.restore();
      }
      final img = await rec.endRecording().toImage((w * 3).toInt(), h.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/hires/$id.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
    // sequência no tempo, para ver se os pés ficam firmes
    for (final id in const ['bird_dog', 'superman', 'one_arm_row', 'donkey_kick', 'bicycle_crunch', 'deadlift', 'reverse_fly', 'lateral_raise', 'sumo_squat', 'hip_abduction_standing', 'jump_rope', 'leg_curl_lying', 'pull_up']) {
      final clip = lib[id]!;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      for (var c = 0; c < 6; c++) {
        canvas.save();
        canvas.translate(c * 240.0, 0);
        FigurePainter(
                clip: clip,
                time: c / 6,
                palette: FigurePalette.light,
                style: const FigureStyle(male: true),
                yaw: clip.defaultYaw + 35)
            .paint(canvas, const Size(240, 195));
        canvas.restore();
      }
      final img = await rec.endRecording().toImage(1440, 195);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/hires/seq_$id.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: !enabled);

  test('braços e pernas em quadros grandes', () async {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    final ids = (Platform.environment['REVIEW_IDS'] ?? '').split(',').where((e) => e.isNotEmpty).toList();
    final list = ids.isNotEmpty ? ids : (lib.clips.keys.toList()..sort());
    Directory('build/arms').createSync(recursive: true);
    const tw = 420.0, th = 340.0;
    for (final id in list) {
      final clip = lib[id]!;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      for (var c = 0; c < 3; c++) {
        canvas.save();
        canvas.translate(c * tw, 0);
        FigurePainter(
                clip: clip,
                time: const [0.0, 0.3, 0.55][c],
                palette: FigurePalette.light,
                style: const FigureStyle(male: true, showPath: false),
                ghost: false,
                yaw: clip.defaultYaw + (c == 2 ? 60 : 25))
            .paint(canvas, const Size(tw, th));
        canvas.restore();
      }
      final img = await rec.endRecording().toImage((tw * 3).toInt(), th.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/arms/$id.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: !enabled);

  test('boneco 2D: folhas de revisão', () async {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    Directory('build/cartoon').createSync(recursive: true);
    const tw = 300.0, th = 240.0;
    // quadro grande por exercício, 4 vistas, homem (linha 1) e mulher (linha 2)
    const ids = ['squat_bw', 'bench_press', 'curl', 'crunch', 'lat_pulldown', 'plank', 'deadlift', 'lateral_raise',
      'lunge_db', 'hip_thrust', 'push_up', 'calf_raise', 'leg_press', 'seated_row', 'bird_dog', 'walk'];
    const views = [0.0, 45.0, 90.0, 270.0];
    final groups = <String, (Set<String>, Set<String>)>{
      'squat_bw': ({'quadriceps'}, {'gluteos', 'posterior'}),
      'bench_press': ({'peito'}, {'triceps', 'ombros'}),
      'curl': ({'biceps'}, {'antebraco'}),
      'crunch': ({'abdomen'}, {}),
      'lat_pulldown': ({'costas'}, {'biceps'}),
      'plank': ({'abdomen'}, {'lombar', 'ombros'}),
      'deadlift': ({'posterior'}, {'gluteos', 'lombar'}),
      'lateral_raise': ({'ombros'}, {'trapezio'}),
      'lunge_db': ({'quadriceps'}, {'gluteos'}),
      'hip_thrust': ({'gluteos'}, {'posterior'}),
      'push_up': ({'peito'}, {'triceps'}),
      'calf_raise': ({'panturrilha'}, {}),
      'leg_press': ({'quadriceps'}, {'gluteos'}),
      'seated_row': ({'costas'}, {'biceps'}),
      'bird_dog': ({'lombar'}, {'gluteos', 'abdomen'}),
      'walk': ({'cardio'}, {}),
    };
    for (final id in ids) {
      final clip = lib[id];
      if (clip == null) continue;
      final g = groups[id] ?? (<String>{}, <String>{});
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      for (var r = 0; r < 2; r++) {
        for (var c = 0; c < views.length; c++) {
          canvas.save();
          canvas.translate(c * tw, r * th);
          CartoonPainter(
            clip: clip,
            time: c == 1 ? clip.keyTimes[1] : 0.3,
            palette: FigurePalette.light,
            style: FigureStyle(male: r == 0, primary: g.$1, secondary: g.$2, showPath: c == 0),
            yaw: views[c],
          ).paint(canvas, const Size(tw, th));
          canvas.restore();
        }
      }
      final img = await rec.endRecording().toImage((tw * views.length).toInt(), (th * 2).toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/cartoon/$id.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: !enabled);

  test('revisão de todos os movimentos', () async {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    final ids = lib.clips.keys.toList()..sort();
    Directory('build/review').createSync(recursive: true);
    const tw = 220.0, th = 180.0, cols = 6, per = 8;
    for (var s = 0; s * per < ids.length; s++) {
      final chunk = ids.skip(s * per).take(per).toList();
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      for (var r = 0; r < chunk.length; r++) {
        final clip = lib[chunk[r]]!;
        for (var c = 0; c < cols; c++) {
          canvas.save();
          canvas.translate(c * tw, r * th);
          FigurePainter(
                  clip: clip,
                  time: c / cols,
                  palette: FigurePalette.light,
                  style: FigureStyle(male: s.isEven, showPath: false),
                  ghost: false,
                  yaw: clip.defaultYaw + 30)
              .paint(canvas, const Size(tw, th));
          canvas.restore();
        }
      }
      final img = await rec.endRecording().toImage((tw * cols).toInt(), (th * chunk.length).toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final name = 'r_${s.toString().padLeft(2, '0')}';
      File('build/review/$name.txt').writeAsStringSync(chunk.join('\n'));
      File('build/review/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: !enabled);
}
