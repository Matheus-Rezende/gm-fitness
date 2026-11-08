import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/body_shape_icon.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'home_shell.dart';

class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  String? _sex;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final sex = _sex ?? state.sex;
    final list = state.presets.where((p) => p.fits(sex)).toList()
      ..sort((a, b) => (a.sex == 'both' ? 0 : 1) - (b.sex == 'both' ? 0 : 1));
    return Scaffold(
      appBar: AppBar(title: const Text('Planos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Escolha o formato mais parecido com o seu corpo. Cada plano tem uma semana de treino pensada para '
            'deixar o corpo mais proporcional.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'F', label: Text('Feminino'), icon: Icon(Icons.female_rounded)),
              ButtonSegment(value: 'M', label: Text('Masculino'), icon: Icon(Icons.male_rounded)),
            ],
            selected: {sex},
            onSelectionChanged: (s) => setState(() => _sex = s.first),
          ),
          const SizedBox(height: 16),
          for (final (i, p) in list.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetDetailScreen(preset: p))),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: GmColors.cycle[i % 4].withAlpha(36),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: BodyShapeIcon(shape: p.shape, color: GmColors.cycle[i % 4]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(child: Text(p.name, style: text.titleLarge)),
                                  if (state.currentPreset?.id == p.id) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle_rounded, color: GmColors.green, size: 20),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(p.summary, style: text.bodySmall),
                              const SizedBox(height: 6),
                              Text('${p.days.length} dias por semana',
                                  style: text.labelMedium?.copyWith(color: scheme.primary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PresetDetailScreen extends StatelessWidget {
  const PresetDetailScreen({super.key, required this.preset});

  final BodyPreset preset;

  Future<void> _apply(BuildContext context) async {
    final state = AppScope.read(context);
    bool? replace = false;
    if (state.entries.isNotEmpty) {
      replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usar este plano'),
          content: const Text('Você já tem exercícios na sua lista. As cargas que já registrou para os mesmos '
              'exercícios são mantidas.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Somar à lista')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Substituir lista')),
          ],
        ),
      );
      if (replace == null) return;
    }
    final n = await state.applyPreset(preset, replace: replace);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    homeTab.value = 0;
    Navigator.popUntil(context, (r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$n exercícios do plano ${preset.name} na sua semana')));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(preset.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => _apply(context),
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: const Text('Usar este plano'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(color: scheme.primary.withAlpha(30), borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(10),
                child: BodyShapeIcon(shape: preset.shape, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(preset.summary, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: 16),
          Text(preset.description, style: text.bodyLarge),
          const SectionTitle('Objetivos', icon: Icons.flag_outlined),
          BulletList(preset.goals),
          const SectionTitle('Foco do treino', icon: Icons.center_focus_strong_outlined),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final f in preset.focus) Chip(label: Text(f))]),
          if (preset.caution.isNotEmpty) ...[
            const SectionTitle('Atenção', icon: Icons.info_outline),
            BulletList(preset.caution, icon: Icons.info_outline, color: GmColors.red),
          ],
          const SectionTitle('Semana de treino', icon: Icons.calendar_month_outlined),
          for (final (i, d) in preset.days.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 5, color: GmColors.cycle[i % 4]),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(weekdayNames[d.weekday], style: text.headlineSmall),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(d.title, style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final it in d.items)
                      Builder(builder: (context) {
                        final ex = state.exercise(it.exercise);
                        if (ex == null) return const SizedBox.shrink();
                        final rest = it.rest > 0 ? ', descanso de ${it.rest}s' : '';
                        return ListTile(
                          leading: MotionThumb(clip: state.clipFor(ex), size: 52, male: preset.sex == 'M' || (preset.sex == 'both' && state.isMale)),
                          title: Text(ex.name, style: text.titleSmall),
                          subtitle: Text('${it.sets} séries de ${it.reps}$rest'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id)),
                          ),
                        );
                      }),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
