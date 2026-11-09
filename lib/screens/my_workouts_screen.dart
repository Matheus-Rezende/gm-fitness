import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../models/session.dart';
import '../models/workout_entry.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../update/updater.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/entry_editor.dart';
import 'catalog_screen.dart';
import 'exercise_detail_screen.dart';
import 'home_shell.dart';
import 'profile_sheet.dart';
import 'sessions_history_screen.dart';
import 'workout_session_screen.dart';

/// Treino por dia da semana, abrindo no dia de hoje.
class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  final int _today = DateTime.now().weekday - 1;
  late int _day = _today;

  Future<void> _add() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogScreen(pickMode: true)),
    );
    if (id == null || !mounted) return;
    final saved = await showEntryEditor(context, exerciseId: id, initialWeekday: _day < 0 ? _today : _day);
    if (saved != null && mounted) setState(() => _day = saved.weekday);
  }

  String _dayTitle(AppState state, int day) {
    final preset = state.currentPreset;
    if (preset != null) {
      for (final d in preset.days) {
        if (d.weekday == day) return d.title;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final items = state.entriesOnDay(_day);
    final isToday = _day == _today;
    final done = isToday ? items.where((e) => state.isDone(e.id)).length : 0;
    final activity = state.weekActivity();
    final counts = List<int>.generate(7, (i) => state.entriesOnDay(i).length);
    final noDay = state.entriesOnDay(-1).length;
    final title = _day < 0 ? 'Sem dia definido' : weekdayNames[_day];
    final subtitle = _day < 0 ? '' : _dayTitle(state, _day);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar exercício'),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(fit: BoxFit.scaleDown, child: GmWordmark(size: 30)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Histórico de treinos',
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SessionsHistoryScreen())),
                      icon: const Icon(Icons.history_rounded),
                    ),
                    IconButton(
                      tooltip: 'Meu perfil',
                      onPressed: () => showProfileSheet(context),
                      icon: ListenableBuilder(
                        listenable: Updater.instance,
                        builder: (context, child) => Badge(
                          isLabelVisible: Updater.instance.available != null,
                          backgroundColor: GmColors.red,
                          child: child,
                        ),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: GmColors.yellow,
                          child: Text(
                            state.name.isEmpty ? (state.isMale ? 'M' : 'F') : state.name.characters.first.toUpperCase(),
                            style:
                                const TextStyle(fontFamily: display, fontWeight: FontWeight.w800, color: GmColors.ink),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? (state.name.isEmpty ? 'Treino de hoje' : 'Bora, ${state.name}')
                          : 'Planejamento',
                      style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Text(title, style: text.displayMedium),
                    if (subtitle.isNotEmpty) Text(subtitle, style: text.titleLarge?.copyWith(color: scheme.primary)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Expanded(
                        child: _DayPill(
                          label: weekdayShort[d],
                          count: counts[d],
                          active: activity[d],
                          today: d == _today,
                          selected: d == _day,
                          onTap: () => setState(() => _day = d),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (noDay > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ChoiceChip(
                      label: Text('Sem dia ($noDay)'),
                      selected: _day == -1,
                      onSelected: (_) => setState(() => _day = -1),
                    ),
                  ),
                ),
              ),
            if (state.activeSession != null || (_day >= 0 && items.isNotEmpty))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SessionBar(day: _day, hasItems: items.isNotEmpty),
                ),
              ),
            if (isToday && items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: _Progress(done: done, total: items.length),
                ),
              ),
            if (state.entries.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onAdd: _add))
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.self_improvement_rounded, size: 48, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        _day == -1 ? 'Nenhum exercício sem dia.' : 'Dia de descanso. Recuperar também faz parte do treino.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                sliver: SliverReorderableList(
                  itemCount: items.length,
                  onReorderItem: (a, b) => state.reorderDay(_day, a, b),
                  itemBuilder: (context, i) => ReorderableDelayedDragStartListener(
                    key: ValueKey(items[i].id),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EntryCard(entry: items[i], position: i + 1, canCheck: isToday),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Botão para iniciar o treino do dia, ou faixa do treino em andamento.
class _SessionBar extends StatelessWidget {
  const _SessionBar({required this.day, required this.hasItems});

  final int day;
  final bool hasItems;

  void _open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutSessionScreen()));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.activeSession;
    final text = Theme.of(context).textTheme;
    if (active == null) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: GmColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
        ),
        onPressed: hasItems
            ? () async {
                await state.startSession(day);
                if (context.mounted) _open(context);
              }
            : null,
        icon: const Icon(Icons.play_arrow_rounded, color: GmColors.yellow, size: 28),
        label: Text('Iniciar treino de ${weekdayLabel(day).toLowerCase()}'),
      );
    }
    return Material(
      color: GmColors.yellow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.timer_rounded, color: GmColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treino em andamento',
                        style: text.titleMedium?.copyWith(color: GmColors.ink)),
                    Text(weekdayLabel(active.weekday), style: text.bodySmall?.copyWith(color: GmColors.ink)),
                  ],
                ),
              ),
              StreamBuilder<int>(
                stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                builder: (_, _) => Text(
                  formatDuration(active.elapsed),
                  style: const TextStyle(
                    fontFamily: display,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: GmColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: GmColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.count,
    required this.active,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final bool today;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? Colors.white : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count exercícios',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : (today ? scheme.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: today && !selected ? Border.all(color: scheme.primary, width: 1.5) : null,
          ),
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
              const SizedBox(height: 2),
              Text(
                count == 0 ? '–' : '$count',
                style: TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 20, color: fg, height: 1.1),
              ),
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? GmColors.yellow : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final finished = done >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$done', style: text.displaySmall?.copyWith(color: finished ? GmColors.green : scheme.onSurface)),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text('de $total feitos', style: text.titleMedium),
            ),
            const Spacer(),
            if (finished)
              Text('Treino concluído', style: text.titleMedium?.copyWith(color: GmColors.green)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: finished ? GmColors.green : GmColors.yellow,
          ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.position, required this.canCheck});

  final WorkoutEntry entry;
  final int position;
  final bool canCheck;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ex = state.exercise(entry.exerciseId);
    if (ex == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = canCheck && state.isDone(entry.id);
    final rest = entry.rest > 0 ? ', descanso de ${entry.rest}s' : '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id)),
        ),
        child: Opacity(
          opacity: done ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    MotionThumb(clip: state.clipFor(ex), size: 76, male: state.isMale),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(6)),
                        child: Text('$position',
                            style: const TextStyle(
                                fontFamily: display, fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name,
                          style: text.titleMedium?.copyWith(decoration: done ? TextDecoration.lineThrough : null),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${entry.sets} séries de ${entry.reps}$rest', style: text.bodySmall),
                      const SizedBox(height: 8),
                      LoadStepper(kg: entry.loadKg, compact: true, onChanged: (v) => state.setLoad(entry.id, v)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (canCheck)
                      IconButton(
                        tooltip: done ? 'Desmarcar' : 'Marcar como feito',
                        onPressed: () => state.toggleDone(entry.id),
                        icon: Icon(
                          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: done ? GmColors.green : scheme.onSurfaceVariant,
                          size: 30,
                        ),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Mais opções',
                      onSelected: (a) async {
                        if (a == 'edit') {
                          await showEntryEditor(context, exerciseId: ex.id, existing: entry);
                        } else if (a == 'remove') {
                          await state.removeEntry(entry.id);
                          if (context.mounted) showSnack(context, '${ex.name} removido do treino');
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar séries e dia')),
                        PopupMenuItem(value: 'remove', child: Text('Remover do treino')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlateStripe(),
          const SizedBox(height: 20),
          Text('Monte sua semana', style: text.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Escolha um plano pronto para o seu formato de corpo ou adicione exercícios um a um.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => homeTab.value = 2,
              icon: const Icon(Icons.accessibility_new_rounded),
              label: const Text('Ver planos prontos'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar exercício'),
            ),
          ),
        ],
      ),
    );
  }
}
