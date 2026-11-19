import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/models/plan.dart';
import 'package:gm_fitness/models/split_templates.dart';
import 'package:gm_fitness/models/training.dart';
import 'package:gm_fitness/models/workout_entry.dart';

void main() {
  final catalog = {
    for (final e in (jsonDecode(File('assets/exercises.json').readAsStringSync())['exercises'] as List))
      (e as Map)['id'] as String,
  };

  test('todas as divisões prontas usam exercícios do catálogo', () {
    for (final t in splitTemplates) {
      for (final d in t.days) {
        for (final it in d.items) {
          expect(catalog, contains(it.exercise), reason: '${t.id}: ${it.exercise}');
          final swap = beginnerSwaps[it.exercise];
          if (swap != null) expect(catalog, contains(swap), reason: 'troca de ${it.exercise}');
        }
      }
      for (final level in TrainLevel.values) {
        final items = planTemplate(t, level, exists: catalog.contains);
        for (var s = 0; s < t.days.length; s++) {
          expect(items.where((i) => i.slot == s).length, greaterThanOrEqualTo(4), reason: '${t.id} ${level.name} $s');
        }
        if (level == TrainLevel.advanced) {
          expect(items.where((i) => i.technique == Technique.dropset).length, t.days.length);
        }
      }
    }
  });

  test('1RM pelas fórmulas de Epley e Brzycki', () {
    expect(epley1rm(100, 10), closeTo(133.3, 0.1));
    expect(brzycki1rm(100, 10), closeTo(133.3, 0.1));
    expect(estimate1rm(80, 1), 80);
    expect(estimate1rm(0, 10), 0);
    expect(roundLoad(41.3), 41);
    expect(roundLoad(7.3), 7.5);
  });

  test('pirâmide crescente aumenta a carga e diminui as repetições', () {
    final p = pyramid(up: true, kg: 40, sets: 4);
    expect(p.map((s) => s.repsNumber), [12, 10, 8, 6]);
    expect(p[1].kg, 40);
    expect(p.first.kg, lessThan(p.last.kg));
    final d = pyramid(up: false, kg: 40, sets: 4);
    expect(d.first.repsNumber, 6);
  });

  test('exercício personalizado vai e volta do JSON', () {
    const e = WorkoutEntry(
      id: 'e1',
      exerciseId: 'rosca_direta_barra',
      weekday: 1,
      technique: Technique.dropset,
      cadence: '3-0-1',
      rir: 1,
      note: 'pegada fechada',
      setPlan: [SetSpec(reps: '12', kg: 10, warmup: true), SetSpec(reps: '10', kg: 20)],
    );
    final back = WorkoutEntry.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);
    expect(back.technique, Technique.dropset);
    expect(back.cadence, '3-0-1');
    expect(back.rir, 1);
    expect(back.note, 'pegada fechada');
    expect(back.totalSets, 2);
    expect(back.setPlan.first.warmup, isTrue);
    expect(back.setsSummary, '1 aquec. + 10×20');
    // dados antigos continuam válidos
    final old = WorkoutEntry.fromJson({'id': 'x', 'exerciseId': 'agachamento_livre', 'weekday': 2, 'sets': 3});
    expect(old.technique, Technique.normal);
    expect(old.rir, -1);
    expect(old.hasSetPlan, isFalse);
  });

  test('plano de divisão vai e volta do JSON', () {
    const p = TrainingPlan(mode: PlanMode.split, count: 4, names: {0: 'Peito'}, trainDays: {0, 1, 3, 4});
    final back = TrainingPlan.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(back.isSplit, isTrue);
    expect(back.count, 4);
    expect(back.slotLabel(1), 'Treino B');
    expect(back.fullLabel(0), 'Treino A · Peito');
    expect(back.trainDays, {0, 1, 3, 4});
    expect(splitName(5), 'ABCDE');
    expect(const TrainingPlan().slotLabel(2), 'Quarta');
  });
}
