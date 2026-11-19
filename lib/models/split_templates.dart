import 'training.dart';

/// Nível de quem vai treinar, usado para montar séries, repetições e descanso.
enum TrainLevel { beginner, intermediate, advanced }

extension TrainLevelInfo on TrainLevel {
  String get label => switch (this) {
        TrainLevel.beginner => 'Iniciante',
        TrainLevel.intermediate => 'Intermediário',
        TrainLevel.advanced => 'Avançado',
      };

  String get who => switch (this) {
        TrainLevel.beginner => 'Até 6 meses de treino. Foco em aprender a técnica.',
        TrainLevel.intermediate => '6 meses a 2 anos de treino constante.',
        TrainLevel.advanced => 'Mais de 2 anos, com boa técnica nos exercícios livres.',
      };

  /// Resumo do que muda nas séries.
  String get dose => switch (this) {
        TrainLevel.beginner => 'Compostos 3 × 10–12 (1min30 de descanso), isolados 3 × 12–15 (1 min).',
        TrainLevel.intermediate => 'Compostos 4 × 8–10 (2 min), isolados 3 × 10–12 (1min15). Pare a 2 repetições da falha.',
        TrainLevel.advanced =>
          'Compostos 4 × 6–8 (2min30), isolados 4 × 8–12 (1min15), com drop-set no último isolado de cada treino.',
      };
}

/// Tipo do exercício dentro do modelo: define séries, repetições e descanso.
enum SlotKind {
  /// Multiarticular (agachamento, supino, remada...).
  compound,

  /// Monoarticular (rosca, extensora, elevação lateral...).
  isolation,

  /// Abdômen e lombar.
  core,
}

class TemplateItem {
  const TemplateItem(this.exercise, this.kind);

  final String exercise;
  final SlotKind kind;
}

class TemplateDay {
  const TemplateDay(this.name, this.items);

  final String name;
  final List<TemplateItem> items;
}

/// Divisão de treino pronta (Full body, AB, ABC, ABCD, ABCDE).
class SplitTemplate {
  const SplitTemplate({
    required this.id,
    required this.name,
    required this.summary,
    required this.description,
    required this.levels,
    required this.trainDays,
    required this.days,
  });

  final String id;
  final String name;
  final String summary;
  final String description;

  /// Níveis para os quais a divisão é indicada.
  final Set<TrainLevel> levels;

  /// Dias da semana sugeridos (0 = segunda).
  final Set<int> trainDays;
  final List<TemplateDay> days;

  String get letters => ['A', 'B', 'C', 'D', 'E', 'F'].take(days.length).join();
}

/// Uma linha pronta para virar exercício da lista.
class PlannedItem {
  const PlannedItem({
    required this.slot,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.rest,
    this.technique = Technique.normal,
    this.rir = -1,
  });

  final int slot;
  final String exercise;
  final int sets;
  final String reps;
  final int rest;
  final Technique technique;
  final int rir;
}

/// Trocas para iniciantes: exercícios livres mais técnicos viram versões guiadas.
const beginnerSwaps = {
  'supino_reto_barra': 'supino_reto_halteres',
  'supino_inclinado_barra': 'supino_inclinado_halteres',
  'agachamento_barra': 'agachamento_smith',
  'stiff_barra': 'stiff_halteres',
  'remada_curvada_barra': 'remada_curvada_halteres',
  'desenvolvimento_barra': 'desenvolvimento_halteres',
  'triceps_testa': 'triceps_polia',
  'barra_fixa': 'barra_fixa_assistida',
  'paralelas': 'triceps_banco',
  'levantamento_terra': 'stiff_halteres',
  'agachamento_bulgaro': 'afundo',
  'afundo_halteres': 'afundo',
  'elevacao_pelvica': 'ponte_gluteo',
  'crossover': 'voador',
  'face_pull': 'voador_invertido',
  'pulldown_bracos_estendidos': 'remada_sentada',
  'elevacao_pernas_barra': 'elevacao_pernas',
};

