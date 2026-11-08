import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/main.dart';
import 'package:gm_fitness/models/exercise.dart';
import 'package:gm_fitness/models/workout_entry.dart';
import 'package:gm_fitness/motion/motion_clip.dart';
import 'package:gm_fitness/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalize remove acentos', () {
    expect(normalize('Elevação Pélvica'), 'elevacao pelvica');
  });

  test('formatKg', () {
    expect(formatKg(10), '10 kg');
    expect(formatKg(12.5), '12,5 kg');
  });

  test('animações: todos os quadros com o mesmo tamanho e segmentos com comprimento estável', () {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    expect(lib.clips.length, greaterThan(60));
    for (final clip in lib.clips.values) {
      final n = clip.valuesPerFrame;
      expect(clip.frames.every((f) => f.length == n), isTrue, reason: clip.id);
      // comprimento do tronco (quadril -> pescoço) é sempre 30 unidades
      for (final f in clip.frames) {
        final dx = f[Jt.neck * 2] - f[Jt.hip * 2];
        final dy = f[Jt.neck * 2 + 1] - f[Jt.hip * 2 + 1];
        expect((dx * dx + dy * dy), closeTo(900, 12), reason: clip.id);
      }
      final s = clip.sample(0.37);
      expect(s.length, n);
    }
  });

  test('estado: carrega catálogo, aplica plano e registra carga', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    expect(state.allExercises.length, greaterThan(80));
    for (final e in state.allExercises) {
      expect(state.clipFor(e), isNotNull, reason: e.id);
    }
    final preset = state.presets.firstWhere((p) => p.id == 'triangulo_invertido');
    final n = await state.applyPreset(preset, replace: true);
    expect(n, greaterThan(15));
    final first = state.entries.first;
    await state.setLoad(first.id, 12.5);
    expect(state.entry(first.id)!.loadKg, 12.5);
    expect(state.entry(first.id)!.history.last.kg, 12.5);

    final custom = await state.saveCustom(
      name: 'Meu exercício',
      group: 'gluteos',
      equipment: 'elastico',
      level: 'iniciante',
      anim: 'glute_bridge',
      steps: const ['Passo 1'],
      tips: const [],
    );
    expect(state.exercise(custom.id)?.custom, isTrue);
    await state.deleteCustom(custom.id);
    expect(state.exercise(custom.id), isNull);
  });

  testWidgets('abre o app e mostra as abas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GmFitnessApp());
    for (var i = 0; i < 40 && find.byType(NavigationBar).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Meus treinos'), findsWidgets);
    expect(find.text('Exercícios'), findsOneWidget);
    expect(find.text('Planos'), findsOneWidget);
  });
}
