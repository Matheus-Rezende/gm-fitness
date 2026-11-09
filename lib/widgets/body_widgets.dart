import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/body.dart';
import '../models/workout_entry.dart';
import '../theme/gm_theme.dart';

/// Lê um número digitado com vírgula ou ponto.
double? readNumber(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

String formatNumber(double v, {int decimals = 1}) {
  final s = v.toStringAsFixed(decimals);
  final t = s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  return t.replaceAll('.', ',');
}

/// Campo numérico com unidade.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    this.helper,
    this.decimals = true,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? helper;
  final bool decimals;
  final String? Function(String)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimals ? r'[0-9.,]' : r'[0-9]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix, helperText: helper, helperMaxLines: 2),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator == null ? null : (v) => validator!(v ?? ''),
      onChanged: onChanged,
    );
  }
}

/// Validação de faixa: vazio é aceito quando [optional].
String? Function(String) rangeValidator(double min, double max, String unit, {bool optional = false}) {
  return (s) {
    if (s.trim().isEmpty) return optional ? null : 'Preencha este campo';
    final v = readNumber(s);
    if (v == null) return 'Número inválido';
    if (v < min || v > max) return 'Use um valor entre ${formatNumber(min)} e ${formatNumber(max)} $unit';
    return null;
  };
}

/// Escolha do objetivo em cartões.
class GoalPicker extends StatelessWidget {
  const GoalPicker({super.key, required this.value, required this.onChanged});

  final Goal? value;
  final ValueChanged<Goal> onChanged;

  static IconData iconOf(Goal g) => switch (g) {
        Goal.loseFat => Icons.local_fire_department_rounded,
        Goal.tone => Icons.auto_awesome_rounded,
        Goal.gainMuscle => Icons.fitness_center_rounded,
        Goal.health => Icons.favorite_rounded,
      };

  static Color colorOf(Goal g) => switch (g) {
        Goal.loseFat => GmColors.red,
        Goal.tone => GmColors.yellow,
        Goal.gainMuscle => GmColors.blue,
        Goal.health => GmColors.green,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final g in Goal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: value == g ? scheme.primary : scheme.outlineVariant, width: value == g ? 2.5 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(g),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: colorOf(g), borderRadius: BorderRadius.circular(12)),
                        child: Icon(iconOf(g), color: g == Goal.tone ? GmColors.ink : Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.label, style: text.titleMedium),
                            Text(g.description, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (value == g) Icon(Icons.check_circle_rounded, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Nível de atividade fora da academia.
class ActivityPicker extends StatelessWidget {
  const ActivityPicker({super.key, required this.value, required this.onChanged});

  final Activity? value;
  final ValueChanged<Activity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in Activity.values)
              ChoiceChip(label: Text(a.label), selected: value == a, onSelected: (_) => onChanged(a)),
          ],
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(value!.description, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Pede o peso do dia.
Future<double?> askWeight(BuildContext context, {double? initial}) async {
  final ctrl = TextEditingController(text: initial == null ? '' : formatNumber(initial));
  final key = GlobalKey<FormState>();
  final v = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Registrar peso'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberField(
              controller: ctrl,
              label: 'Peso de hoje',
              suffix: 'kg',
              validator: rangeValidator(30, 300, 'kg'),
            ),
            const SizedBox(height: 10),
            Text('Para comparar melhor, pese-se ao acordar, depois de ir ao banheiro e antes de comer.',
                style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (key.currentState?.validate() ?? false) Navigator.pop(ctx, readNumber(ctrl.text));
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return v;
}

/// Pequeno cartão com um número e uma legenda.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.caption, this.color, this.icon});

  final String label;
  final String value;
  final String? caption;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? scheme.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.headlineMedium?.copyWith(color: color)),
          ),
          if (caption != null) Text(caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
        ],
      ),
    );
  }
}