/// Monta as séries do modelo para o nível escolhido.
List<PlannedItem> planTemplate(SplitTemplate t, TrainLevel level, {bool Function(String id)? exists}) {
  final out = <PlannedItem>[];
  for (final (slot, day) in t.days.indexed) {
    final used = <String>{};
    final dayItems = <PlannedItem>[];
    final kinds = <SlotKind>[];
    for (final it in day.items) {
      var id = it.exercise;
      if (level == TrainLevel.beginner) id = beginnerSwaps[id] ?? id;
      if (used.contains(id) || (exists != null && !exists(id))) continue;
      used.add(id);
      final timed = id.startsWith('prancha') || id == 'agachamento_isometrico';
      final (sets, reps, rest) = switch ((it.kind, level)) {
        (SlotKind.compound, TrainLevel.beginner) => (3, '10-12', 90),
        (SlotKind.compound, TrainLevel.intermediate) => (4, '8-10', 120),
        (SlotKind.compound, TrainLevel.advanced) => (4, '6-8', 150),
        (SlotKind.isolation, TrainLevel.beginner) => (3, '12-15', 60),
        (SlotKind.isolation, TrainLevel.intermediate) => (3, '10-12', 75),
        (SlotKind.isolation, TrainLevel.advanced) => (4, '8-12', 75),
        (SlotKind.core, TrainLevel.beginner) => (3, timed ? '30s' : '15', 45),
        (SlotKind.core, TrainLevel.intermediate) => (3, timed ? '45s' : '15-20', 45),
        (SlotKind.core, TrainLevel.advanced) => (4, timed ? '60s' : '15-20', 45),
      };
      final rir = switch (level) {
        TrainLevel.beginner => -1,
        TrainLevel.intermediate => it.kind == SlotKind.core ? -1 : 2,
        TrainLevel.advanced => it.kind == SlotKind.compound ? 2 : (it.kind == SlotKind.isolation ? 1 : -1),
      };
      dayItems.add(PlannedItem(slot: slot, exercise: id, sets: sets, reps: reps, rest: rest, rir: rir));
      kinds.add(it.kind);
    }
    if (level == TrainLevel.advanced) {
      // drop-set no último exercício isolado do dia
      final i = kinds.lastIndexOf(SlotKind.isolation);
      if (i >= 0) {
        final p = dayItems[i];
        dayItems[i] = PlannedItem(
            slot: p.slot, exercise: p.exercise, sets: p.sets, reps: p.reps, rest: p.rest,
            technique: Technique.dropset, rir: 0);
      }
    }
    out.addAll(dayItems);
  }
  return out;
}

const _c = SlotKind.compound;
const _i = SlotKind.isolation;
const _k = SlotKind.core;

