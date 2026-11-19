import 'package:flutter/material.dart';

import '../models/training.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import 'common.dart';
import 'one_rm.dart';

/// Abre a folha para adicionar um exercício à lista ou editar um item.
/// Devolve o item salvo, ou null se o usuário cancelar.
Future<WorkoutEntry?> showEntryEditor(
  BuildContext context, {
  required String exerciseId,
  WorkoutEntry? existing,
  int? initialWeekday,
}) {
  final state = AppScope.read(context);
  return showModalBottomSheet<WorkoutEntry>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _EntryEditor(
        state: state,
        exerciseId: exerciseId,
        existing: existing,
        initialWeekday: initialWeekday ?? state.currentSlot,
      ),
    ),
  );
}

class _EntryEditor extends StatefulWidget {
  const _EntryEditor({required this.state, required this.exerciseId, this.existing, required this.initialWeekday});

  final AppState state;
  final String exerciseId;
  final WorkoutEntry? existing;
  final int initialWeekday;

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  late int _weekday = widget.existing?.weekday ?? widget.initialWeekday;
  late int _sets = widget.existing?.sets ?? 3;
  late final TextEditingController _reps = TextEditingController(text: widget.existing?.reps ?? '12');
  late double _kg = widget.existing?.loadKg ?? 0;
  late int _rest = widget.existing?.rest ?? 60;
  late Technique _technique = widget.existing?.technique ?? Technique.normal;
  late final TextEditingController _cadence = TextEditingController(text: widget.existing?.cadence ?? '');
  late int _rir = widget.existing?.rir ?? -1;
  late final TextEditingController _note = TextEditingController(text: widget.existing?.note ?? '');
  late List<SetSpec> _setPlan = [...?widget.existing?.setPlan];
  late bool _custom = (widget.existing?.extras.isNotEmpty ?? false) ||
      (widget.existing?.note.isNotEmpty ?? false) ||
      (widget.existing?.hasSetPlan ?? false);
  bool _saving = false;

  @override
  void dispose() {
    _reps.dispose();
    _cadence.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final reps = _reps.text.trim().isEmpty ? '12' : _reps.text.trim();
    final cadence = _cadence.text.trim();
    final note = _note.text.trim();
    WorkoutEntry result;
    final ex = widget.existing;
    if (ex == null) {
      result = await widget.state.addEntry(
        widget.exerciseId,
        weekday: _weekday,
        sets: _sets,
        reps: reps,
        loadKg: _kg,
        rest: _rest,
        technique: _technique,
        cadence: cadence,
        rir: _rir,
        note: note,
        setPlan: _setPlan,
      );
    } else {
      result = ex.copyWith(
        weekday: _weekday,
        sets: _setPlan.isNotEmpty ? _setPlan.length : _sets,
        reps: reps,
        loadKg: _kg,
        rest: _rest,
        technique: _technique,
        cadence: cadence,
        rir: _rir,
        note: note,
        setPlan: _setPlan,
      );
      await widget.state.updateEntry(result);
    }
    if (mounted) Navigator.pop(context, result);
  }

  int get _repsNumber {
    final m = RegExp(r'\d+').firstMatch(_reps.text);
    return m == null ? 0 : int.parse(m.group(0)!);
  }

  void _startSetPlan() {
    setState(() {
      _setPlan = [for (var i = 0; i < _sets; i++) SetSpec(reps: _reps.text.trim().isEmpty ? '12' : _reps.text.trim(), kg: _kg)];
    });
  }

