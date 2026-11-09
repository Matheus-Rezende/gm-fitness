import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/preset.dart';
import '../models/session.dart';
import '../models/workout_entry.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'session_feedback_screen.dart';

/// Treino em andamento: cronômetro, séries, descanso e finalização.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _tick;
  DateTime? _restEnds;
  int _restTotal = 0;
  String? _restFor;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final ends = _restEnds;
      if (ends != null && DateTime.now().isAfter(ends)) {
        final settings = AppScope.read(context).settings;
        if (settings.restVibration) HapticFeedback.heavyImpact();
        if (settings.restSound) SystemSound.play(SystemSoundType.alert);
        _restEnds = null;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _startRest(WorkoutEntry e, int done) {
    if (e.rest <= 0 || done >= e.sets) {
      setState(() => _restEnds = null);
      return;
    }
    setState(() {
      _restTotal = e.rest;
      _restFor = e.id;
      _restEnds = DateTime.now().add(Duration(seconds: e.rest));
    });
  }

  Future<void> _finish(AppState state) async {
    final rpe = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _RpeSheet(),
    );
    if (rpe == null || !mounted) return;
    final session = await state.finishSession(rpe);
    if (session == null || !mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SessionFeedbackScreen(session: session)));
  }

  Future<void> _cancel(AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar treino?'),
        content: const Text('O tempo e as séries marcadas neste treino não serão salvos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuar treinando')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Descartar')),
        ],
      ),
    );
    if (ok != true) return;
    await state.cancelSession();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.activeSession;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (active == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Nenhum treino em andamento.')));
    }
    final items = state.entriesOnDay(active.weekday);
    final planned = items.fold(0, (a, e) => a + e.sets);
    final done = items.fold(0, (a, e) => a + state.setsDoneFor(e.id));
    final restLeft = _restEnds == null ? 0 : _restEnds!.difference(DateTime.now()).inSeconds + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Treino de ${weekdayLabel(active.weekday).toLowerCase()}'),
        actions: [
          IconButton(
            tooltip: 'Descartar treino',
            onPressed: () => _cancel(state),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => _finish(state),
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Finalizar treino'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tempo de treino', style: text.labelLarge?.copyWith(color: Colors.white70)),
                Text(
                  formatDuration(active.elapsed),
                  style: const TextStyle(
                    fontFamily: display,
                    fontWeight: FontWeight.w800,
                    fontSize: 64,
                    height: 1,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('$done de $planned séries', style: text.titleMedium?.copyWith(color: Colors.white)),
                    const Spacer(),
                    Text('${planned == 0 ? 0 : (done * 100 / planned).round()}%',
                        style: text.titleMedium?.copyWith(color: GmColors.yellow)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: planned == 0 ? 0 : done / planned,
                    minHeight: 8,
                    color: GmColors.yellow,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          if (restLeft > 0) ...[
            const SizedBox(height: 12),
            _RestBanner(
              left: restLeft,
              total: _restTotal,
              name: state.exercise(state.entry(_restFor ?? '')?.exerciseId ?? '')?.name ?? '',
              onSkip: () => setState(() => _restEnds = null),
            ),
          ],
          const SizedBox(height: 14),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Nenhum exercício neste dia. Adicione exercícios na aba Treino.',
                  textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          for (final (i, e) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SessionCard(
                entry: e,
                position: i + 1,
                onSet: (count) async {
                  final prev = state.setsDoneFor(e.id);
                  await state.markSet(e.id, count);
                  if (count > prev && mounted) _startRest(e, count);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RestBanner extends StatelessWidget {
  const _RestBanner({required this.left, required this.total, required this.name, required this.onSkip});

  final int left;
  final int total;
  final String name;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      decoration: BoxDecoration(color: GmColors.yellow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : left / total,
                  strokeWidth: 4,
                  color: GmColors.ink,
                  backgroundColor: GmColors.ink.withAlpha(40),
                ),
                Text('$left',
                    style: const TextStyle(
                        fontFamily: display, fontWeight: FontWeight.w800, fontSize: 18, color: GmColors.ink)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descanso', style: text.titleMedium?.copyWith(color: GmColors.ink)),
                if (name.isNotEmpty)
                  Text('Próxima série de $name',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: GmColors.ink)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: GmColors.ink),
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.entry, required this.position, required this.onSet});

  final WorkoutEntry entry;
  final int position;
  final ValueChanged<int> onSet;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ex = state.exercise(entry.exerciseId);
    if (ex == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = state.setsDoneFor(entry.id);
    final complete = done >= entry.sets;
    final feel = state.activeSession?.feel[entry.id];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id))),
                  child: MotionThumb(clip: state.clipFor(ex), size: 64, male: state.isMale),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$position. ${ex.name}', style: text.titleMedium),
                      Text('${entry.sets} séries de ${entry.reps}', style: text.bodySmall),
                      const SizedBox(height: 6),
                      LoadStepper(kg: entry.loadKg, compact: true, onChanged: (v) => state.setLoad(entry.id, v)),
                    ],
                  ),
                ),
                if (complete) const Icon(Icons.check_circle_rounded, color: GmColors.green, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text('Séries', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 1; i <= entry.sets; i++)
                  Semantics(
                    button: true,
                    label: 'Série $i ${i <= done ? 'feita' : 'pendente'}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => onSet(i <= done ? i - 1 : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i <= done ? GmColors.green : scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: i <= done
                            ? const Icon(Icons.check_rounded, color: Colors.white)
                            : Text('$i',
                                style: TextStyle(
                                    fontFamily: display,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: scheme.onSurface)),
                      ),
                    ),
                  ),
              ],
            ),
            if (complete) ...[
              const SizedBox(height: 12),
              Text('Como foi a carga?', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in Feel.values)
                    ChoiceChip(
                      label: Text(f.label),
                      selected: feel == f,
                      onSelected: (v) => state.setFeel(entry.id, v ? f : null),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RpeSheet extends StatefulWidget {
  const _RpeSheet();

  @override
  State<_RpeSheet> createState() => _RpeSheetState();
}

class _RpeSheetState extends State<_RpeSheet> {
  double _rpe = 5;

  Color get _color {
    final i = intensityOf(_rpe.round());
    return switch (i) {
      Intensity.light => GmColors.green,
      Intensity.moderate => GmColors.yellow,
      Intensity.high => const Color(0xFFF07A1A),
      Intensity.veryHigh => GmColors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final v = _rpe.round();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quão pesado foi o treino?', style: text.headlineMedium),
            const SizedBox(height: 6),
            Text('Pense no treino inteiro, de 0 (repouso) a 10 (o máximo que você aguentaria).', style: text.bodyMedium),
            const SizedBox(height: 20),
            Center(
              child: Text('$v',
                  style: TextStyle(fontFamily: display, fontWeight: FontWeight.w800, fontSize: 72, height: 1, color: _color)),
            ),
            Center(child: Text(rpeLabels[v], style: text.titleLarge)),
            Slider(
              value: _rpe,
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: _color,
              label: '$v',
              onChanged: (x) => setState(() => _rpe = x),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Muito fácil', style: text.bodySmall), Text('Máximo', style: text.bodySmall)],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, v), child: const Text('Ver resultado')),
          ],
        ),
      ),
    );
  }
}
