import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../widgets/body_shape_icon.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'home_shell.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Planos por formato de corpo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Escolha o formato mais parecido com o seu. Cada plano tem 5 dias de treino (ou 3, para quem está '
              'começando) pensados para deixar o corpo mais proporcional.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          for (final p in state.presets)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresetDetailScreen(preset: p))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: BodyShapeIcon(shape: p.shape, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: text.titleMedium),
                            const SizedBox(height: 2),
                            Text(p.summary, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
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
          content: const Text('Você já tem exercícios na sua lista. O que prefere fazer? '
              'As cargas que você já registrou para os mesmos exercícios são mantidas.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Somar à lista')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Substituir')),
          ],
        ),
      );
      if (replace == null) return;
    }
    final n = await state.applyPreset(preset, replace: replace ?? false);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    homeTab.value = 0;
    Navigator.popUntil(context, (r) => r.isFirst);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$n exercícios do plano ${preset.name} na sua lista')));
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
            icon: const Icon(Icons.playlist_add_check),
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
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.all(8),
                child: BodyShapeIcon(shape: preset.shape, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(preset.summary, style: text.titleSmall)),
            ],
          ),
          const SizedBox(height: 16),
          Text(preset.description, style: text.bodyMedium),
          const SectionTitle('Objetivos', icon: Icons.flag_outlined),
          BulletList(preset.goals),
          const SectionTitle('Foco do treino', icon: Icons.center_focus_strong_outlined),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final f in preset.focus) Chip(label: Text(f))]),
          if (preset.caution.isNotEmpty) ...[
            const SectionTitle('Atenção', icon: Icons.info_outline),
            BulletList(preset.caution, icon: Icons.info_outline, color: scheme.tertiary),
          ],
          const SectionTitle('Semana de treino', icon: Icons.calendar_month_outlined),
          for (final d in preset.days)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(weekdayNames[d.weekday],
                                style: text.labelLarge?.copyWith(color: scheme.onSecondaryContainer)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d.title, style: text.titleSmall)),
                        ],
                      ),
                    ),
                    for (final it in d.items)
                      Builder(builder: (context) {
                        final ex = state.exercise(it.exercise);
                        if (ex == null) return const SizedBox.shrink();
                        final rest = it.rest > 0 ? ' · ${it.rest}s descanso' : '';
                        return ListTile(
                          leading: MotionThumb(clip: state.clipFor(ex), size: 48),
                          title: Text(ex.name),
                          subtitle: Text('${it.sets} × ${it.reps}$rest'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: ex.id)),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
