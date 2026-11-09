import 'package:flutter/material.dart';

import '../models/body.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/body_widgets.dart';
import '../widgets/common.dart';
import 'body_edit_screen.dart';
import 'sessions_history_screen.dart';

/// Aba Evolução: objetivo, peso, números do corpo e plano de ação.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  void _edit(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BodyEditScreen()));

  Future<void> _weigh(BuildContext context, AppState state) async {
    final kg = await askWeight(context, initial: state.currentWeight);
    if (kg != null) await state.addWeight(kg);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final body = state.body;
    final m = state.metrics;
    final goal = body.goal;
    final hasBasics = body.heightCm != null && state.currentWeight != null && body.birthYear != null;
    final now = DateTime.now();
    final recent = state.sessions.where((s) => now.difference(s.startedAt).inDays < 28).toList();
    final minutes = recent.fold(0, (a, s) => a + s.duration.inMinutes);

    return Scaffold(
      floatingActionButton: hasBasics
          ? FloatingActionButton.extended(
              heroTag: 'fab_evolucao',
              onPressed: () => _weigh(context, state),
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('Registrar peso'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(
              children: [
                Expanded(child: Text('Evolução', style: text.displayMedium)),
                IconButton(
                  tooltip: 'Editar corpo e objetivo',
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            if (!hasBasics)
              _CompleteCard(onTap: () => _edit(context))
            else ...[
              _GoalCard(goal: goal ?? Goal.health),
              const SizedBox(height: 16),
              if (state.weights.length > 1) ...[
                Text('Peso', style: text.titleLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                  decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: WeightChart(records: state.weights, target: body.targetKg),
                ),
                const SizedBox(height: 16),
              ],
              Text('Seus números', style: text.titleLarge),
              const SizedBox(height: 8),
              MetricsGrid(metrics: m),
              if (!m.adult)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Para menores de 18 anos, calorias e metas de peso devem ser definidas com um médico ou '
                    'nutricionista.',
                    style: text.bodyMedium,
                  ),
                ),
            ],
            const SectionTitle('Treinos nas últimas 4 semanas', icon: Icons.timer_outlined),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: 'Treinos',
                    value: '${recent.length}',
                    caption: '${(recent.length / 4).toStringAsFixed(1).replaceAll('.', ',')} por semana',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: 'Tempo total',
                    value: minutes >= 60 ? '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}' : '$minutes min',
                    caption: 'treinando',
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsHistoryScreen())),
                icon: const Icon(Icons.history_rounded),
                label: const Text('Ver histórico de treinos'),
              ),
            ),
            if (goal != null) ...[
              const SectionTitle('Seu plano de ação', icon: Icons.flag_rounded),
              BulletList(actionTips(goal, m), icon: Icons.arrow_right_rounded),
            ],
            if (state.weights.isNotEmpty) ...[
              const SectionTitle('Pesagens', icon: Icons.monitor_weight_outlined),
              for (final (i, w) in state.weights.reversed.take(12).indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(formatKg(w.kg), style: text.titleMedium),
                  subtitle: Text(_date(w.date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i < state.weights.length - 1)
                        Text(
                          signedKg(w.kg - state.weights[state.weights.length - 2 - i].kg),
                          style: text.bodyMedium,
                        ),
                      IconButton(
                        tooltip: 'Apagar pesagem',
                        onPressed: () => state.removeWeight(w),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Text(
              'Os números são estimativas (IMC da OMS e gasto calórico pela fórmula de Mifflin-St Jeor) e servem '
              'para orientar. Um nutricionista ou médico ajusta tudo para você.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _CompleteCard extends StatelessWidget {
  const _CompleteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: GmColors.yellow, size: 32),
          const SizedBox(height: 8),
          Text('Acompanhe sua evolução', style: text.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Informe idade, altura, peso e objetivo para ver seu IMC, calorias e proteína do dia, a previsão para '
            'chegar à meta e o gráfico do seu peso.',
            style: text.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GmColors.yellow, foregroundColor: GmColors.ink),
            onPressed: onTap,
            child: const Text('Preencher agora'),
          ),
        ],
      ),
    );
  }
}

/// Peso atual, meta, progresso e previsão.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final m = state.metrics;
    final now = state.currentWeight!;
    final start = state.startWeight!;
    final target = state.body.targetKg;
    final color = GoalPicker.colorOf(goal);
    double? progress;
    if (target != null && (start - target).abs() > 0.1) {
      progress = ((start - now) / (start - target)).clamp(0.0, 1.0);
    }
    final change = now - start;
    final last = state.weights.last.date;
    final daysSince = DateTime.now().difference(last).inDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(goal.label,
                    style: text.labelLarge?.copyWith(color: goal == Goal.tone ? GmColors.ink : Colors.white)),
              ),
              const SizedBox(width: 8),
              if (state.weights.length > 1)
                Expanded(
                  child: Text('${signedKg(change)} desde o início',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: Colors.white70)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(formatKg(now).replaceAll(' kg', ''),
                      style: const TextStyle(
                          fontFamily: display, fontWeight: FontWeight.w800, fontSize: 56, height: 1, color: Colors.white)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text('kg', style: TextStyle(color: Colors.white70, fontSize: 18)),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              if (target != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('meta', style: text.bodySmall?.copyWith(color: Colors.white70)),
                    Text(formatKg(target),
                        style: const TextStyle(
                            fontFamily: display, fontWeight: FontWeight.w800, fontSize: 28, color: GmColors.yellow)),
                  ],
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: GmColors.yellow,
                backgroundColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(progress * 100).round()}% do caminho até a meta',
                style: text.bodySmall?.copyWith(color: Colors.white70)),
          ],
          if (m.weeksToTarget != null && m.weeksToTarget! > 0) ...[
            const SizedBox(height: 10),
            Text(
              'No ritmo saudável de ${formatKg(m.weeklyChangeKg!.abs())} por semana, a meta chega em '
              '${etaText(m.weeksToTarget!)}.',
              style: text.bodyMedium?.copyWith(color: Colors.white),
            ),
          ] else if (m.weeksToTarget == 0) ...[
            const SizedBox(height: 10),
            Text('Você chegou à meta! Agora o foco é manter e ganhar força.',
                style: text.titleMedium?.copyWith(color: GmColors.yellow)),
          ],
          if (daysSince >= 7) ...[
            const SizedBox(height: 10),
            Text('Última pesagem há $daysSince dias. Que tal se pesar hoje?',
                style: text.bodySmall?.copyWith(color: GmColors.yellow)),
          ],
        ],
      ),
    );
  }
}
