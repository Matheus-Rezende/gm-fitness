import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/main.dart';
import 'package:gm_fitness/models/body.dart';
import 'package:gm_fitness/models/exercise.dart';
import 'package:gm_fitness/models/session.dart';
import 'package:gm_fitness/models/workout_entry.dart';
import 'package:gm_fitness/motion/motion_clip.dart';
import 'package:gm_fitness/state/app_state.dart';
import 'package:gm_fitness/update/updater.dart';
import 'package:gm_fitness/version.dart';
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
        // comprimento do tronco (quadril -> pescoço) é sempre 30 unidades, em 3D
        final d = MotionClip.joint(f, Jt.neck) - MotionClip.joint(f, Jt.hip);
        expect(d.length, closeTo(30, 0.4), reason: clip.id);
        // braço: ombro -> cotovelo mantém 19 unidades
        final ua = MotionClip.joint(f, Jt.elbN) - MotionClip.joint(f, Jt.shN);
        expect(ua.length, closeTo(19, 0.6), reason: '${clip.id} braço');
        final th = MotionClip.joint(f, Jt.kneeN) - MotionClip.joint(f, Jt.hipN);
        expect(th.length, closeTo(25.5, 0.6), reason: '${clip.id} coxa');
      }
      // enquadramento funciona em qualquer ângulo
      for (final yaw in const [0.0, 45.0, 90.0, 180.0, 270.0]) {
        final b = clip.boundsFor(Camera(yaw));
        expect(b.width, greaterThan(10), reason: '${clip.id} $yaw');
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
    expect(male.where((p) => p.sex == 'M' && p.shape != 'iniciante').length, 5);
    expect(male.where((p) => p.shape == 'iniciante' && p.sex == 'M' && p.days.length == 5).length, 1);
    expect(male.any((p) => p.sex == 'F'), isFalse);
    expect(state.recommendedIds, isNotEmpty);

    await state.setProfile(sex: 'F');
    expect(state.presetsForUser.where((p) => p.sex == 'F' && p.shape != 'iniciante').length, 5);
    expect(state.presetsForUser.where((p) => p.shape == 'iniciante' && p.sex == 'F' && p.days.length == 5).length, 1);

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

  test('sessão: intensidade, cargas sugeridas e persistência', () async {
    expect(intensityOf(2), Intensity.light);
    expect(intensityOf(5), Intensity.moderate);
    expect(intensityOf(8), Intensity.high);
    expect(intensityOf(10), Intensity.veryHigh);
    expect(suggestLoad(10, Feel.easy, completed: true), 11);
    expect(suggestLoad(20, Feel.easy, completed: true), 22.5);
    expect(suggestLoad(10, Feel.right, completed: true), 10);
    expect(suggestLoad(10, Feel.hard, completed: true), 10);
    expect(suggestLoad(10, Feel.hard, completed: false), 9);
    expect(suggestLoad(0.5, Feel.hard, completed: false), 0);
    expect(suggestLoad(0, Feel.easy, completed: true), 0);
    expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '03:07');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');

    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    final ex = state.allExercises.first;
    final a = await state.addEntry(ex.id, weekday: 2, sets: 3, reps: '10', loadKg: 20);
    final b = await state.addEntry(ex.id, weekday: 2, sets: 2, reps: '30s', loadKg: 0);
    await state.startSession(2);
    expect(state.activeSession, isNotNull);
    await state.markSet(a.id, 5);
    expect(state.setsDoneFor(a.id), 3);
    await state.markSet(b.id, 1);
    await state.setFeel(a.id, Feel.easy);

    final again = await AppState.load();
    expect(again.activeSession?.weekday, 2);
    expect(again.setsDoneFor(a.id), 3);
    expect(again.activeSession?.feel[a.id], Feel.easy);

    final s = await state.finishSession(6);
    expect(s, isNotNull);
    expect(state.activeSession, isNull);
    expect(s!.setsDone, 4);
    expect(s.setsPlanned, 5);
    expect(s.volume, 3 * 10 * 20);
    expect(s.sessionLoad, greaterThanOrEqualTo(0));
    expect(state.sessions.first.id, s.id);
    expect(state.averageLoadBefore(s), isNull);

    final item = s.items.firstWhere((i) => i.entryId == a.id);
    await state.applyLoads({a.id: suggestLoad(item.loadKg, item.feel, completed: true)});
    expect(state.entry(a.id)?.loadKg, 22.5);

    final reloaded = await AppState.load();
    expect(reloaded.sessions.length, 1);
    expect(reloaded.sessions.first.rpe, 6);
    expect(reloaded.activeSession, isNull);
  });

  test('versão do app igual à do pubspec', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(line.split(':')[1].trim().split('+').first, kAppVersion);
  });

  test('atualização: comparação de versões e leitura da Release', () {
    expect(compareVersions('0.5.0', '0.4.0'), greaterThan(0));
    expect(compareVersions('v0.10.0', '0.9.9'), greaterThan(0));
    expect(compareVersions('1.0.0+7', '1.0.0'), 0);
    expect(compareVersions('0.4.1', '0.5'), lessThan(0));
    final info = parseRelease({
      'tag_name': 'v0.6.0',
      'draft': false,
      'prerelease': false,
      'body': '- Novidade A\r\n- Novidade B\r\n\r\n## Como instalar no Android\r\n1. Baixe',
      'assets': [
        {'name': 'notas.txt', 'browser_download_url': 'https://x/notas.txt', 'size': 10},
        {'name': 'gm-fitness-v0.6.0.apk', 'browser_download_url': 'https://x/app.apk', 'size': 52428800},
      ],
    });
    expect(info, isNotNull);
    expect(info!.version, '0.6.0');
    expect(info.apkUrl, 'https://x/app.apk');
    expect(info.notes, '- Novidade A\n- Novidade B');
    expect(info.sizeLabel, '50 MB');
    expect(parseRelease({'tag_name': 'v1.0.0', 'assets': []}), isNull);
    expect(parseRelease({'tag_name': 'v1.0.0', 'prerelease': true, 'assets': []}), isNull);
  });

  test('corpo: IMC, calorias, proteína e previsão', () {
    final now = DateTime(2026, 11, 9);
    final data = BodyData(
      birthYear: 1996,
      heightCm: 165,
      targetKg: 70,
      goal: Goal.loseFat,
      activity: Activity.sedentary,
      waistCm: 90,
    );
    final m = BodyMetrics.compute(data: data, weightKg: 80, sex: 'F', trainingDays: 3, now: now);
    expect(m.age, 30);
    expect(m.adult, isTrue);
    expect(m.bmi!, closeTo(29.38, 0.01));
    expect(m.bmiLabel, 'Sobrepeso');
    expect(m.bmr, 1520);
    expect(m.tdee, 1950);
    expect(m.calories, 1550);
    expect(m.proteinG, 125);
    expect(m.weeklyChangeKg!, closeTo(-0.6, 0.001));
    expect(m.weeksToTarget, 17);
    expect(m.waistToHeight!, closeTo(0.545, 0.001));
    expect(m.waterL!, closeTo(2.8, 0.001));

    final gain = BodyMetrics.compute(
      data: data.copyWith(goal: Goal.gainMuscle, clearTarget: true),
      weightKg: 60,
      sex: 'M',
      now: now,
    );
    expect(gain.calories! > gain.tdee!, isTrue);
    expect(gain.weeklyChangeKg! > 0, isTrue);
    expect(gain.weeksToTarget, isNull);

    // meta na direção errada não gera previsão
    final wrong = BodyMetrics.compute(data: data.copyWith(targetKg: 90), weightKg: 80, sex: 'F', now: now);
    expect(wrong.weeksToTarget, isNull);

    // menor de idade: sem calorias nem metas
    final teen = BodyMetrics.compute(data: data.copyWith(birthYear: 2011), weightKg: 60, sex: 'F', now: now);
    expect(teen.adult, isFalse);
    expect(teen.calories, isNull);
    expect(teen.bmi, isNotNull);

    expect(targetProblem(45, 170), isNotNull);
    expect(targetProblem(60, 170), isNull);
    expect(bmiClass(17), 'Abaixo do peso');
    expect(bmiClass(22), 'Peso adequado');
    expect(bmiClass(41), 'Obesidade grau III');
    expect(actionTips(Goal.loseFat, m).any((t) => t.contains('1550 kcal')), isTrue);
  });

  test('estado: corpo e pesagens são salvos', () async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    expect(state.currentWeight, isNull);
    await state.setBody(const BodyData(birthYear: 1990, heightCm: 180, goal: Goal.gainMuscle));
    await state.addWeight(75, DateTime(2026, 10, 1, 8));
    await state.addWeight(76, DateTime(2026, 10, 8, 8));
    await state.addWeight(76.4, DateTime(2026, 10, 8, 20)); // mesmo dia substitui
    expect(state.weights.length, 2);
    expect(state.currentWeight, 76.4);
    expect(state.startWeight, 75);
    expect(state.metrics.bmi, isNotNull);

    final again = await AppState.load();
    expect(again.body.goal, Goal.gainMuscle);
    expect(again.body.heightCm, 180);
    expect(again.weights.length, 2);
    await again.removeWeight(again.weights.first);
    expect(again.weights.single.kg, 76.4);
    await again.clearAll();
    expect(again.weights, isEmpty);
    expect(again.body.goal, isNull);
  });

  testWidgets('introdução completa com dados do corpo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GmFitnessApp());
    await _pumpUntil(tester, find.text('Começar'));

    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tap(find.text('Começar'));
    await tap(find.text('Feminino'));
    await tap(find.text('Continuar'));
    expect(find.text('Sobre você'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Idade'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, 'Altura'), '165');
    await tester.enterText(find.widgetWithText(TextFormField, 'Peso atual'), '80');
    await tester.pump();
    await tap(find.text('Continuar').last);
    expect(find.text('Qual é o seu objetivo?'), findsOneWidget);
    await tap(find.text('Emagrecer'));
    await tap(find.text('Pouco ativo'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Peso que quer alcançar (opcional)'), '70');
    await tester.pump();
    await tap(find.text('Continuar').last);
    expect(find.text('Seu ponto de partida'), findsOneWidget);
    expect(find.text('Sobrepeso'), findsOneWidget);
    await tap(find.text('Escolher meu treino'));
    await tap(find.text('Nunca treinei ou não sei meu formato'));
    await _pumpUntil(tester, find.byType(NavigationBar));
    final tab = find.descendant(of: find.byType(NavigationBar), matching: find.text('Evolução'));
    expect(tab, findsOneWidget);
    await tap(tab);
    expect(find.text('Seus números'), findsOneWidget);
    expect(find.text('Emagrecer'), findsWidgets);
    expect(tester.takeException(), isNull);
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
