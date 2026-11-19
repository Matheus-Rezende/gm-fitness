import 'training.dart';

class LoadRecord {
  const LoadRecord(this.date, this.kg);

  final DateTime date;
  final double kg;

  factory LoadRecord.fromJson(Map<String, dynamic> j) =>
      LoadRecord(DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(), (j['kg'] as num).toDouble());

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};
}

/// Um exercício dentro da lista do usuário, com o dia (ou a letra do treino),
/// séries, repetições, carga atual, histórico de cargas e a personalização
/// (técnica, cadência, repetições na reserva, observação e carga por série).
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.exerciseId,
    this.weekday = -1,
    this.sets = 3,
    this.reps = '12',
    this.loadKg = 0,
    this.rest = 60,
    this.history = const [],
    this.technique = Technique.normal,
    this.cadence = '',
    this.rir = -1,
    this.note = '',
    this.setPlan = const [],
  });

  final String id;
  final String exerciseId;

  /// Posição no plano: dia da semana (0 = segunda) ou letra do treino (0 = A),
  /// conforme o modo do plano. -1 = sem dia.
  final int weekday;
  final int sets;
  final String reps;
  final double loadKg;
  final int rest;
  final List<LoadRecord> history;
  final Technique technique;

  /// Cadência (ex.: "3-0-1": segundos descendo, pausa embaixo e subindo).
  final String cadence;

  /// Repetições na reserva desejadas ao fim de cada série (-1 = não definido).
  final int rir;
  final String note;

  /// Séries com carga e repetições próprias. Vazio = todas iguais ([sets] × [reps] com [loadKg]).
  final List<SetSpec> setPlan;

  int get slot => weekday;

  bool get hasSetPlan => setPlan.isNotEmpty;

  /// Quantidade de séries (a do plano por série, se houver).
  int get totalSets => hasSetPlan ? setPlan.length : sets;

  /// Séries efetivas, já expandidas (uma por série).
  List<SetSpec> get expandedSets =>
      hasSetPlan ? setPlan : [for (var i = 0; i < sets; i++) SetSpec(reps: reps, kg: loadKg)];

  /// Resumo das séries para os cartões ("3 séries de 12" ou "12×20 · 10×22 · 8×24").
  String get setsSummary {
    if (!hasSetPlan) return '$sets séries de $reps';
    String one(SetSpec s) => s.kg > 0 ? '${s.reps}×${formatKg(s.kg).replaceAll(' kg', '')}' : s.reps;
    final warm = setPlan.where((s) => s.warmup).length;
    final work = setPlan.where((s) => !s.warmup).map(one).join(' · ');
    return warm > 0 ? '$warm aquec. + $work' : work;
  }

  /// Personalização resumida (técnica, cadência, RIR).
  List<String> get extras => [
        if (technique != Technique.normal) technique.label,
        if (cadence.isNotEmpty) 'Cadência $cadence',
        if (rir >= 0) 'RIR $rir',
      ];

  WorkoutEntry copyWith({
    int? weekday,
    int? sets,
    String? reps,
    double? loadKg,
    int? rest,
    List<LoadRecord>? history,
    Technique? technique,
    String? cadence,
    int? rir,
    String? note,
    List<SetSpec>? setPlan,
  }) =>
      WorkoutEntry(
        id: id,
        exerciseId: exerciseId,
        weekday: weekday ?? this.weekday,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        loadKg: loadKg ?? this.loadKg,
        rest: rest ?? this.rest,
        history: history ?? this.history,
        technique: technique ?? this.technique,
        cadence: cadence ?? this.cadence,
        rir: rir ?? this.rir,
        note: note ?? this.note,
        setPlan: setPlan ?? this.setPlan,
      );

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        id: j['id'] as String,
        exerciseId: j['exerciseId'] as String,
        weekday: (j['weekday'] as num?)?.toInt() ?? -1,
        sets: (j['sets'] as num?)?.toInt() ?? 3,
        reps: (j['reps'] ?? '12').toString(),
        loadKg: (j['loadKg'] as num?)?.toDouble() ?? 0,
        rest: (j['rest'] as num?)?.toInt() ?? 60,
        history: [
          for (final h in (j['history'] as List? ?? const [])) LoadRecord.fromJson(Map<String, dynamic>.from(h as Map)),
        ],
        technique: techniqueFromName(j['technique'] as String?),
        cadence: (j['cadence'] as String?) ?? '',
        rir: (j['rir'] as num?)?.toInt() ?? -1,
        note: (j['note'] as String?) ?? '',
        setPlan: [
          for (final s in (j['setPlan'] as List? ?? const [])) SetSpec.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'weekday': weekday,
        'sets': sets,
        'reps': reps,
        'loadKg': loadKg,
        'rest': rest,
        'history': [for (final h in history) h.toJson()],
        if (technique != Technique.normal) 'technique': technique.name,
        if (cadence.isNotEmpty) 'cadence': cadence,
        if (rir >= 0) 'rir': rir,
        if (note.isNotEmpty) 'note': note,
        if (setPlan.isNotEmpty) 'setPlan': [for (final s in setPlan) s.toJson()],
      };
}

String formatKg(double kg) {
  if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
  return '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
}
