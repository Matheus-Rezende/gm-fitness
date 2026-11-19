import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/session.dart';
import '../models/training.dart';
import '../models/workout_entry.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../update/updater.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/entry_editor.dart';
import '../widgets/one_rm.dart';
import 'catalog_screen.dart';
import 'exercise_detail_screen.dart';
import 'home_shell.dart';
import 'profile_sheet.dart';
import 'sessions_history_screen.dart';
import 'split_setup_screen.dart';
import 'workout_session_screen.dart';

/// Treino por dia da semana (abre no dia de hoje) ou por divisão A, B, C...
/// (abre no próximo treino).
class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  /// Dia ou letra escolhida; null = o de hoje (ou o próximo treino da divisão).
  int? _picked;

  int _dayOf(AppState state) {
    final d = _picked ?? state.currentSlot;
    return d >= state.plan.slotCount ? state.currentSlot : d;
  }

  Future<void> _add() async {
    final state = AppScope.read(context);
    final day = _dayOf(state);
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogScreen(pickMode: true)),
    );
    if (id == null || !mounted) return;
    final saved = await showEntryEditor(context, exerciseId: id, initialWeekday: day < 0 ? state.currentSlot : day);
    if (saved != null && mounted) setState(() => _picked = saved.weekday);
  }

  void _openSetup() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SplitSetupScreen()));

  Future<void> _rename(AppState state, int day) async {
    final ctrl = TextEditingController(text: state.slotName(day));
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nome do ${state.plan.isSplit ? 'treino ${splitLetters[day]}' : 'treino de ${state.plan.slotLabel(day).toLowerCase()}'}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: Costas e bíceps', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Salvar')),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await state.renameSlot(day, name);
  }

  /// Letras da divisão feitas nos últimos 7 dias (bolinha amarela).
  List<bool> _recentSlots(AppState state) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final out = List<bool>.filled(state.plan.slotCount, false);
    for (final s in state.sessions) {
      if (s.startedAt.isBefore(since)) break;
      if (s.split && s.weekday >= 0 && s.weekday < out.length) out[s.weekday] = true;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final plan = state.plan;
    final day = _dayOf(state);
    final current = state.currentSlot;
    final items = state.entriesOnDay(day);
    final isToday = day == current;
    final done = isToday ? items.where((e) => state.isDone(e.id)).length : 0;
    final activity = plan.isSplit ? _recentSlots(state) : state.weekActivity();
    final counts = List<int>.generate(plan.slotCount, (i) => state.entriesOnDay(i).length);
    final noDay = state.entriesOnDay(-1).length;
    final title = day < 0 ? (plan.isSplit ? 'Sem treino definido' : 'Sem dia definido') : plan.slotLabel(day);
    final subtitle = day < 0 ? '' : state.slotName(day);
    final doneToday = plan.isSplit ? state.splitDoneToday : null;
    final heading = plan.isSplit
        ? (isToday
            ? (doneToday != null
                ? 'Treino ${splitLetters[doneToday]} feito hoje. Próximo:'
                : (state.name.isEmpty ? 'Próximo treino' : 'Bora, ${state.name}'))
            : 'Planejamento · divisão ${splitName(plan.count)}')
        : (isToday ? (state.name.isEmpty ? 'Treino de hoje' : 'Bora, ${state.name}') : 'Planejamento');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_treino',
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
                      tooltip: 'Organizar treinos',
                      onPressed: _openSetup,
                      icon: const Icon(Icons.view_week_rounded),
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
                    Text(heading, style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: day < 0 ? null : () => _rename(state, day),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(title, style: text.displayMedium)),
                              if (day >= 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(Icons.edit_outlined, size: 20, color: scheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                          if (subtitle.isNotEmpty)
                            Text(subtitle, style: text.titleLarge?.copyWith(color: scheme.primary))
                          else if (day >= 0)
                            Text('Toque para dar um nome', style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    for (var d = 0; d < plan.slotCount; d++)
                      Expanded(
                        child: _DayPill(
                          label: plan.slotShort(d),
                          count: counts[d],
                          active: activity[d],
                          today: d == current,
                          selected: d == day,
                          onTap: () => setState(() => _picked = d),
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
                      label: Text('${plan.slotShort(-1)} ($noDay)'),
                      selected: day == -1,
                      onSelected: (_) => setState(() => _picked = -1),
                    ),
                  ),
                ),
              ),
            if (state.activeSession != null || (day >= 0 && items.isNotEmpty))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SessionBar(day: day, hasItems: items.isNotEmpty),
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
              SliverFillRemaining(hasScrollBody: false, child: _EmptyState(onAdd: _add, onSetup: _openSetup))
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
                        day == -1
                            ? 'Nenhum exercício aqui.'
                            : (plan.isSplit
                                ? 'Nenhum exercício no ${plan.slotLabel(day).toLowerCase()} ainda. Toque em "Adicionar exercício".'
                                : 'Dia de descanso. Recuperar também faz parte do treino.'),
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
                  onReorderItem: (a, b) => state.reorderDay(day, a, b),
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
        label: Text(state.plan.isSplit
            ? 'Iniciar treino ${splitLetters[day.clamp(0, 5)]}'
            : 'Iniciar treino de ${state.plan.slotLabel(day).toLowerCase()}'),
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
                    Text(
                        state.slotName(active.weekday).isEmpty
                            ? state.plan.slotLabel(active.weekday)
                            : '${state.plan.slotLabel(active.weekday)} · ${state.slotName(active.weekday)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: GmColors.ink)),
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
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
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
                      Text('${entry.setsSummary}$rest', style: text.bodySmall),
                      if (entry.extras.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        EntryTags(entry: entry),
                      ],
                      if (entry.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(entry.note,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                        ),
                      if (!entry.hasSetPlan) ...[
                        const SizedBox(height: 8),
                        LoadStepper(kg: entry.loadKg, compact: true, onChanged: (v) => state.setLoad(entry.id, v)),
                      ],
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
                        } else if (a == 'rm') {
                          final work = entry.expandedSets.where((s) => !s.warmup).toList();
                          final top = work.isEmpty ? null : work.reduce((x, y) => y.kg > x.kg ? y : x);
                          await showOneRmSheet(context, kg: top?.kg ?? entry.loadKg, reps: top?.repsNumber ?? 10);
                        } else if (a == 'remove') {
                          await state.removeEntry(entry.id);
                          if (context.mounted) showSnack(context, '${ex.name} removido do treino');
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar e personalizar')),
                        PopupMenuItem(value: 'rm', child: Text('Calcular 1RM')),
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
  const _EmptyState({required this.onAdd, required this.onSetup});

  final VoidCallback onAdd;
  final VoidCallback onSetup;

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
            'Escolha uma divisão pronta (AB, ABC, ABCD, ABCDE), um plano para o seu formato de corpo '
            'ou adicione exercícios um a um.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.view_week_rounded),
              label: const Text('Montar divisão (ABC, ABCD...)'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => homeTab.value = 2,
              icon: const Icon(Icons.accessibility_new_rounded),
              label: const Text('Planos por formato de corpo'),
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

/// Etiquetas da personalização (técnica, cadência, RIR).
class EntryTags extends StatelessWidget {
  const EntryTags({super.key, required this.entry});

  final WorkoutEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final t in entry.extras)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: t == entry.technique.label && entry.technique != Technique.normal
                  ? GmColors.yellow
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              t,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t == entry.technique.label && entry.technique != Technique.normal
                    ? GmColors.ink
                    : scheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