  Future<void> _editSet(int i) async {
    final s = _setPlan[i];
    final reps = TextEditingController(text: s.reps);
    var kg = s.kg;
    var warm = s.warmup;
    final out = await showDialog<SetSpec>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Série ${i + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: reps,
                decoration: const InputDecoration(labelText: 'Repetições', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              LoadStepper(kg: kg, onChanged: (v) => setD(() => kg = v)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: warm,
                onChanged: (v) => setD(() => warm = v ?? false),
                title: const Text('Série de aquecimento'),
                subtitle: const Text('Não conta no volume do treino.'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, SetSpec(reps: reps.text.trim().isEmpty ? s.reps : reps.text.trim(), kg: kg, warmup: warm)),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    reps.dispose();
    if (out != null && mounted) setState(() => _setPlan[i] = out);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final plan = state.plan;
    final ex = state.exercise(widget.exerciseId);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final est = estimate1rm(_kg, _repsNumber);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing == null ? 'Adicionar aos meus treinos' : 'Editar exercício', style: text.titleLarge),
          if (ex != null) Text(ex.name, style: text.bodyMedium),
          const SizedBox(height: 16),
          Text(plan.isSplit ? 'Treino' : 'Dia da semana', style: text.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var d = 0; d < plan.slotCount; d++)
                ChoiceChip(
                  label: Text(plan.isSplit && state.slotName(d).isNotEmpty
                      ? '${plan.slotShort(d)} · ${state.slotName(d)}'
                      : plan.slotShort(d)),
                  selected: _weekday == d,
                  onSelected: (_) => setState(() => _weekday = d),
                ),
              ChoiceChip(
                label: Text(plan.slotShort(-1)),
                selected: _weekday == -1,
                onSelected: (_) => setState(() => _weekday = -1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_setPlan.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Séries', style: text.labelLarge),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: 'Menos séries',
                            onPressed: _sets <= 1 ? null : () => setState(() => _sets--),
                            icon: const Icon(Icons.remove),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text('$_sets', textAlign: TextAlign.center, style: text.titleMedium),
                          ),
                          IconButton.outlined(
                            tooltip: 'Mais séries',
                            onPressed: _sets >= 10 ? null : () => setState(() => _sets++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _reps,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Repetições',
                      hintText: '12, 8-10, 30s',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Carga', style: text.labelLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                LoadStepper(kg: _kg, onChanged: (v) => setState(() => _kg = v)),
                const SizedBox(width: 12),
                if (est > 0)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => showOneRmSheet(context, kg: _kg, reps: _repsNumber),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text('1RM estimado: ${formatKg(roundLoad(est))}',
                            style: text.bodySmall?.copyWith(color: scheme.primary)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('Descanso entre séries', style: text.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in const [0, 30, 45, 60, 75, 90, 120, 150, 180])
                ChoiceChip(
                  label: Text(s == 0 ? 'Livre' : (s % 60 == 0 ? '${s ~/ 60} min' : '${s}s')),
                  selected: _rest == s,
                  onSelected: (_) => setState(() => _rest = s),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              initiallyExpanded: _custom,
              onExpansionChanged: (v) => _custom = v,
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Personalizar'),
              subtitle: const Text('Técnica, cadência, repetições na reserva, carga por série e observação'),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(context, 'Técnica', onInfo: () => _techniqueHelp(context)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in Technique.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _technique == t,
                        onSelected: (_) => setState(() => _technique = t),
                      ),
                  ],
                ),
                if (_technique != Technique.normal) ...[
                  const SizedBox(height: 6),
                  Text(_technique.how, style: text.bodySmall),
                ],
                const SizedBox(height: 16),
                _label(context, 'Repetições na reserva (RIR)', onInfo: () => _info(context, 'Repetições na reserva', rirExplanation)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(label: const Text('Livre'), selected: _rir < 0, onSelected: (_) => setState(() => _rir = -1)),
                    for (var r = 0; r <= 4; r++)
                      ChoiceChip(
                        label: Text(r == 0 ? 'Falha' : '$r'),
                        selected: _rir == r,
                        onSelected: (_) => setState(() => _rir = r),
                      ),
                  ],
                ),
                if (_rir >= 0) ...[
                  const SizedBox(height: 4),
                  Text('${rirLabel(_rir)} ao final de cada série (esforço ${rpeFromRir(_rir).toStringAsFixed(0)} de 10).',
                      style: text.bodySmall),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _cadence,
                  decoration: InputDecoration(
                    labelText: 'Cadência (opcional)',
                    hintText: 'Ex.: 3-0-1',
                    helperText: 'Segundos descendo, pausa embaixo e subindo.',
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'O que é cadência',
                      onPressed: () => _info(
                          context,
                          'Cadência',
                          'É o tempo de cada fase da repetição. Em "3-0-1", você desce em 3 segundos, '
                              'não pausa embaixo e sobe em 1 segundo. Para começar, 2-0-1 ou 3-0-1 ajudam a controlar o peso.'),
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label(context, 'Carga por série'),
                if (_setPlan.isEmpty) ...[
                  Text('Use quando cada série tiver peso ou repetições diferentes (pirâmide, aquecimento).',
                      style: text.bodySmall),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _startSetPlan,
                    icon: const Icon(Icons.stacked_bar_chart_rounded),
                    label: const Text('Definir carga por série'),
                  ),
                ] else ...[
                  for (final (i, st) in _setPlan.indexed)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: st.warmup ? scheme.surfaceContainerHighest : scheme.primary,
                        child: Text(st.warmup ? 'Aq' : '${i + 1 - _setPlan.take(i).where((x) => x.warmup).length}',
                            style: TextStyle(fontSize: 12, color: st.warmup ? scheme.onSurface : scheme.onPrimary)),
                      ),
                      title: Text('${st.reps} repetições${st.kg > 0 ? ' com ${formatKg(st.kg)}' : ''}'),
                      subtitle: st.warmup ? const Text('Aquecimento') : null,
                      onTap: () => _editSet(i),
                      trailing: IconButton(
                        tooltip: 'Remover série',
                        onPressed: () => setState(() => _setPlan.removeAt(i)),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Série'),
                        onPressed: _setPlan.length >= 10
                            ? null
                            : () => setState(() => _setPlan.add(_setPlan.isEmpty
                                ? SetSpec(reps: '10', kg: _kg)
                                : _setPlan.last.copyWith(warmup: false))),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.local_fire_department_outlined, size: 18),
                        label: const Text('Aquecimento'),
                        onPressed: _setPlan.any((x) => x.warmup)
                            ? null
                            : () => setState(() => _setPlan.insert(0, warmupSet(_workKg))),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.trending_up_rounded, size: 18),
                        label: const Text('Pirâmide crescente'),
                        onPressed: () => setState(() {
                          _setPlan = pyramid(up: true, kg: _workKg, sets: _workSets);
                          _technique = Technique.pyramidUp;
                        }),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.trending_down_rounded, size: 18),
                        label: const Text('Pirâmide decrescente'),
                        onPressed: () => setState(() {
                          _setPlan = pyramid(up: false, kg: _workKg, sets: _workSets);
                          _technique = Technique.pyramidDown;
                        }),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Séries iguais'),
                        onPressed: () => setState(() {
                          _sets = _workSets;
                          _setPlan = [];
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Toque numa série para mudar repetições e carga. A pirâmide usa a carga de 10 repetições como base.',
                      style: text.bodySmall),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    hintText: 'Ex.: banco no furo 3, pegada fechada',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(widget.existing == null ? 'Adicionar' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  /// Carga de trabalho de referência (a maior do plano por série, ou a carga única).
  double get _workKg {
    final work = _setPlan.where((s) => !s.warmup).map((s) => s.kg);
    if (work.isEmpty) return _kg;
    // a carga de 10 repetições, se houver; senão a média
    for (final s in _setPlan) {
      if (!s.warmup && s.repsNumber == 10) return s.kg;
    }
    return work.reduce((a, b) => a + b) / work.length;
  }

  int get _workSets {
    final n = _setPlan.where((s) => !s.warmup).length;
    return n >= 2 ? n : (_sets >= 2 ? _sets : 4);
  }

  Widget _label(BuildContext context, String title, {VoidCallback? onInfo}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            if (onInfo != null)
              IconButton(
                tooltip: 'Saiba mais',
                visualDensity: VisualDensity.compact,
                onPressed: onInfo,
                icon: const Icon(Icons.info_outline_rounded, size: 20),
              ),
          ],
        ),
      );

  void _info(BuildContext context, String title, String body) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi'))],
        ),
      );

  void _techniqueHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Técnicas de treino'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in Technique.values.skip(1)) ...[
                  Text(t.label, style: Theme.of(ctx).textTheme.titleSmall),
                  Text(t.how),
                  const SizedBox(height: 10),
                ],
                Text(techniqueNote, style: Theme.of(ctx).textTheme.bodySmall),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi'))],
        ),
      );
}
