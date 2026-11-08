/// Como o usuário sentiu um exercício ao terminar as séries.
enum Feel { easy, right, hard }

extension FeelLabel on Feel {
  String get label => switch (this) {
        Feel.easy => 'Fácil',
        Feel.right => 'Na medida',
        Feel.hard => 'Difícil',
      };
}

Feel? feelFromName(String? s) {
  for (final f in Feel.values) {
    if (f.name == s) return f;
  }
  return null;
}

/// Treino em andamento: quando começou e quantas séries de cada item já foram feitas.
class ActiveSession {
  ActiveSession({required this.weekday, required this.startedAt, Map<String, int>? sets, Map<String, Feel>? feel})
      : sets = sets ?? {},
        feel = feel ?? {};

  final int weekday;
  final DateTime startedAt;
  final Map<String, int> sets;
  final Map<String, Feel> feel;

  Duration get elapsed => DateTime.now().difference(startedAt);

  factory ActiveSession.fromJson(Map<String, dynamic> j) => ActiveSession(
        weekday: (j['weekday'] as num).toInt(),
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        sets: {for (final e in (j['sets'] as Map? ?? const {}).entries) e.key.toString(): (e.value as num).toInt()},
        feel: {
          for (final e in (j['feel'] as Map? ?? const {}).entries)
            if (feelFromName(e.value?.toString()) != null) e.key.toString(): feelFromName(e.value.toString())!,
        },
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'startedAt': startedAt.toIso8601String(),
        'sets': sets,
        'feel': {for (final e in feel.entries) e.key: e.value.name},
      };
}

/// Resultado de um exercício dentro de um treino concluído.
class SessionItem {
  const SessionItem({
    required this.entryId,
    required this.exerciseId,
    required this.name,
    required this.setsDone,
    required this.setsPlanned,
    required this.reps,
    required this.loadKg,
    this.feel,
  });

  final String entryId;
  final String exerciseId;
  final String name;
  final int setsDone;
  final int setsPlanned;
  final String reps;
  final double loadKg;
  final Feel? feel;

  /// Repetições como número (o primeiro número do texto, ex.: "10 cada" -> 10).
  int get repsNumber {
    final m = RegExp(r'\d+').firstMatch(reps);
    return m == null ? 0 : int.parse(m.group(0)!);
  }

  bool get isTimed => reps.contains('s') || reps.contains('min');

  /// Volume em kg (séries × repetições × carga), só para exercícios com carga.
  double get volume => (loadKg <= 0 || isTimed) ? 0 : setsDone * repsNumber * loadKg;

  factory SessionItem.fromJson(Map<String, dynamic> j) => SessionItem(
        entryId: j['entryId'] as String,
        exerciseId: j['exerciseId'] as String,
        name: j['name'] as String,
        setsDone: (j['setsDone'] as num).toInt(),
        setsPlanned: (j['setsPlanned'] as num).toInt(),
        reps: (j['reps'] ?? '').toString(),
        loadKg: (j['loadKg'] as num?)?.toDouble() ?? 0,
        feel: feelFromName(j['feel'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'exerciseId': exerciseId,
        'name': name,
        'setsDone': setsDone,
        'setsPlanned': setsPlanned,
        'reps': reps,
        'loadKg': loadKg,
        'feel': feel?.name,
      };
}

/// Treino concluído, com a percepção de esforço (PSE de 0 a 10).
class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.weekday,
    required this.startedAt,
    required this.duration,
    required this.rpe,
    required this.items,
  });

  final String id;
  final int weekday;
  final DateTime startedAt;
  final Duration duration;
  final int rpe;
  final List<SessionItem> items;

  int get setsDone => items.fold(0, (a, i) => a + i.setsDone);
  int get setsPlanned => items.fold(0, (a, i) => a + i.setsPlanned);
  double get volume => items.fold(0.0, (a, i) => a + i.volume);
  double get completion => setsPlanned == 0 ? 0 : setsDone / setsPlanned;

  /// Carga da sessão (método de Foster): PSE × minutos, em unidades arbitrárias.
  int get sessionLoad => (rpe * duration.inSeconds / 60).round();

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id'] as String,
        weekday: (j['weekday'] as num).toInt(),
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ?? DateTime.now(),
        duration: Duration(seconds: (j['seconds'] as num).toInt()),
        rpe: (j['rpe'] as num).toInt(),
        items: [for (final i in (j['items'] as List)) SessionItem.fromJson(Map<String, dynamic>.from(i as Map))],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekday': weekday,
        'startedAt': startedAt.toIso8601String(),
        'seconds': duration.inSeconds,
        'rpe': rpe,
        'items': [for (final i in items) i.toJson()],
      };
}

/// Faixa de intensidade a partir da PSE.
enum Intensity { light, moderate, high, veryHigh }

Intensity intensityOf(int rpe) {
  if (rpe <= 3) return Intensity.light;
  if (rpe <= 6) return Intensity.moderate;
  if (rpe <= 8) return Intensity.high;
  return Intensity.veryHigh;
}

extension IntensityLabel on Intensity {
  String get label => switch (this) {
        Intensity.light => 'Leve',
        Intensity.moderate => 'Moderada',
        Intensity.high => 'Alta',
        Intensity.veryHigh => 'Muito alta',
      };
}

/// Escala de percepção de esforço (CR-10 de Borg adaptada por Foster).
const rpeLabels = [
  'Repouso',
  'Muito, muito fácil',
  'Fácil',
  'Moderado',
  'Um pouco difícil',
  'Difícil',
  'Difícil',
  'Muito difícil',
  'Muito difícil',
  'Muito, muito difícil',
  'Máximo',
];

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Carga sugerida para o próximo treino a partir de como o exercício foi sentido.
/// Fácil: sobe um degrau (1 kg, ou 2,5 kg acima de 20 kg). Na medida: mantém.
/// Difícil: mantém se completou as séries, senão desce um degrau.
double suggestLoad(double kg, Feel? feel, {required bool completed}) {
  if (kg <= 0 || feel == null) return kg;
  final step = kg >= 20 ? 2.5 : 1.0;
  return switch (feel) {
    Feel.easy => kg + step,
    Feel.right => kg,
    Feel.hard => completed ? kg : (kg - step < 0 ? 0.0 : kg - step),
  };
}
