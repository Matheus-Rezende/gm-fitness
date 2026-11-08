class LoadRecord {
  const LoadRecord(this.date, this.kg);

  final DateTime date;
  final double kg;

  factory LoadRecord.fromJson(Map<String, dynamic> j) =>
      LoadRecord(DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(), (j['kg'] as num).toDouble());

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};
}

/// Um exercício dentro da lista do usuário, com dia da semana, séries,
/// repetições, carga atual e histórico de cargas.
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
  });

  final String id;
  final String exerciseId;
  final int weekday;
  final int sets;
  final String reps;
  final double loadKg;
  final int rest;
  final List<LoadRecord> history;

  WorkoutEntry copyWith({int? weekday, int? sets, String? reps, double? loadKg, int? rest, List<LoadRecord>? history}) =>
      WorkoutEntry(
        id: id,
        exerciseId: exerciseId,
        weekday: weekday ?? this.weekday,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        loadKg: loadKg ?? this.loadKg,
        rest: rest ?? this.rest,
        history: history ?? this.history,
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
      };
}

String formatKg(double kg) {
  if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
  return '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
}
