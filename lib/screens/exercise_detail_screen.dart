import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/preset.dart';
import '../models/workout_entry.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/entry_editor.dart';
import '../theme/gm_theme.dart';
import '../widgets/exercise_visuals.dart';
import 'custom_exercise_screen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  Future<void> _delete(BuildContext context, AppState state, Exercise ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir exercício?'),
        content: Text('"${ex.name}" também sai da sua lista de treinos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteCustom(ex.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ex = state.exercise(exerciseId);
    if (ex == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Exercício não encontrado.')));
    }
    final clip = state.clipFor(ex);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final mine = state.entriesFor(ex.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(ex.name),
        actions: [
          if (ex.custom) ...[
            IconButton(
              tooltip: 'Editar',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustomExerciseScreen(existing: ex)),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: () => _delete(context, state, ex),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () async {
              final saved = await showEntryEditor(context, exerciseId: ex.id);
              if (saved != null && context.mounted) {
                showSnack(context, 'Adicionado em ${weekdayLabel(saved.weekday).toLowerCase()}');
              }
            },
            icon: const Icon(Icons.playlist_add),
            label: Text(mine.isEmpty ? 'Adicionar aos meus treinos' : 'Adicionar em outro dia'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (clip != null)
            MotionView(clip: clip, style: figureStyleFor(state, ex))
          else
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text('Sem animação para este exercício',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(
                avatar: const Icon(Icons.adjust, size: 18),
                label: Text(state.meta.group(ex.group)),
              ),
              for (final g in ex.secondary) Chip(label: Text(state.meta.group(g))),
              Chip(avatar: const Icon(Icons.fitness_center, size: 18), label: Text(state.meta.equip(ex.equipment))),
              Chip(avatar: const Icon(Icons.signal_cellular_alt, size: 18), label: Text(state.meta.level(ex.level))),
            ],
          ),
          if (ex.notesFor(state.sex).isNotEmpty) ...[
            const SizedBox(height: 16),
            _ForYou(notes: ex.notesFor(state.sex), male: state.isMale),
          ],
          if (mine.isNotEmpty) ...[
            const SectionTitle('No meu treino', icon: Icons.event_note),
            for (final e in mine) _MyEntry(entry: e),
          ],
          if (ex.steps.isNotEmpty) ...[
            const SectionTitle('Como fazer', icon: Icons.format_list_numbered),
            NumberedList(ex.steps),
          ],
          if (ex.tips.isNotEmpty) ...[
            const SectionTitle('Dicas', icon: Icons.lightbulb_outline),
            BulletList(ex.tips, icon: Icons.lightbulb_outline),
          ],
          if (ex.mistakes.isNotEmpty) ...[
            const SectionTitle('Erros comuns', icon: Icons.report_gmailerrorred),
            BulletList(ex.mistakes, icon: Icons.close_rounded, color: scheme.error),
          ],
          const SizedBox(height: 20),
          Text(
            'A animação é uma ilustração da técnica. Use uma carga que permita fazer todas as repetições com '
            'boa execução e, se sentir dor, pare e procure um profissional.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ForYou extends StatelessWidget {
  const _ForYou({required this.notes, required this.male});

  final List<String> notes;
  final bool male;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: GmColors.yellow.withAlpha(40),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: GmColors.yellow),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(male ? Icons.male_rounded : Icons.female_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(male ? 'Para o corpo masculino' : 'Para o corpo feminino', style: text.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final n in notes)
                        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(n, style: text.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyEntry extends StatelessWidget {
  const _MyEntry({required this.entry});

  final WorkoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hist = entry.history.reversed.take(5).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${weekdayLabel(entry.weekday)} · ${entry.sets} × ${entry.reps}',
                    style: text.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => showEntryEditor(context, exerciseId: entry.exerciseId, existing: entry),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => state.removeEntry(entry.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Row(
              children: [
                Text('Carga', style: text.labelLarge),
                const SizedBox(width: 12),
                LoadStepper(kg: entry.loadKg, onChanged: (v) => state.setLoad(entry.id, v)),
              ],
            ),
            if (hist.length > 1) ...[
              const SizedBox(height: 10),
              Text('Histórico de carga', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final h in hist)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${_date(h.date)}: ${formatKg(h.kg)}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
