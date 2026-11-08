import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/main.dart';
import 'package:gm_fitness/models/exercise.dart';
import 'package:gm_fitness/models/workout_entry.dart';
import 'package:gm_fitness/motion/motion_clip.dart';
import 'package:gm_fitness/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalize remove acentos', () {
    expect(normalize('Elevação Pélvica'), 'elevacao pelvica');
  });

  test('formatKg', () {
    expect(formatKg(10), '10 kg');
    expect(formatKg(12.5), '12,5 kg');
  });

  test('animações: quadros consistentes, tronco com comprimento fixo e poses-chave', () {
    final lib = MotionLibrary.parse(File('assets/motions.json').readAsStringSync());
    expect(lib.clips.length, greaterThan(60));
    for (final clip in lib.clips.values) {
      final n = clip.valuesPerFrame;
      expect(clip.frames.every((f) => f.length == n), isTrue, reason: clip.id);
      for (final f in clip.frames) {
        final dx = f[Jt.neck * 2] - f[Jt.hip * 2];
        final dy = f[Jt.neck * 2 + 1] - f[Jt.hip * 2 + 1];
        expect((dx * dx + dy * dy), closeTo(900, 12), reason: clip.id);
      }
      expect(clip.keyTimes.length, 3, reason: clip.id);
      expect(clip.keyPath.length, clip.frameCount, reason: clip.id);
      expect(clip.sample(0.37).length, n);
    }
  });

  test('estado: perfil, planos por gênero, carga e feitos', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    expect(state.allExercises.length, greaterThan(80));
    for (final e in state.allExercises) {
      expect(state.clipFor(e), isNotNull, reason: e.id);
    }

    await state.setProfile(sex: 'M');
    final male = state.presetsForUser;
    expect(male.where((p) => p.sex == 'M').length, 5);
    expect(male.any((p) => p.sex == 'F'), isFalse);
    expect(state.recommendedIds, isNotEmpty);

    await state.setProfile(sex: 'F');
    expect(state.presetsForUser.where((p) => p.sex == 'F').length, 5);

    final preset = state.presets.firstWhere((p) => p.id == 'triangulo_invertido');
    final n = await state.applyPreset(preset, replace: true);
    expect(n, greaterThan(15));
    expect(state.currentPreset?.id, 'triangulo_invertido');
    final first = state.entries.first;
    await state.setLoad(first.id, 12.5);
    expect(state.entry(first.id)!.loadKg, 12.5);
    expect(state.entry(first.id)!.history.last.kg, 12.5);

    await state.toggleDone(first.id);
    expect(state.isDone(first.id), isTrue);
    expect(state.weekActivity().where((d) => d).length, 1);
    await state.toggleDone(first.id);
    expect(state.isDone(first.id), isFalse);

    final squat = state.exercise('agachamento_livre')!;
    expect(squat.notesFor('F'), isNotEmpty);
    expect(squat.notesFor('M'), isNotEmpty);

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

  testWidgets('primeira abertura mostra o onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GmFitnessApp());
    await _pumpUntil(tester, find.text('Começar'));
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('com perfil salvo abre direto nas abas', (tester) async {
    SharedPreferences.setMockInitialValues({'profile_v1': '{"sex":"M","onboarded":true}'});
    await tester.pumpWidget(const GmFitnessApp());
    await _pumpUntil(tester, find.byType(NavigationBar));
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Exercícios'), findsOneWidget);
    expect(find.text('Planos'), findsOneWidget);
  });
}