const splitTemplates = <SplitTemplate>[
  SplitTemplate(
    id: 'fullbody_ab',
    name: 'Corpo inteiro A/B',
    summary: '2 treinos alternados, 3 vezes por semana',
    description:
        'Cada treino trabalha o corpo todo, e você alterna A e B (A-B-A numa semana, B-A-B na outra). '
        'É a divisão recomendada para quem está começando: cada músculo treina 2 a 3 vezes por semana, '
        'com tempo para aprender bem os movimentos.',
    levels: {TrainLevel.beginner},
    trainDays: {0, 2, 4},
    days: [
      TemplateDay('Corpo inteiro', [
        TemplateItem('agachamento_goblet', _c),
        TemplateItem('supino_reto_halteres', _c),
        TemplateItem('remada_sentada', _c),
        TemplateItem('desenvolvimento_halteres', _c),
        TemplateItem('mesa_flexora', _i),
        TemplateItem('prancha', _k),
      ]),
      TemplateDay('Corpo inteiro', [
        TemplateItem('leg_press_45', _c),
        TemplateItem('puxada_frontal', _c),
        TemplateItem('supino_inclinado_halteres', _c),
        TemplateItem('stiff_halteres', _c),
        TemplateItem('elevacao_lateral', _i),
        TemplateItem('abdominal_supra', _k),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'upper_lower',
    name: 'AB: superiores e inferiores',
    summary: '2 treinos, 4 vezes por semana (A-B-descanso-A-B)',
    description:
        'A trabalha peito, costas, ombros e braços; B trabalha pernas, glúteos e abdômen. '
        'Treinando 4 vezes por semana, cada músculo é estimulado 2 vezes, a frequência que mais traz resultado '
        'para a maioria das pessoas.',
    levels: {TrainLevel.beginner, TrainLevel.intermediate},
    trainDays: {0, 1, 3, 4},
    days: [
      TemplateDay('Superiores', [
        TemplateItem('supino_reto_barra', _c),
        TemplateItem('puxada_frontal', _c),
        TemplateItem('desenvolvimento_halteres', _c),
        TemplateItem('remada_sentada', _c),
        TemplateItem('elevacao_lateral', _i),
        TemplateItem('rosca_direta_halteres', _i),
        TemplateItem('triceps_corda', _i),
      ]),
      TemplateDay('Inferiores e abdômen', [
        TemplateItem('agachamento_barra', _c),
        TemplateItem('leg_press_45', _c),
        TemplateItem('stiff_barra', _c),
        TemplateItem('cadeira_extensora', _i),
        TemplateItem('mesa_flexora', _i),
        TemplateItem('elevacao_pelvica', _c),
        TemplateItem('panturrilha_em_pe', _i),
        TemplateItem('prancha', _k),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'abc_ppl',
    name: 'ABC: empurrar, puxar e pernas',
    summary: '3 treinos; 3 dias (1× por semana) ou 6 dias (A-B-C-A-B-C)',
    description:
        'A: peito, ombros e tríceps (músculos de empurrar). B: costas e bíceps (puxar). C: pernas e abdômen. '
        'Feito em 6 dias, cada músculo treina 2 vezes por semana; em 3 dias, é um bom começo para quem tem pouco tempo.',
    levels: {TrainLevel.beginner, TrainLevel.intermediate, TrainLevel.advanced},
    trainDays: {0, 2, 4},
    days: [
      TemplateDay('Peito, ombros e tríceps', [
        TemplateItem('supino_reto_barra', _c),
        TemplateItem('supino_inclinado_halteres', _c),
        TemplateItem('voador', _i),
        TemplateItem('desenvolvimento_halteres', _c),
        TemplateItem('elevacao_lateral', _i),
        TemplateItem('triceps_corda', _i),
        TemplateItem('triceps_frances', _i),
      ]),
      TemplateDay('Costas e bíceps', [
        TemplateItem('puxada_frontal', _c),
        TemplateItem('remada_curvada_barra', _c),
        TemplateItem('remada_unilateral', _c),
        TemplateItem('pulldown_bracos_estendidos', _i),
        TemplateItem('face_pull', _i),
        TemplateItem('rosca_direta_barra', _i),
        TemplateItem('rosca_martelo', _i),
      ]),
      TemplateDay('Pernas e abdômen', [
        TemplateItem('agachamento_barra', _c),
        TemplateItem('leg_press_45', _c),
        TemplateItem('cadeira_extensora', _i),
        TemplateItem('stiff_barra', _c),
        TemplateItem('mesa_flexora', _i),
        TemplateItem('elevacao_pelvica', _c),
        TemplateItem('panturrilha_em_pe', _i),
        TemplateItem('abdominal_supra', _k),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'abcd',
    name: 'ABCD',
    summary: '4 treinos, 4 dias por semana',
    description:
        'A: peito e tríceps. B: costas e bíceps. C: pernas completas. D: ombros, trapézio e abdômen. '
        'Mais exercícios por músculo em cada treino, com cada grupo treinando uma vez por semana '
        '(os braços e ombros também trabalham como auxiliares nos outros dias).',
    levels: {TrainLevel.intermediate, TrainLevel.advanced},
    trainDays: {0, 1, 3, 4},
    days: [
      TemplateDay('Peito e tríceps', [
        TemplateItem('supino_reto_barra', _c),
        TemplateItem('supino_inclinado_halteres', _c),
        TemplateItem('crucifixo_halteres', _i),
        TemplateItem('crossover', _i),
        TemplateItem('triceps_testa', _i),
        TemplateItem('triceps_corda', _i),
      ]),
      TemplateDay('Costas e bíceps', [
        TemplateItem('puxada_frontal', _c),
        TemplateItem('remada_curvada_barra', _c),
        TemplateItem('remada_sentada', _c),
        TemplateItem('remada_unilateral', _c),
        TemplateItem('rosca_direta_barra', _i),
        TemplateItem('rosca_scott', _i),
        TemplateItem('rosca_martelo', _i),
      ]),
      TemplateDay('Pernas', [
        TemplateItem('agachamento_barra', _c),
        TemplateItem('leg_press_45', _c),
        TemplateItem('afundo_halteres', _c),
        TemplateItem('cadeira_extensora', _i),
        TemplateItem('stiff_barra', _c),
        TemplateItem('mesa_flexora', _i),
        TemplateItem('panturrilha_sentado', _i),
      ]),
      TemplateDay('Ombros, trapézio e abdômen', [
        TemplateItem('desenvolvimento_barra', _c),
        TemplateItem('elevacao_lateral', _i),
        TemplateItem('elevacao_frontal', _i),
        TemplateItem('voador_invertido', _i),
        TemplateItem('encolhimento', _i),
        TemplateItem('elevacao_pernas', _k),
        TemplateItem('prancha', _k),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'abcde',
    name: 'ABCDE',
    summary: '5 treinos, de segunda a sexta',
    description:
        'Um grupo principal por dia: A peito, B costas, C pernas, D ombros e trapézio, E braços e abdômen. '
        'Permite muitas séries por músculo, mas cada um treina só uma vez por semana. '
        'Indicada para quem já treina há bastante tempo e gosta de treinos focados.',
    levels: {TrainLevel.advanced},
    trainDays: {0, 1, 2, 3, 4},
    days: [
      TemplateDay('Peito', [
        TemplateItem('supino_reto_barra', _c),
        TemplateItem('supino_inclinado_barra', _c),
        TemplateItem('supino_reto_halteres', _c),
        TemplateItem('crucifixo_halteres', _i),
        TemplateItem('crossover', _i),
      ]),
      TemplateDay('Costas e lombar', [
        TemplateItem('barra_fixa', _c),
        TemplateItem('remada_curvada_barra', _c),
        TemplateItem('puxada_frontal', _c),
        TemplateItem('remada_unilateral', _c),
        TemplateItem('pulldown_bracos_estendidos', _i),
        TemplateItem('hiperextensao_lombar', _k),
      ]),
      TemplateDay('Pernas', [
        TemplateItem('agachamento_barra', _c),
        TemplateItem('leg_press_45', _c),
        TemplateItem('agachamento_bulgaro', _c),
        TemplateItem('cadeira_extensora', _i),
        TemplateItem('stiff_barra', _c),
        TemplateItem('mesa_flexora', _i),
        TemplateItem('elevacao_pelvica', _c),
        TemplateItem('panturrilha_em_pe', _i),
      ]),
      TemplateDay('Ombros e trapézio', [
        TemplateItem('desenvolvimento_barra', _c),
        TemplateItem('elevacao_lateral', _i),
        TemplateItem('elevacao_frontal', _i),
        TemplateItem('face_pull', _i),
        TemplateItem('voador_invertido', _i),
        TemplateItem('encolhimento', _i),
      ]),
      TemplateDay('Braços e abdômen', [
        TemplateItem('paralelas', _c),
        TemplateItem('rosca_direta_barra', _i),
        TemplateItem('triceps_testa', _i),
        TemplateItem('rosca_scott', _i),
        TemplateItem('triceps_corda', _i),
        TemplateItem('rosca_martelo', _i),
        TemplateItem('elevacao_pernas_barra', _k),
      ]),
    ],
  ),
];