/// Gráfico das pesagens, com a faixa do peso-meta.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.records, this.target, this.height = 180});

  final List<WeightRecord> records;
  final double? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightPainter(
          records: records,
          target: target,
          line: scheme.primary,
          grid: scheme.outlineVariant,
          label: scheme.onSurfaceVariant,
          targetColor: GmColors.green,
        ),
      ),
    );
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter({
    required this.records,
    required this.target,
    required this.line,
    required this.grid,
    required this.label,
    required this.targetColor,
  });

  final List<WeightRecord> records;
  final double? target;
  final Color line;
  final Color grid;
  final Color label;
  final Color targetColor;

  void _text(Canvas c, String s, Offset at, {Color? color, bool right = false, double size = 11}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color ?? label, fontSize: size, fontFamily: body)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(right ? at.dx - tp.width : at.dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;
    var lo = records.map((r) => r.kg).reduce(math.min);
    var hi = records.map((r) => r.kg).reduce(math.max);
    if (target != null) {
      lo = math.min(lo, target!);
      hi = math.max(hi, target!);
    }
    final pad = math.max(1.0, (hi - lo) * 0.15);
    lo -= pad;
    hi += pad;
    const left = 36.0, rightPad = 8.0, top = 8.0, bottom = 22.0;
    final w = size.width - left - rightPad;
    final h = size.height - top - bottom;
    final t0 = records.first.date.millisecondsSinceEpoch.toDouble();
    final t1 = math.max(records.last.date.millisecondsSinceEpoch.toDouble(), t0 + const Duration(days: 1).inMilliseconds);
    Offset pt(WeightRecord r) => Offset(
          left + (records.length == 1 ? w / 2 : (r.date.millisecondsSinceEpoch - t0) / (t1 - t0) * w),
          top + (hi - r.kg) / (hi - lo) * h,
        );
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + h * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gridPaint);
      _text(canvas, formatNumber(hi - (hi - lo) * i / 3, decimals: 0), Offset(left - 6, y), right: true);
    }
    if (target != null) {
      final y = top + (hi - target!) / (hi - lo) * h;
      final p = Paint()
        ..color = targetColor
        ..strokeWidth = 2;
      for (var x = left; x < left + w; x += 10) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, left + w), y), p);
      }
      _text(canvas, 'meta', Offset(left + w - 2, y - 9), color: targetColor, right: true);
    }
    final pts = [for (final r in records) pt(r)];
    if (pts.length > 1) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final fill = Path.from(path)
        ..lineTo(pts.last.dx, top + h)
        ..lineTo(pts.first.dx, top + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withAlpha(70), line.withAlpha(0)],
          ).createShader(Rect.fromLTWH(left, top, w, h)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = line);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }
    String d(DateTime x) => '${x.day.toString().padLeft(2, '0')}/${x.month.toString().padLeft(2, '0')}';
    _text(canvas, d(records.first.date), Offset(left, size.height - 8));
    if (records.length > 1) _text(canvas, d(records.last.date), Offset(left + w, size.height - 8), right: true);
  }

  @override
  bool shouldRepaint(_WeightPainter old) => old.records != records || old.target != target || old.line != line;
}

/// "−1,2 kg" / "+0,8 kg".
String signedKg(double v) => '${v > 0 ? '+' : v < 0 ? '−' : ''}${formatKg(v.abs())}';

Color bmiColor(double bmi) {
  if (bmi < 18.5) return GmColors.yellow;
  if (bmi < 25) return GmColors.green;
  if (bmi < 30) return GmColors.yellow;
  return GmColors.red;
}

const _months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

/// "cerca de 12 semanas (mar/2027)".
String etaText(int weeks, [DateTime? from]) {
  final d = (from ?? DateTime.now()).add(Duration(days: weeks * 7));
  final span = weeks < 9 ? '$weeks semana${weeks == 1 ? '' : 's'}' : '${(weeks / 4.345).round()} meses';
  return 'cerca de $span (${_months[d.month - 1]}/${d.year})';
}

/// Grade com IMC, gasto, calorias, proteína, água e cintura.
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key, required this.metrics});

  final BodyMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final tiles = <Widget>[
      if (m.bmi != null)
        MetricTile(
          icon: Icons.monitor_weight_outlined,
          label: 'IMC',
          value: formatNumber(m.bmi!),
          caption: m.bmiLabel,
          color: bmiColor(m.bmi!),
        ),
      if (m.healthyMinKg != null)
        MetricTile(
          icon: Icons.straighten_rounded,
          label: 'Peso saudável',
          value: '${m.healthyMinKg!.ceil()}–${m.healthyMaxKg!.floor()} kg',
          caption: 'para a sua altura',
        ),
      if (m.calories != null)
        MetricTile(
          icon: Icons.restaurant_rounded,
          label: 'Calorias por dia',
          value: '${m.calories}',
          caption: 'gasto estimado: ${m.tdee} kcal',
          color: GmColors.red,
        ),
      if (m.proteinG != null)
        MetricTile(
          icon: Icons.egg_alt_outlined,
          label: 'Proteína por dia',
          value: '${m.proteinG} g',
          caption: 'carne, ovos, laticínios, feijão',
          color: GmColors.blue,
        ),
      if (m.waterL != null)
        MetricTile(
          icon: Icons.water_drop_outlined,
          label: 'Água por dia',
          value: '${formatNumber(m.waterL!)} L',
          caption: 'mais nos dias de treino',
          color: GmColors.blue,
        ),
      if (m.waistToHeight != null)
        MetricTile(
          icon: Icons.accessibility_new_rounded,
          label: 'Cintura ÷ altura',
          value: formatNumber(m.waistToHeight!, decimals: 2),
          caption: m.waistToHeight! < 0.5 ? 'abaixo de 0,5: ótimo' : 'o ideal é ficar abaixo de 0,5',
          color: m.waistToHeight! < 0.5 ? GmColors.green : GmColors.yellow,
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 560 ? 3 : 2;
      final w = (box.maxWidth - 10 * (cols - 1)) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    });
  }
}
