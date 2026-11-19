import 'package:flutter/material.dart';

import '../models/training.dart';
import '../models/workout_entry.dart';
import '../theme/gm_theme.dart';
import 'common.dart';

/// Calculadora de carga máxima (1RM) e tabela de cargas por repetição.
Future<void> showOneRmSheet(BuildContext context, {double kg = 0, int reps = 10}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _OneRmSheet(kg: kg, reps: reps <= 0 ? 10 : reps.clamp(1, 20)),
    );

class _OneRmSheet extends StatefulWidget {
  const _OneRmSheet({required this.kg, required this.reps});

  final double kg;
  final int reps;

  @override
  State<_OneRmSheet> createState() => _OneRmSheetState();
}

class _OneRmSheetState extends State<_OneRmSheet> {
  late double _kg = widget.kg;
  late double _reps = widget.reps.toDouble();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final reps = _reps.round();
    final rm = estimate1rm(_kg, reps);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calculadora de 1RM', style: text.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Estima a carga máxima que você levantaria uma única vez, a partir de uma série feita com boa técnica. '
            'Não é preciso testar o máximo de verdade.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Carga usada', style: text.labelLarge),
          const SizedBox(height: 6),
          LoadStepper(kg: _kg, onChanged: (v) => setState(() => _kg = v)),
          const SizedBox(height: 16),
          Text('Repetições feitas: $reps', style: text.labelLarge),
          Slider(
            value: _reps,
            min: 1,
            max: 15,
            divisions: 14,
            label: '$reps',
            onChanged: (v) => setState(() => _reps = v),
          ),
          if (reps > 10)
            Text('Acima de 10 repetições a estimativa fica menos precisa.',
                style: text.bodySmall?.copyWith(color: scheme.error)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1RM estimado', style: text.labelLarge?.copyWith(color: Colors.white70)),
                Text(
                  rm <= 0 ? '–' : formatKg(roundLoad(rm)),
                  style: const TextStyle(
                      fontFamily: display, fontWeight: FontWeight.w800, fontSize: 48, height: 1.1, color: Colors.white),
                ),
                if (rm > 0)
                  Text(
                    'Epley ${formatKg(roundLoad(epley1rm(_kg, reps)))} · Brzycki ${formatKg(roundLoad(brzycki1rm(_kg, reps)))}',
                    style: text.bodySmall?.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
          if (rm > 0) ...[
            const SizedBox(height: 16),
            Text('Cargas para cada objetivo', style: text.titleMedium),
            const SizedBox(height: 6),
            Table(
              columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.2)},
              children: [
                TableRow(children: [
                  for (final h in const ['% do 1RM', 'Repetições', 'Carga'])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(h, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                ]),
                for (final (p, r) in percentTable)
                  TableRow(
                    decoration: BoxDecoration(
                      color: r == reps ? scheme.primaryContainer : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('$p%')),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text('$r')),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(formatKg(roundLoad(rm * p / 100)), style: text.titleSmall),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Força: 1 a 6 repetições (85 a 100%). Hipertrofia: 6 a 12 (67 a 85%). Resistência: 12 ou mais. '
              'Fonte: ACSM (2009) e tabela de %1RM da NSCA.',
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
