import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/preset.dart';
import '../models/split_templates.dart';
import '../models/training.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/common.dart';
import 'share_plan_screen.dart';

/// Organização da semana: por dia da semana ou em divisão A, B, C...,
/// com nomes de cada treino, dias em que a pessoa treina e divisões prontas.
class SplitSetupScreen extends StatelessWidget {
  const SplitSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final plan = state.plan;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Organizar treinos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Enviar e receber treinos'),
              subtitle: const Text('Importe o treino do seu personal ou envie o seu. Biblioteca de treinos.'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharePlanScreen())),
            ),
          ),
          Text('Como você organiza a semana?', style: text.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<PlanMode>(
            segments: const [
              ButtonSegment(value: PlanMode.weekdays, label: Text('Dia da semana'), icon: Icon(Icons.calendar_month)),
              ButtonSegment(value: PlanMode.split, label: Text('Divisão A, B, C'), icon: Icon(Icons.view_week_rounded)),
            ],
            selected: {plan.mode},
            onSelectionChanged: (v) async {
              await state.setPlan(plan.copyWith(mode: v.first));
              if (context.mounted) {
                showSnack(
                    context,
                    v.first == PlanMode.split
                        ? 'Seus dias com exercícios viraram treinos ${splitName(state.plan.count)}.'
                        : 'Cada treino voltou para um dia da semana.');
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            plan.isSplit
                ? 'Você faz os treinos em ordem (A, depois B, depois C...), em qualquer dia. '
                    'Faltou um dia? O próximo treino continua sendo o que ficou pendente.'
                : 'Cada exercício fica num dia fixo da semana.',
            style: text.bodySmall,
          ),
          if (plan.isSplit) ...[
            const SizedBox(height: 20),
            Text('Quantos treinos?', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var n = 2; n <= 6; n++)
                  ChoiceChip(
                    label: Text(splitName(n)),
                    selected: plan.count == n,
                    onSelected: (_) async {
                      final lost = [for (var s = n; s < plan.count; s++) ...state.entriesOnDay(s)].length;
                      if (lost > 0) {
                        final ok = await _confirm(
                          context,
                          'Diminuir para ${splitName(n)}?',
                          '$lost exercício(s) dos treinos removidos vão para "Sem treino". Você pode movê-los depois.',
                        );
                        if (!ok) return;
                      }
                      await state.setPlan(plan.copyWith(count: n));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (var s = 0; s < plan.count; s++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: GmColors.cycle[s % GmColors.cycle.length],
                    foregroundColor: s % GmColors.cycle.length == 2 ? GmColors.ink : Colors.white,
                    child: Text(splitLetters[s], style: const TextStyle(fontFamily: display, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(state.slotName(s).isEmpty ? 'Treino ${splitLetters[s]}' : state.slotName(s)),
                  subtitle: Text('${state.entriesOnDay(s).length} exercícios'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _rename(context, state, s),
                ),
              ),
            const SizedBox(height: 12),
            Text('Em quais dias você treina?', style: text.titleMedium),
            const SizedBox(height: 4),
            Text('Usado nos lembretes e para contar quantas vezes por semana você treina.', style: text.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 0; d < 7; d++)
                  FilterChip(
                    label: Text(weekdayShort[d]),
                    selected: plan.trainDays.contains(d),
                    onSelected: (v) {
                      final days = {...plan.trainDays};
                      v ? days.add(d) : days.remove(d);
                      if (days.isEmpty) return;
                      state.setPlan(plan.copyWith(trainDays: days));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.trainDays.length} dias por semana: cada treino se repete '
              '${_freq(plan.trainDays.length, plan.count)}.',
              style: text.bodySmall?.copyWith(color: scheme.primary),
            ),
          ],
          const SizedBox(height: 28),
          Text('Divisões prontas', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Montadas com base nas recomendações do ACSM e em estudos de volume e frequência. '
            'Escolha o seu nível e o app ajusta séries, repetições e descanso.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 10),
          for (final t in splitTemplates) _TemplateCard(template: t),
        ],
      ),
    );
  }

  static String _freq(int days, int count) {
    final per = days / count;
    if (per >= 1.75) return 'cerca de 2 vezes por semana';
    if (per >= 1.25) return 'de 1 a 2 vezes por semana';
    if (per >= 0.75) return '1 vez por semana';
    return 'a cada 1 a 2 semanas';
  }

  static Future<bool> _confirm(BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
          ],
        ),
      ) ??
      false;

  static Future<void> _rename(BuildContext context, AppState state, int s) async {
    final ctrl = TextEditingController(text: state.slotName(s));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nome do treino ${splitLetters[s]}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: Peito e tríceps', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Salvar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await state.renameSlot(s, name);
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final SplitTemplate template;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final t = template;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(8)),
                    child: Text(t.letters,
                        style: const TextStyle(
                            fontFamily: display, fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.name, style: text.titleMedium)),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 6),
              Text(t.summary, style: text.bodyMedium),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final l in TrainLevel.values)
                    if (t.levels.contains(l))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                        child: Text(l.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => _TemplateSheet(template: template),
      );
}

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet({required this.template});

  final SplitTemplate template;

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  late TrainLevel _level = widget.template.levels.first;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final t = widget.template;
    final text = Theme.of(context).textTheme;
    final items = planTemplate(t, _level, exists: (id) => state.exercise(id) != null);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.name, style: text.headlineMedium),
          const SizedBox(height: 6),
          Text(t.description, style: text.bodyMedium),
          const SizedBox(height: 6),
          Text('Dias sugeridos: ${(t.trainDays.toList()..sort()).map((d) => weekdayShort[d]).join(', ')}',
              style: text.bodySmall),
          const SizedBox(height: 16),
          Text('Seu nível', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final l in TrainLevel.values)
                ChoiceChip(
                  label: Text(l.label),
                  selected: _level == l,
                  onSelected: (_) => setState(() => _level = l),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${_level.who} ${_level.dose}', style: text.bodySmall),
          if (!t.levels.contains(_level))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _level == TrainLevel.beginner
                    ? 'Para quem está começando, recomendamos Corpo inteiro A/B ou AB.'
                    : 'Essa divisão não é a mais indicada para o seu nível, mas pode ser usada.',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          for (final (i, d) in t.days.indexed) ...[
            Text('Treino ${splitLetters[i]} · ${d.name}', style: text.titleSmall),
            const SizedBox(height: 4),
            for (final it in items.where((x) => x.slot == i))
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  '• ${state.exercise(it.exercise)?.name ?? it.exercise}: ${it.sets} × ${it.reps}'
                  '${it.technique == Technique.dropset ? ' · drop-set na última série' : ''}',
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final has = state.entries.isNotEmpty;
                if (has) {
                  final ok = await SplitSetupScreen._confirm(
                    context,
                    'Usar ${t.name}?',
                    'Os exercícios atuais serão substituídos pelos desta divisão. '
                        'As cargas que você já anotou para os mesmos exercícios são mantidas, e o histórico de treinos não muda.',
                  );
                  if (!ok) return;
                }
                final n = await state.applyTemplate(t, _level);
                nav.pop();
                nav.pop();
                messenger.showSnackBar(
                    SnackBar(content: Text('${t.letters} pronto: $n exercícios. Ajuste as cargas no primeiro treino.')));
              },
              icon: const Icon(Icons.check),
              label: Text('Usar esta divisão (${_level.label.toLowerCase()})'),
            ),
          ),
        ],
      ),
    );
  }
}
