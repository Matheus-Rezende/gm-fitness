import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../models/session.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';

Color intensityColor(Intensity i) => switch (i) {
      Intensity.light => GmColors.green,
      Intensity.moderate => GmColors.yellow,
      Intensity.high => const Color(0xFFF07A1A),
      Intensity.veryHigh => GmColors.red,
    };

/// Mensagens de orientação a partir do resultado do treino.
List<String> sessionAdvice(WorkoutSession s, double? previousAverage) {
  final tips = <String>[];
  final pct = (s.completion * 100).round();
  final minutes = s.duration.inMinutes;
  switch (intensityOf(s.rpe)) {
    case Intensity.light:
      tips.add(s.completion >= 0.9
          ? 'O treino ficou leve. Se a técnica está boa, aumente a carga dos exercícios que você marcou como fáceis.'
          : 'Esforço leve. Nas primeiras semanas isso é esperado; depois, busque terminar as séries com 2 ou 3 '
              'repetições de folga, não mais que isso.');
    case Intensity.moderate:
      tips.add('Boa intensidade para evoluir com segurança. Mantenha esse nível na maior parte da semana.');
    case Intensity.high:
      tips.add('Treino puxado. Durma bem e coma proteína hoje; amanhã pode ser um dia mais leve ou de cardio.');
    case Intensity.veryHigh:
      tips.add('Intensidade muito alta. Descanse, hidrate-se e mantenha as cargas no próximo treino. Se for '
          'assim sempre, o risco de lesão e cansaço acumulado aumenta.');
  }
  if (pct < 70 && s.setsPlanned > 0) {
    tips.add('Você fez $pct% das séries planejadas. Se faltou tempo, comece pelos exercícios principais ou reduza '
        'uma série de cada.');
  }
  if (minutes > 90) {
    tips.add('O treino passou de 1h30. Confira se os descansos não estão longos demais.');
  } else if (minutes > 0 && minutes < 20 && s.setsDone >= 10) {
    tips.add('Ritmo bem rápido. Respeite os descansos para manter a técnica até a última repetição.');
  }
  if (previousAverage != null && previousAverage > 0) {
    final diff = (s.sessionLoad - previousAverage) / previousAverage;
    if (diff > 0.3) {
      tips.add('A carga deste treino ficou ${(diff * 100).round()}% acima da sua média recente. Aumentos grandes '
          'de uma vez pedem mais recuperação.');
    } else if (diff < -0.3) {
      tips.add('A carga deste treino ficou ${(-diff * 100).round()}% abaixo da sua média recente.');
    }
  }
  final hard = s.items.where((i) => i.feel == Feel.hard && i.setsDone < i.setsPlanned).length;
  if (hard > 0) {
    tips.add('Em $hard exercício${hard > 1 ? 's' : ''} a carga ficou pesada demais para completar as séries; '
        'a sugestão abaixo reduz um pouco.');
  }
  return tips;
}

/// Resultado do treino: tempo, séries, volume, intensidade e sugestões.
class SessionFeedbackScreen extends StatefulWidget {
  const SessionFeedbackScreen({super.key, required this.session, this.fromHistory = false});

  final WorkoutSession session;

  /// Aberto pelo histórico: só consulta, sem botão de aplicar cargas.
  final bool fromHistory;

  @override
  State<SessionFeedbackScreen> createState() => _SessionFeedbackScreenState();
}

class _SessionFeedbackScreenState extends State<SessionFeedbackScreen> {
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = widget.session;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final intensity = intensityOf(s.rpe);
    final color = intensityColor(intensity);
    final prevAvg = state.averageLoadBefore(s);
    final advice = sessionAdvice(s, prevAvg);
    final suggestions = <SessionItem, double>{
      for (final i in s.items)
        if (i.feel != null && suggestLoad(i.loadKg, i.feel, completed: i.setsDone >= i.setsPlanned) != i.loadKg)
          i: suggestLoad(i.loadKg, i.feel, completed: i.setsDone >= i.setsPlanned),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fromHistory ? 'Resumo do treino' : 'Treino concluído'),
        automaticallyImplyLeading: widget.fromHistory,
      ),
      bottomNavigationBar: widget.fromHistory ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Concluir')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Treino de ${weekdayLabel(s.weekday).toLowerCase()}', style: text.titleMedium),
          const SizedBox(height: 4),
          const PlateStripe(),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: formatDuration(s.duration), label: 'de treino'),
              _Stat(value: '${s.setsDone}/${s.setsPlanned}', label: 'séries feitas'),
              _Stat(value: s.volume >= 1000 ? '${(s.volume / 1000).toStringAsFixed(1).replaceAll('.', ',')} t' : '${s.volume.round()} kg', label: 'levantados'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intensidade', style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(intensity.label, style: text.displaySmall?.copyWith(color: color)),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('esforço ${s.rpe}/10', style: text.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _IntensityBar(rpe: s.rpe),
                const SizedBox(height: 12),
                Text(
                  'Carga da sessão: ${s.rpe} × ${s.duration.inMinutes} min = ${s.sessionLoad} pontos'
                  '${prevAvg == null ? '' : '. Sua média recente: ${prevAvg.round()} pontos'}.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SectionTitle('O que isso quer dizer', icon: Icons.insights_rounded),
          BulletList(advice, icon: Icons.arrow_right_rounded),
          if (suggestions.isNotEmpty) ...[
            const SectionTitle('Carga para o próximo treino', icon: Icons.trending_up_rounded),
            for (final e in suggestions.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key.name, style: text.titleSmall)),
                    Text(formatKg(e.key.loadKg), style: text.bodyMedium),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                    Text(formatKg(e.value),
                        style: text.titleMedium?.copyWith(color: e.value > e.key.loadKg ? GmColors.green : GmColors.red)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            if (!widget.fromHistory) OutlinedButton.icon(
              onPressed: _applied
                  ? null
                  : () async {
                      await state.applyLoads({for (final e in suggestions.entries) e.key.entryId: e.value});
                      if (mounted) setState(() => _applied = true);
                    },
              icon: Icon(_applied ? Icons.check_rounded : Icons.fitness_center_rounded),
              label: Text(_applied ? 'Cargas atualizadas' : 'Aplicar novas cargas'),
            ),
          ],
          const SectionTitle('Exercícios', icon: Icons.list_alt_rounded),
          for (final i in s.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                i.setsDone >= i.setsPlanned ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                color: i.setsDone >= i.setsPlanned ? GmColors.green : scheme.onSurfaceVariant,
              ),
              title: Text(i.name),
              subtitle: Text('${i.setsDone} de ${i.setsPlanned} séries'
                  '${i.loadKg > 0 ? ' com ${formatKg(i.loadKg)}' : ''}'
                  '${i.feel == null ? '' : ', ${i.feel!.label.toLowerCase()}'}'),
            ),
          const SizedBox(height: 8),
          Text(
            'A intensidade usa a sua percepção de esforço (escala de 0 a 10) multiplicada pelo tempo de treino, '
            'um método simples e muito usado para acompanhar a carga de treino.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.displaySmall),
          ),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.rpe});

  final int rpe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return SizedBox(
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 6,
              bottom: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Row(
                  children: [
                    for (final (flex, i) in const [
                      (4, Intensity.light),
                      (3, Intensity.moderate),
                      (2, Intensity.high),
                      (2, Intensity.veryHigh),
                    ])
                      Expanded(flex: flex, child: ColoredBox(color: intensityColor(i))),
                  ],
                ),
              ),
            ),
            Positioned(
              left: (w * rpe / 10 - 11).clamp(0, w - 22),
              top: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: GmColors.ink, width: 3),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
