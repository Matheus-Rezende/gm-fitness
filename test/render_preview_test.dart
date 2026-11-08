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
    final ids = lib.clips.keys.toList()..sort();
    const tileW = 240.0, tileH = 195.0, cols = 4;
    const perSheet = 12;
    Directory('build/previews').createSync(recursive: true);
    for (var s = 0; s * perSheet < ids.length; s++) {
      final chunk = ids.skip(s * perSheet).take(perSheet).toList();
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      for (var r = 0; r < chunk.length; r++) {
        final clip = lib[chunk[r]]!;
        for (var c = 0; c < cols; c++) {
          canvas.save();
          canvas.translate(c * tileW, r * tileH);
          FigurePainter(clip: clip, time: c / cols, palette: FigurePalette.light).paint(canvas, const Size(tileW, tileH));
          canvas.restore();
        }
      }
      final pic = rec.endRecording();
      final img = await pic.toImage((tileW * cols).toInt(), (tileH * chunk.length).toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/previews/sheet_${s.toString().padLeft(2, '0')}.txt').writeAsStringSync(chunk.join('\n'));
      File('build/previews/sheet_${s.toString().padLeft(2, '0')}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: !enabled);
}
