import 'dart:math' as math;

/// Objetivo principal de quem treina.
enum Goal { loseFat, tone, gainMuscle, health }

extension GoalText on Goal {
  String get label => switch (this) {
        Goal.loseFat => 'Emagrecer',
        Goal.tone => 'Definir',
        Goal.gainMuscle => 'Ganhar massa',
        Goal.health => 'Saúde e disposição',
      };

  String get description => switch (this) {
        Goal.loseFat => 'Perder gordura mantendo os músculos.',
        Goal.tone => 'Manter o peso, firmar e desenhar o corpo.',
        Goal.gainMuscle => 'Ganhar músculo e força, subindo o peso aos poucos.',
        Goal.health => 'Mais energia, menos dores e um corpo mais forte no dia a dia.',
      };
}

/// Quanto a pessoa se mexe fora da academia.
enum Activity { sedentary, light, moderate, active }

extension ActivityText on Activity {
  String get label => switch (this) {
        Activity.sedentary => 'Pouco ativo',
        Activity.light => 'Levemente ativo',
        Activity.moderate => 'Ativo',
        Activity.active => 'Muito ativo',
      };

  String get description => switch (this) {
        Activity.sedentary => 'Passo quase o dia todo sentado.',
        Activity.light => 'Ando um pouco no dia a dia.',
        Activity.moderate => 'Fico muito tempo em pé ou andando.',
        Activity.active => 'Trabalho com esforço físico.',
      };

  double get factor => switch (this) {
        Activity.sedentary => 1.2,
        Activity.light => 1.375,
        Activity.moderate => 1.55,
        Activity.active => 1.725,
      };
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// Dados do corpo informados pela pessoa (o peso fica no histórico de pesagens).
class BodyData {
  const BodyData({this.birthYear, this.heightCm, this.waistCm, this.targetKg, this.goal, this.activity});

  final int? birthYear;
  final double? heightCm;
  final double? waistCm;
  final double? targetKg;
  final Goal? goal;
  final Activity? activity;

  int? ageAt(DateTime now) => birthYear == null ? null : now.year - birthYear!;

  BodyData copyWith({
    int? birthYear,
    double? heightCm,
    double? waistCm,
    double? targetKg,
    Goal? goal,
    Activity? activity,
    bool clearWaist = false,
    bool clearTarget = false,
  }) =>
      BodyData(
        birthYear: birthYear ?? this.birthYear,
        heightCm: heightCm ?? this.heightCm,
        waistCm: clearWaist ? null : (waistCm ?? this.waistCm),
        targetKg: clearTarget ? null : (targetKg ?? this.targetKg),
        goal: goal ?? this.goal,
        activity: activity ?? this.activity,
      );

  factory BodyData.fromJson(Map<String, dynamic> j) => BodyData(
        birthYear: (j['birthYear'] as num?)?.toInt(),
        heightCm: _num(j['heightCm']),
        waistCm: _num(j['waistCm']),
        targetKg: _num(j['targetKg']),
        goal: _enumByName(Goal.values, j['goal']),
        activity: _enumByName(Activity.values, j['activity']),
      );

  Map<String, dynamic> toJson() => {
        'birthYear': birthYear,
        'heightCm': heightCm,
        'waistCm': waistCm,
        'targetKg': targetKg,
        'goal': goal?.name,
        'activity': activity?.name,
      };
}

/// Uma pesagem.
class WeightRecord {
  const WeightRecord(this.date, this.kg);

  final DateTime date;
  final double kg;

  factory WeightRecord.fromJson(Map<String, dynamic> j) =>
      WeightRecord(DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(), (j['kg'] as num).toDouble());

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'kg': kg};
}

/// Classificação do IMC segundo a OMS.
String bmiClass(double bmi) {
  if (bmi < 18.5) return 'Abaixo do peso';
  if (bmi < 25) return 'Peso adequado';
  if (bmi < 30) return 'Sobrepeso';
  if (bmi < 35) return 'Obesidade grau I';
  if (bmi < 40) return 'Obesidade grau II';
  return 'Obesidade grau III';
}

/// Faixa de peso com IMC entre 18,5 e 24,9 para a altura.
(double, double) healthyRange(double heightCm) {
  final m = heightCm / 100;
  return (18.5 * m * m, 24.9 * m * m);
}

/// Mensagem de erro para um peso-meta fora do saudável, ou null se estiver ok.
String? targetProblem(double target, double heightCm) {
  final (min, _) = healthyRange(heightCm);
  if (target < min) {
    return 'Esse peso fica abaixo da faixa saudável para ${heightCm.round()} cm. O mínimo recomendado é '
        '${min.ceil()} kg.';
  }
  return null;
}

int _round50(double v) => (v / 50).round() * 50;

/// Números calculados a partir do perfil. Campos ficam nulos quando falta dado.
class BodyMetrics {
  BodyMetrics._({
    required this.age,
    required this.adult,
    this.bmi,
    this.healthyMinKg,
    this.healthyMaxKg,
    this.waistToHeight,
    this.bmr,
    this.tdee,
    this.calories,
    this.proteinG,
    this.waterL,
    this.weeklyChangeKg,
    this.weeksToTarget,
  });

  final int? age;

