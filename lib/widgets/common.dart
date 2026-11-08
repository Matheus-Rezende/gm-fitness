import 'package:flutter/material.dart';

import '../models/workout_entry.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: scheme.primary), const SizedBox(width: 8)],
          Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class NumberedList extends StatelessWidget {
  const NumberedList(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: scheme.primaryContainer,
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(items[i], style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key, this.icon = Icons.check_circle_outline, this.color});

  final List<String> items;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(width: 10),
                Expanded(child: Text(t)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Controle de carga: botões de menos e mais e toque no valor para digitar.
class LoadStepper extends StatelessWidget {
  const LoadStepper({super.key, required this.kg, required this.onChanged, this.step = 1.0, this.compact = false});

  final double kg;
  final ValueChanged<double> onChanged;
  final double step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuir carga',
            visualDensity: VisualDensity.compact,
            onPressed: kg <= 0 ? null : () => onChanged((kg - step).clamp(0, 999).toDouble()),
            icon: const Icon(Icons.remove),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final v = await askLoad(context, kg);
              if (v != null) onChanged(v);
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: compact ? 48 : 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  formatKg(kg),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSecondaryContainer),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar carga',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(kg + step),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

double? parseKg(String text) {
  final t = text.trim().replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || v < 0 || v > 999) return null;
  return (v * 2).round() / 2;
}

String _plainKg(double kg) => formatKg(kg).replaceAll(' kg', '');

/// Diálogo para digitar a carga, com atalhos de ajuste.
Future<double?> askLoad(BuildContext context, double current) {
  final ctrl = TextEditingController(text: current == 0 ? '' : _plainKg(current));
  return showDialog<double>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        void bump(double d) {
          final v = (parseKg(ctrl.text) ?? 0) + d;
          final nv = v < 0 ? 0.0 : v;
          ctrl.text = _plainKg(nv);
          setLocal(() {});
        }

        return AlertDialog(
          title: const Text('Carga (kg)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(suffixText: 'kg', hintText: '0', border: OutlineInputBorder()),
                onSubmitted: (_) => Navigator.pop(ctx, parseKg(ctrl.text) ?? 0),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final d in const [-5.0, -2.5, -1.0, 1.0, 2.5, 5.0])
                    ActionChip(
                      label: Text('${d > 0 ? '+' : '−'}${_plainKg(d.abs())}'),
                      onPressed: () => bump(d),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, parseKg(ctrl.text) ?? 0), child: const Text('Salvar')),
          ],
        );
      });
    },
  );
}

/// Lista de opções em uma folha inferior; devolve a chave escolhida.
Future<String?> pickOption(BuildContext context,
    {required String title, required Map<String, String> options, String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in options.entries)
                    ListTile(
                      title: Text(e.value),
                      trailing: e.key == current ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary) : null,
                      onTap: () => Navigator.pop(ctx, e.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showSnack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
}
