import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../motion/motion_clip.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Criar ou editar um exercício do próprio usuário.
class CustomExerciseScreen extends StatefulWidget {
  const CustomExerciseScreen({super.key, this.existing});

  final Exercise? existing;

  @override
  State<CustomExerciseScreen> createState() => _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends State<CustomExerciseScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _steps = TextEditingController(text: widget.existing?.steps.join('\n') ?? '');
  late final _tips = TextEditingController(text: widget.existing?.tips.join('\n') ?? '');
  late String _group = widget.existing?.group ?? 'gluteos';
  late String _equipment = widget.existing?.equipment ?? 'halter';
  late String _level = widget.existing?.level ?? 'iniciante';
  late String? _anim = widget.existing?.anim;
  bool _saving = false;
  bool _triedSave = false;

  @override
  void dispose() {
    _name.dispose();
    _steps.dispose();
    _tips.dispose();
    super.dispose();
  }

  List<String> _lines(String s) => s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  Future<void> _save() async {
    setState(() => _triedSave = true);
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final ex = await state.saveCustom(
      id: widget.existing?.id,
      name: _name.text,
      group: _group,
      equipment: _equipment,
      level: _level,
      anim: _anim,
      steps: _lines(_steps.text),
      tips: _lines(_tips.text),
    );
    if (mounted) Navigator.pop(context, ex);
  }

  Future<void> _pickAnim(AppState state) async {
    final res = await Navigator.push<_AnimChoice>(
      context,
      MaterialPageRoute(builder: (_) => _AnimationPicker(library: state.motions, current: _anim)),
    );
    if (res != null) setState(() => _anim = res.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final clip = state.motions[_anim];
    final nameError = _triedSave && _name.text.trim().isEmpty ? 'Dê um nome ao exercício' : null;

    Widget option(String label, String value, Future<void> Function() onTap) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(value),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Novo exercício' : 'Editar exercício'),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('Salvar')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_triedSave) setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Nome do exercício',
              errorText: nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          option('Grupo muscular principal', state.meta.group(_group), () async {
            final v = await pickOption(context, title: 'Grupo muscular', options: state.meta.groups, current: _group);
            if (v != null) setState(() => _group = v);
          }),
          option('Equipamento', state.meta.equip(_equipment), () async {
            final v = await pickOption(context, title: 'Equipamento', options: state.meta.equipment, current: _equipment);
            if (v != null) setState(() => _equipment = v);
          }),
          option('Nível', state.meta.level(_level), () async {
            final v = await pickOption(context, title: 'Nível', options: state.meta.levels, current: _level);
            if (v != null) setState(() => _level = v);
          }),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: Text('Animação', style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(
                onPressed: () => _pickAnim(state),
                icon: const Icon(Icons.movie_outlined),
                label: Text(clip == null ? 'Escolher' : 'Trocar'),
              ),
            ],
          ),
          Text(
            'Escolha o movimento mais parecido com o seu exercício. Ele aparece quando você abrir o exercício.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (clip != null) ...[
            Text(clip.name, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            MotionView(clip: clip, showControls: false),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _steps,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Como fazer (um passo por linha)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tips,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Dicas (opcional, uma por linha)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Salvar exercício'),
          ),
        ],
      ),
    );
  }
}

class _AnimChoice {
  const _AnimChoice(this.id);

  final String? id;
}

class _AnimationPicker extends StatefulWidget {
  const _AnimationPicker({required this.library, this.current});

  final MotionLibrary library;
  final String? current;

  @override
  State<_AnimationPicker> createState() => _AnimationPickerState();
}

class _AnimationPickerState extends State<_AnimationPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = normalize(_q);
    final clips = widget.library.sorted.where((c) => q.isEmpty || normalize(c.name).contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher animação'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, const _AnimChoice(null)), child: const Text('Sem animação')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Buscar movimento',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: clips.length,
        itemBuilder: (context, i) {
          final c = clips[i];
          final selected = c.id == widget.current;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context, _AnimChoice(c.id)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(child: LayoutBuilder(builder: (context, box) => MotionThumb(clip: c, size: box.biggest.shortestSide))),
                  const SizedBox(height: 6),
                  Text(c.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
