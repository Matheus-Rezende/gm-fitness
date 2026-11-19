import 'preset.dart';

/// Como a semana de treinos é organizada.
enum PlanMode {
  /// Cada exercício fica num dia da semana (segunda, terça...).
  weekdays,

  /// Divisão em letras (A, B, C...): treina-se na ordem, um treino por vez,
  /// em qualquer dia, e depois do último volta para o A.
  split,
}

const splitLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

/// Nome curto da divisão a partir da quantidade de treinos (3 -> "ABC").
String splitName(int count) => splitLetters.take(count.clamp(1, splitLetters.length)).join();

/// Organização dos treinos do usuário.
///
/// Os exercícios guardam um número de "posição" (o campo `weekday` do
/// [WorkoutEntry]): no modo [PlanMode.weekdays] ele é o dia da semana
/// (0 = segunda); no modo [PlanMode.split] é a letra (0 = A, 1 = B...).
/// -1 é sempre "sem dia/sem treino".
class TrainingPlan {
  const TrainingPlan({
    this.mode = PlanMode.weekdays,
    this.count = 3,
    this.names = const {},
    this.trainDays = const {0, 2, 4},
  });

  final PlanMode mode;

  /// Quantos treinos tem a divisão (2 a 6), só no modo [PlanMode.split].
  final int count;

  /// Nome de cada treino ou dia (ex.: 1 -> "Costas e bíceps").
  final Map<int, String> names;

  /// Dias da semana em que a pessoa treina (0 = segunda), usados nos lembretes
  /// e para contar a frequência semanal no modo [PlanMode.split].
  final Set<int> trainDays;

  bool get isSplit => mode == PlanMode.split;

  /// Quantas posições existem: 7 dias, ou a quantidade de letras.
  int get slotCount => isSplit ? count : 7;

  /// Rótulo curto da posição (Seg, A...).
  String slotShort(int s) {
    if (s < 0) return isSplit ? 'Sem treino' : 'Sem dia';
    return isSplit ? splitLetters[s.clamp(0, 5)] : weekdayShort[s.clamp(0, 6)];
  }

  /// Rótulo da posição (Quarta, Treino B...).
  String slotLabel(int s) {
    if (s < 0) return isSplit ? 'Sem treino' : 'Sem dia';
    return isSplit ? 'Treino ${splitLetters[s.clamp(0, 5)]}' : weekdayNames[s.clamp(0, 6)];
  }

  String nameOf(int s) => names[s] ?? '';

  /// Rótulo com o nome, se houver ("Treino B · Costas e bíceps").
  String fullLabel(int s) {
    final n = nameOf(s);
    return n.isEmpty ? slotLabel(s) : '${slotLabel(s)} · $n';
  }

  TrainingPlan copyWith({PlanMode? mode, int? count, Map<int, String>? names, Set<int>? trainDays}) => TrainingPlan(
        mode: mode ?? this.mode,
        count: (count ?? this.count).clamp(2, 6),
        names: names ?? this.names,
        trainDays: trainDays ?? this.trainDays,
      );

  factory TrainingPlan.fromJson(Map<String, dynamic> j) => TrainingPlan(
        mode: j['mode'] == 'split' ? PlanMode.split : PlanMode.weekdays,
        count: ((j['count'] as num?)?.toInt() ?? 3).clamp(2, 6),
        names: {
          for (final e in (j['names'] as Map? ?? const {}).entries)
            if (int.tryParse(e.key.toString()) != null && e.value is String) int.parse(e.key.toString()): e.value as String,
        },
        trainDays: {
          for (final d in (j['trainDays'] as List? ?? const [0, 2, 4]))
            if (d is num && d >= 0 && d < 7) d.toInt(),
        },
      );

  Map<String, dynamic> toJson() => {
        'mode': isSplit ? 'split' : 'weekdays',
        'count': count,
        'names': {for (final e in names.entries) '${e.key}': e.value},
        'trainDays': (trainDays.toList()..sort()),
      };
}
