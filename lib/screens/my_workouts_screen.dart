import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../models/workout_entry.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/entry_editor.dart';
import 'catalog_screen.dart';
import 'exercise_detail_screen.dart';
import 'home_shell.dart';

class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  int _day = DateTime.now().weekday - 1;

  Future<void> _add() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogScreen(pickMode: true)),
    );
    if (id == null || !mounted) return;
    final saved = await showEntryEditor(context, exerciseId: id, initialWeekday: _day);
    if (saved != null && mounted) setState(() => _day = saved.weekday);
  }

  Future<void> _menu(String action) async {
    final state = AppScope.read(context);
    if (action == 'about') {
      showAboutDialog(
        context: context,
        applicationName: 'GM Fitness',
        applicationVersion: '0.1.0',
        applicationIcon: Icon(Icons.fitness_center_rounded, color: Theme.of(context).colorScheme.primary),
        children: const [
          Text('Treinos para quem está começando na academia. Funciona totalmente offline: '
              'nada sai do seu aparelho.'),
          SizedBox(height: 12),
          Text('As animações ilustram a execução correta, mas não substituem a orientação de um '
              'profissional de educação física. Se sentir dor, pare o exercício.'),
        ],
      );
    } else if (action == 'clear') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Apagar meus dados?'),
          content: const Text('Isso remove sua lista de treinos, as cargas registradas e os exercícios que '
              'você criou. Não dá para desfazer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
          ],
        ),
      );
      if (ok == true) await state.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final all = state.entries;
    final items = state.entriesOnDay(_day);
    final counts = List<int>.generate(8, (i) => state.entriesOnDay(i == 7 ? -1 : i).length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus treinos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'about', child: Text('Sobre o app')),
              PopupMenuItem(value: 'clear', child: Text('Apagar meus dados')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (var d = 0; d < 8; d++)
                  if (d < 7 || counts[7] > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(d == 7
                            ? 'Sem dia (${counts[7]})'
                            : (counts[d] > 0 ? '${weekdayShort[d]} (${counts[d]})' : weekdayShort[d])),
                        selected: _day == (d == 7 ? -1 : d),
                        onSelected: (_) => setState(() => _day = d == 7 ? -1 : d),
                      ),
                    ),
              ],
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? _EmptyState(onAdd: _add)
                : items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _day == -1 ? 'Nenhum exercício sem dia.' : 'Dia de descanso: nada marcado para ${weekdayLabel(_day).toLowerCase()}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                        itemCount: items.length,
                        onReorder: (a, b) => state.reorderDay(_day, a, b),
                        itemBuilder: (context, i) => _EntryCard(key: ValueKey(items[i].id), entry: items[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({super.key, required this.entry});

  final WorkoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ex = state.exercise(entry.exerciseId);
    if (ex == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rest = entry.rest > 0 ? ' · descanso ${entry.rest}s' : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              MotionThumb(clip: state.clipFor(ex), size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.name, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${entry.sets} × ${entry.reps}$rest',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    LoadStepper(
                      kg: entry.loadKg,
                      compact: true,
                      onChanged: (v) => state.setLoad(entry.id, v),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (a) async {
                  if (a == 'edit') {
                    await showEntryEditor(context, exerciseId: ex.id, existing: entry);
                  } else if (a == 'remove') {
                    await state.removeEntry(entry.id);
                    if (context.mounted) {
                      showSnack(context, '${ex.name} removido');
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'remove', child: Text('Remover')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Sua lista está vazia', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Comece por um plano pronto para o seu formato de corpo ou monte a sua lista exercício por exercício.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => homeTab.value = 2,
              icon: const Icon(Icons.accessibility_new),
              label: const Text('Ver planos prontos'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar exercício'),
            ),
          ],
        ),
      ),
    );
  }
}
