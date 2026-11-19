/// Conhecimento de treino usado no app: técnicas avançadas, repetições na
/// reserva (RIR) e estimativa de carga máxima (1RM).
///
/// Referências:
/// - ACSM (2009), "Progression models in resistance training for healthy adults".
/// - Zourdos et al. (2016), escala de percepção de esforço baseada em repetições na reserva.
/// - Strength and Conditioning Journal (2025), "Advanced resistance training strategies
///   for bodybuilding: tools for muscle hypertrophy".
/// - Epley (1985) e Brzycki (1993), fórmulas de 1RM; tabela de %1RM da NSCA.
library;

/// Técnica aplicada a um exercício.
enum Technique { normal, biset, triset, dropset, restPause, pyramidUp, pyramidDown, isometric, slowEccentric }

extension TechniqueInfo on Technique {
  String get label => switch (this) {
        Technique.normal => 'Normal',
        Technique.biset => 'Bi-set',
        Technique.triset => 'Tri-set',
        Technique.dropset => 'Drop-set',
        Technique.restPause => 'Rest-pause',
        Technique.pyramidUp => 'Pirâmide crescente',
        Technique.pyramidDown => 'Pirâmide decrescente',
        Technique.isometric => 'Pico de contração',
        Technique.slowEccentric => 'Negativa lenta',
      };

  String get how => switch (this) {
        Technique.normal => 'Séries normais, com o descanso escolhido entre elas.',
        Technique.biset =>
          'Faça uma série deste exercício e vá direto para o próximo da lista, sem descanso. Descanse só depois do par.',
        Technique.triset =>
          'Faça este exercício e os dois seguintes da lista em sequência, sem descanso. Descanse só depois dos três.',
        Technique.dropset =>
          'Na última série, ao chegar perto da falha, tire 20 a 30% da carga e continue na hora, sem descanso. Pode repetir uma ou duas vezes.',
        Technique.restPause =>
          'Chegue perto da falha, solte o peso por 10 a 20 segundos e faça mais algumas repetições com a mesma carga. Repita 2 ou 3 vezes.',
        Technique.pyramidUp =>
          'A cada série, aumente a carga e diminua as repetições (ex.: 12, 10, 8, 6).',
        Technique.pyramidDown =>
          'Comece com a série mais pesada depois do aquecimento e, a cada série, tire carga e faça mais repetições (ex.: 6, 8, 10, 12).',
        Technique.isometric =>
          'Segure 1 a 2 segundos na posição de maior contração em cada repetição.',
        Technique.slowEccentric =>
          'Desça o peso em 3 a 4 segundos, controlando, e suba em ritmo normal.',
      };

  /// Faz a pessoa ir direto para o próximo exercício, sem cronômetro de descanso.
  bool get skipsRest => this == Technique.biset || this == Technique.triset;

  /// Técnicas recomendadas só para quem já treina há alguns meses.
  bool get advanced => this != Technique.normal && this != Technique.pyramidUp && this != Technique.slowEccentric;
}

Technique techniqueFromName(String? s) {
  for (final t in Technique.values) {
    if (t.name == s) return t;
  }
  return Technique.normal;
}

/// Texto curto sobre técnicas avançadas, mostrado na escolha da técnica.
const techniqueNote =
    'As técnicas avançadas economizam tempo e variam o estímulo, mas, com o mesmo número de séries, '
    'não fazem crescer mais músculo que as séries normais. Use-as com moderação, depois de alguns meses de treino.';

/// Explicação das repetições na reserva (RIR).
const rirExplanation =
    'Repetições na reserva (RIR) são quantas repetições você ainda conseguiria fazer ao terminar a série, '
    'com boa técnica. RIR 0 é ir até a falha; RIR 2 é parar quando ainda sobrariam duas. '
    'No começo é comum errar por uma repetição, então anote como foi e ajuste.';

String rirLabel(int rir) => switch (rir) {
      0 => 'Até a falha',
      1 => 'Sobra 1',
      2 => 'Sobram 2',
      3 => 'Sobram 3',
      _ => 'Sobram $rir',
    };

/// Equivalência aproximada entre RIR e a escala de esforço (RPE) de 1 a 10.
double rpeFromRir(int rir) => (10 - rir).clamp(1, 10).toDouble();

// ------------------------------------------------------------ 1RM

/// Carga máxima para uma repetição pela fórmula de Epley.
double epley1rm(double kg, int reps) => reps <= 1 ? kg : kg * (1 + reps / 30);

/// Carga máxima para uma repetição pela fórmula de Brzycki (boa até ~10 repetições).
double brzycki1rm(double kg, int reps) => reps <= 1 ? kg : (reps >= 37 ? kg * 2 : kg * 36 / (37 - reps));

/// Estimativa de 1RM: média das duas fórmulas até 10 repetições; acima disso, Epley.
double estimate1rm(double kg, int reps) {
  if (kg <= 0 || reps <= 0) return 0;
  if (reps > 10) return epley1rm(kg, reps);
  return (epley1rm(kg, reps) + brzycki1rm(kg, reps)) / 2;
}

/// Tabela de %1RM e repetições aproximadas (NSCA).
const percentTable = <(int, int)>[
  (100, 1), (95, 2), (93, 3), (90, 4), (87, 5), (85, 6), (83, 7), (80, 8), (77, 9), (75, 10), (70, 12), (67, 15),
];

/// Arredonda para o degrau de anilhas mais próximo (0,5 kg abaixo de 10 kg, senão 1 kg).
double roundLoad(double kg) {
  if (kg <= 0) return 0;
  final step = kg < 10 ? 0.5 : 1.0;
  return (kg / step).round() * step;
}

/// Gera séries de pirâmide a partir da carga de trabalho [kg].
List<SetSpec> pyramid({required bool up, required double kg, int sets = 4}) {
  const repsUp = [12, 10, 8, 6, 6, 6];
  final n = sets.clamp(2, 6);
  final list = <SetSpec>[];
  for (var i = 0; i < n; i++) {
    final reps = repsUp[i];
    // carga proporcional à tabela de %1RM das repetições, a partir da carga de 10 repetições
    final factor = _pct(reps) / _pct(10);
    list.add(SetSpec(reps: '$reps', kg: roundLoad(kg * factor)));
  }
  return up ? list : list.reversed.toList();
}

/// Série de aquecimento com metade da carga de trabalho.
SetSpec warmupSet(double kg) => SetSpec(reps: '12', kg: roundLoad(kg * 0.5), warmup: true);

int _pct(int reps) {
  for (final (p, r) in percentTable) {
    if (r >= reps) return p;
  }
  return 65;
}

/// Uma série planejada: repetições, carga e se é aquecimento.
class SetSpec {
  const SetSpec({required this.reps, this.kg = 0, this.warmup = false});

  final String reps;
  final double kg;
  final bool warmup;

  SetSpec copyWith({String? reps, double? kg, bool? warmup}) =>
      SetSpec(reps: reps ?? this.reps, kg: kg ?? this.kg, warmup: warmup ?? this.warmup);

  /// Repetições como número (o primeiro número do texto).
  int get repsNumber {
    final m = RegExp(r'\d+').firstMatch(reps);
    return m == null ? 0 : int.parse(m.group(0)!);
  }

  factory SetSpec.fromJson(Map<String, dynamic> j) => SetSpec(
        reps: (j['reps'] ?? '10').toString(),
        kg: (j['kg'] as num?)?.toDouble() ?? 0,
        warmup: j['warmup'] == true,
      );

  Map<String, dynamic> toJson() => {'reps': reps, 'kg': kg, if (warmup) 'warmup': true};
}
