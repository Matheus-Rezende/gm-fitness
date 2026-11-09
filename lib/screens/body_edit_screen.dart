import 'package:flutter/material.dart';

import '../models/body.dart';
import '../state/app_state.dart';
import '../widgets/body_widgets.dart';

/// Campos do formulário de corpo, usados na introdução e no perfil.
class BodyFormData {
  BodyFormData();

  factory BodyFormData.from(AppState state) {
    final d = BodyFormData();
    final b = state.body;
    final age = b.ageAt(DateTime.now());
    if (age != null) d.age.text = '$age';
    if (b.heightCm != null) d.height.text = formatNumber(b.heightCm!, decimals: 0);
    if (state.currentWeight != null) d.weight.text = formatNumber(state.currentWeight!);
    if (b.waistCm != null) d.waist.text = formatNumber(b.waistCm!);
    if (b.targetKg != null) d.target.text = formatNumber(b.targetKg!);
    d.goal = b.goal;
    d.activity = b.activity;
    return d;
  }

  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  final waist = TextEditingController();
  final target = TextEditingController();
  Goal? goal;
  Activity? activity;

  double? get weightKg => readNumber(weight.text);
  double? get heightCm => readNumber(height.text);

  static final ageCheck = rangeValidator(12, 100, 'anos');
  static final heightCheck = rangeValidator(120, 230, 'cm');
  static final weightCheck = rangeValidator(30, 300, 'kg');
  static final waistCheck = rangeValidator(40, 200, 'cm', optional: true);

  String? targetCheck(String s) {
    final base = rangeValidator(30, 300, 'kg', optional: true)(s);
    if (base != null || s.trim().isEmpty) return base;
    final h = heightCm;
    if (h == null || h < 120) return null;
    return targetProblem(readNumber(s)!, h);
  }

  /// Os dados básicos (idade, altura e peso) estão válidos.
  bool get basicsValid =>
      ageCheck(age.text) == null && heightCheck(height.text) == null && weightCheck(weight.text) == null;

  BodyData toBody(BodyData previous) {
    final a = int.tryParse(age.text.trim());
    final w = readNumber(waist.text);
    final t = readNumber(target.text);
    return BodyData(
      birthYear: a == null ? previous.birthYear : DateTime.now().year - a,
      heightCm: heightCm ?? previous.heightCm,
      waistCm: w,
      targetKg: t,
      goal: goal ?? previous.goal,
      activity: activity ?? previous.activity,
    );
  }

  /// Salva os dados e registra o peso se ele mudou.
  Future<void> save(AppState state) async {
    await state.setBody(toBody(state.body));
    final w = weightKg;
    if (w != null && weightCheck(weight.text) == null && w != state.currentWeight) await state.addWeight(w);
  }

  void dispose() {
    for (final c in [age, height, weight, waist, target]) {
      c.dispose();
    }
  }
}

/// Edição dos dados do corpo e do objetivo.
class BodyEditScreen extends StatefulWidget {
  const BodyEditScreen({super.key});

  @override
  State<BodyEditScreen> createState() => _BodyEditScreenState();
}

class _BodyEditScreenState extends State<BodyEditScreen> {
  final _form = GlobalKey<FormState>();
  late final BodyFormData _data = BodyFormData.from(AppScope.read(context));

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await _data.save(AppScope.read(context));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Corpo e objetivo')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _save, child: const Text('Salvar')),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Medidas', style: text.titleLarge),
            const SizedBox(height: 12),
            BodyBasicsFields(data: _data, onChanged: () => setState(() {})),
            const SizedBox(height: 24),
            Text('Objetivo', style: text.titleLarge),
            const SizedBox(height: 12),
            GoalPicker(value: _data.goal, onChanged: (g) => setState(() => _data.goal = g)),
            const SizedBox(height: 16),
            Text('Fora da academia, você é', style: text.titleMedium),
            const SizedBox(height: 8),
            ActivityPicker(value: _data.activity, onChanged: (a) => setState(() => _data.activity = a)),
            const SizedBox(height: 20),
            TargetField(data: _data),
          ],
        ),
      ),
    );
  }
}

/// Idade, altura, peso e cintura.
class BodyBasicsFields extends StatelessWidget {
  const BodyBasicsFields({super.key, required this.data, this.onChanged});

  final BodyFormData data;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    void changed(String _) => onChanged?.call();
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumberField(
                controller: data.age,
                label: 'Idade',
                suffix: 'anos',
                decimals: false,
                validator: BodyFormData.ageCheck,
                onChanged: changed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberField(
                controller: data.height,
                label: 'Altura',
                suffix: 'cm',
                decimals: false,
                validator: BodyFormData.heightCheck,
                onChanged: changed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NumberField(
                controller: data.weight,
                label: 'Peso atual',
                suffix: 'kg',
                validator: BodyFormData.weightCheck,
                onChanged: changed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberField(
                controller: data.waist,
                label: 'Cintura (opcional)',
                suffix: 'cm',
                helper: 'Na altura do umbigo',
                validator: BodyFormData.waistCheck,
                onChanged: changed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Peso-meta opcional, com a faixa saudável para a altura.
class TargetField extends StatelessWidget {
  const TargetField({super.key, required this.data});

  final BodyFormData data;

  @override
  Widget build(BuildContext context) {
    final h = data.heightCm;
    final range = h == null || h < 120 ? null : healthyRange(h);
    return NumberField(
      controller: data.target,
      label: 'Peso que quer alcançar (opcional)',
      suffix: 'kg',
      helper: range == null
          ? null
          : 'Faixa saudável para a sua altura: ${range.$1.ceil()} a ${range.$2.floor()} kg (IMC de 18,5 a 24,9).',
      validator: data.targetCheck,
    );
  }
}
