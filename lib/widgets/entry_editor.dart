import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import 'common.dart';

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
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _EntryEditor(
        state: state,
        exerciseId: exerciseId,
        existing: existing,
        initialWeekday: initialWeekday ?? (DateTime.now().weekday - 1),
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
  bool _saving = false;

  @override
  void dispose() {
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final reps = _reps.text.trim().isEmpty ? '12' : _reps.text.trim();
    WorkoutEntry result;
    final ex = widget.existing;
    if (ex == null) {
      result = await widget.state
          .addEntry(widget.exerciseId, weekday: _weekday, sets: _sets, reps: reps, loadKg: _kg, rest: _rest);
    } else {
      result = ex.copyWith(weekday: _weekday, sets: _sets, reps: reps, loadKg: _kg, rest: _rest);
      await widget.state.updateEntry(result);
    }
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.state.exercise(widget.exerciseId);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? 'Adicionar aos meus treinos' : 'Editar exercício', style: text.titleLarge),
            if (ex != null) Text(ex.name, style: text.bodyMedium),
            const SizedBox(height: 16),
            Text('Dia da semana', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 0; d < 7; d++)
                  ChoiceChip(
                    label: Text(weekdayShort[d]),
                    selected: _weekday == d,
                    onSelected: (_) => setState(() => _weekday = d),
                  ),
                ChoiceChip(
                  label: const Text('Sem dia'),
                  selected: _weekday == -1,
                  onSelected: (_) => setState(() => _weekday = -1),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                            onPressed: _sets <= 1 ? null : () => setState(() => _sets--),
                            icon: const Icon(Icons.remove),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text('$_sets', textAlign: TextAlign.center, style: text.titleMedium),
                          ),
                          IconButton.outlined(
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
                    decoration: const InputDecoration(
                      labelText: 'Repetições',
                      hintText: '12, 10 cada, 30s',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Carga', style: text.labelLarge),
            const SizedBox(height: 6),
            LoadStepper(kg: _kg, onChanged: (v) => setState(() => _kg = v)),
            const SizedBox(height: 16),
            Text('Descanso entre séries', style: text.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final s in const [0, 30, 45, 60, 90, 120])
                  ChoiceChip(
                    label: Text(s == 0 ? 'Livre' : '${s}s'),
                    selected: _rest == s,
                    onSelected: (_) => setState(() => _rest = s),
                  ),
              ],
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
      ),
    );
  }
}