  /// Cálculos de calorias e metas só valem para maiores de 18 anos.
  final bool adult;
  final double? bmi;
  final double? healthyMinKg;
  final double? healthyMaxKg;
  final double? waistToHeight;
  final int? bmr;
  final int? tdee;
  final int? calories;
  final int? proteinG;
  final double? waterL;

  /// Ritmo saudável esperado (negativo para perder peso).
  final double? weeklyChangeKg;
  final int? weeksToTarget;

  String? get bmiLabel => bmi == null ? null : bmiClass(bmi!);

  static BodyMetrics compute({
    required BodyData data,
    required double? weightKg,
    required String sex,
    int trainingDays = 3,
    DateTime? now,
  }) {
    final age = data.ageAt(now ?? DateTime.now());
    final adult = age != null && age >= 18;
    final h = data.heightCm;
    final w = weightKg;
    double? bmi, minKg, maxKg, whtr, water, weekly;
    int? bmr, tdee, kcal, protein, weeks;
    if (h != null && h > 0) {
      (minKg, maxKg) = healthyRange(h);
      if (data.waistCm != null) whtr = data.waistCm! / h;
    }
    if (h != null && h > 0 && w != null && w > 0) {
      final m = h / 100;
      bmi = w / (m * m);
      water = (w * 0.035).clamp(1.5, 4.0);
    }
    if (adult && h != null && w != null && w > 0) {
      final base = 10 * w + 6.25 * h - 5 * age + (sex == 'M' ? 5 : -161);
      bmr = base.round();
      final factor = (data.activity ?? Activity.light).factor + 0.03 * trainingDays.clamp(0, 6);
      final total = base * factor;
      tdee = _round50(total);
      final floor = math.max(base, sex == 'M' ? 1500.0 : 1200.0);
      final goal = data.goal ?? Goal.health;
      kcal = switch (goal) {
        Goal.loseFat => _round50(math.max(total * 0.8, floor)),
        Goal.tone => _round50(math.max(total * 0.9, floor)),
        Goal.gainMuscle => _round50(total + 250),
        Goal.health => tdee,
      };
      // Para IMC alto, a proteína é calculada sobre um peso de referência.
      final ref = bmi! > 27 ? 25 * (h / 100) * (h / 100) : w;
      final perKg = switch (goal) {
        Goal.loseFat || Goal.tone => 1.8,
        Goal.gainMuscle => 2.0,
        Goal.health => 1.4,
      };
      protein = (ref * perKg / 5).round() * 5;
      weekly = switch (goal) {
        Goal.loseFat => -w * 0.0075,
        Goal.tone => data.targetKg != null && data.targetKg! < w ? -w * 0.005 : null,
        Goal.gainMuscle => w * 0.0025,
        Goal.health => null,
      };
      final t = data.targetKg;
      if (weekly != null && t != null && targetProblem(t, h) == null) {
        final diff = t - w;
        if (diff.abs() < 0.3) {
          weeks = 0;
        } else if (diff.sign == weekly.sign) {
          weeks = (diff.abs() / weekly.abs()).ceil();
        }
      }
    }
    return BodyMetrics._(
      age: age,
      adult: adult,
      bmi: bmi,
      healthyMinKg: minKg,
      healthyMaxKg: maxKg,
      waistToHeight: whtr,
      bmr: bmr,
      tdee: tdee,
      calories: kcal,
      proteinG: protein,
      waterL: water,
      weeklyChangeKg: weekly,
      weeksToTarget: weeks,
    );
  }
}

/// Orientações práticas para o objetivo.
List<String> actionTips(Goal goal, BodyMetrics m) {
  final food = m.calories == null
      ? null
      : 'Por volta de ${m.calories} kcal por dia, com ${m.proteinG} g de proteína espalhados nas refeições.';
  return switch (goal) {
    Goal.loseFat => [
        'Faça o treino de força de 3 a 5 vezes por semana. Ele preserva os músculos enquanto a gordura vai embora.',
        'Some de 150 a 300 minutos de caminhada ou cardio leve na semana. Pode ser em blocos de 10 minutos.',
        ?food,
        'Pese-se uma vez por semana, no mesmo dia, ao acordar. Variar 1 kg de um dia para o outro é água, não gordura.',
        'Meça a cintura a cada 2 semanas. Ela costuma cair mesmo quando a balança para.',
      ],
    Goal.tone => [
        'Priorize o treino de força e suba a carga quando as últimas repetições ficarem fáceis.',
        'Faça de 150 a 200 minutos de atividade leve por semana, como caminhada.',
        ?food,
        'Acompanhe as cargas e a cintura, não só a balança: o peso pode ficar igual enquanto o corpo muda.',
      ],
    Goal.gainMuscle => [
        'Treine cada grupo muscular 2 vezes por semana e aumente a carga aos poucos.',
        'Termine as séries com 1 ou 2 repetições de folga: perto do limite, mas com técnica.',
        ?food,
        'Ganhar mais de 0,5 kg por semana costuma ser gordura. Vá devagar.',
        'Durma de 7 a 9 horas. É no descanso que o músculo cresce.',
      ],
    Goal.health => [
        'Treine força 2 ou 3 vezes por semana e mexa-se todos os dias.',
        'Some 150 minutos de atividade moderada por semana, como caminhada rápida.',
        ?food,
        'Beba água ao longo do dia e durma de 7 a 9 horas.',
      ],
  };
}
