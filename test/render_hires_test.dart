import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  }, skip: !enabled);
}
