import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/motion/figure_painter.dart';
import 'package:gm_fitness/motion/motion_clip.dart';

/// Gera folhas de contato das animações em build/previews/ (só com
/// RENDER_PREVIEWS=1). Serve para conferir o desenho fora do aparelho.
void main() {
  final enabled = Platform.environment['RENDER_PREVIEWS'] == '1';

  test('renderiza prévias', () async {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    final catalog = jsonDecode(File('assets/exercises.json').readAsStringSync()) as Map<String, dynamic>;
    final groups = <String, (String, List<String>)>{};
    for (final e in (catalog['exercises'] as List)) {
      final m = e as Map<String, dynamic>;
      groups.putIfAbsent(
          m['anim'] as String, () => (m['group'] as String, [for (final g in m['secondary'] as List) g as String]));
    }
    final ids = lib.clips.keys.toList()..sort();
    const tileW = 240.0, tileH = 195.0, cols = 4;
    const perSheet = 12;
    Directory('build/previews').createSync(recursive: true);
    for (final male in [false, true]) {
      for (var s = 0; s * perSheet < ids.length; s++) {
        final chunk = ids.skip(s * perSheet).take(perSheet).toList();
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        for (var r = 0; r < chunk.length; r++) {
          final clip = lib[chunk[r]]!;
          final g = groups[clip.id];
          final style = FigureStyle(
            male: male,
            primary: g == null ? const {} : {g.$1},
            secondary: g == null ? const {} : g.$2.toSet(),
          );
          final times = [0.0, clip.keyTimes[1], clip.keyTimes[2], 0.5];
          for (var c = 0; c < cols; c++) {
            canvas.save();
            canvas.translate(c * tileW, r * tileH);
            FigurePainter(clip: clip, time: times[c], palette: FigurePalette.light, style: style)
                .paint(canvas, const Size(tileW, tileH));
            canvas.restore();
          }
        }
        final pic = rec.endRecording();
        final img = await pic.toImage((tileW * cols).toInt(), (tileH * chunk.length).toInt());
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        final name = '${male ? 'm' : 'f'}_${s.toString().padLeft(2, '0')}';
        File('build/previews/$name.txt').writeAsStringSync(chunk.join('\n'));
        File('build/previews/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    }
  }, skip: !enabled);
}
