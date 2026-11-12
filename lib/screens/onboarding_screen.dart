import 'package:flutter/material.dart';

import '../cloud/cloud_ui.dart';
import '../models/body.dart';
import '../models/preset.dart';
import '../models/workout_entry.dart';
import '../motion/figure_painter.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/body_shape_icon.dart';
import '../widgets/exercise_video.dart';
import '../widgets/body_widgets.dart';
import '../widgets/brand.dart';
import 'body_edit_screen.dart';

/// Primeira abertura: escolhe para quem é o treino e o formato do corpo.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  final _name = TextEditingController();
  final _body = BodyFormData();
  final _bodyForm = GlobalKey<FormState>();
  final _goalForm = GlobalKey<FormState>();
  int _page = 0;
  String? _sex;
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  void _go(int page) {
    setState(() => _page = page);
    _pages.animateToPage(page, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _finish(BodyPreset? preset) async {
    if (_saving) return;
    setState(() => _saving = true);
    final state = AppScope.read(context);
    await state.setProfile(sex: _sex ?? 'F', name: _name.text);
    if (_body.basicsValid) {
      if (_body.targetCheck(_body.target.text) != null) _body.target.clear();
      await _body.save(state);
    } else {
      await state.setBody(state.body.copyWith(goal: _body.goal, activity: _body.activity));
    }
    if (preset != null) await state.applyPreset(preset, replace: true);
    await state.setProfile(onboarded: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => _go(_page - 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const GmLogo(size: 36),
                  const Spacer(),
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(left: 6),
                      width: i == _page ? 22 : 7,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? GmColors.cycle[i % GmColors.cycle.length]
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Welcome(onNext: () => _go(1)),
                  _SexPage(
                    sex: _sex,
                    name: _name,
                    onPick: (s) => setState(() => _sex = s),
                    onNext: _sex == null ? null : () => _go(2),
                  ),
                  _AboutPage(
                    formKey: _bodyForm,
                    data: _body,
                    onChanged: () => setState(() {}),
                    onNext: _body.basicsValid ? () => _go(3) : null,
                    onSkip: () => _go(3),
                  ),
                  _GoalPage(
                    formKey: _goalForm,
                    data: _body,
                    showTarget: _body.basicsValid,
                    onChanged: () => setState(() {}),
                    onNext: () {
                      if (!(_goalForm.currentState?.validate() ?? true)) return;
                      _go(_body.basicsValid ? 4 : 5);
                    },
                  ),
                  _StartPage(data: _body, sex: _sex ?? 'F', onNext: () => _go(5)),
                  _ShapePage(sex: _sex ?? 'F', saving: _saving, onPick: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _pageCount = 6;

class _AboutPage extends StatelessWidget {
  const _AboutPage({
    required this.formKey,
    required this.data,
    required this.onChanged,
    required this.onNext,
    required this.onSkip,
  });

  final GlobalKey<FormState> formKey;
  final BodyFormData data;
  final VoidCallback onChanged;
  final VoidCallback? onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text('Sobre você', style: text.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Com a idade, a altura e o peso, o app calcula seu ponto de partida e acompanha a sua evolução. '
            'Os dados ficam só no seu celular.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 20),
          BodyBasicsFields(data: data, onChanged: onChanged),
          const SizedBox(height: 24),
          FilledButton(onPressed: onNext, child: const Text('Continuar')),
          const SizedBox(height: 4),
          TextButton(onPressed: onSkip, child: const Text('Prefiro não informar agora')),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.formKey,
    required this.data,
    required this.showTarget,
    required this.onChanged,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final BodyFormData data;
  final bool showTarget;
  final VoidCallback onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text('Qual é o seu objetivo?', style: text.headlineLarge),
          const SizedBox(height: 16),
          GoalPicker(
            value: data.goal,
            onChanged: (g) {
              data.goal = g;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          Text('Fora da academia, você é', style: text.titleMedium),
          const SizedBox(height: 8),
          ActivityPicker(
            value: data.activity,
            onChanged: (a) {
              data.activity = a;
              onChanged();
            },
          ),
          if (showTarget && data.goal != null && data.goal != Goal.health) ...[
            const SizedBox(height: 20),
            TargetField(data: data),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: data.goal == null ? null : onNext, child: const Text('Continuar')),
        ],
      ),
    );
  }
}

class _StartPage extends StatelessWidget {
  const _StartPage({required this.data, required this.sex, required this.onNext});

  final BodyFormData data;
  final String sex;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valid = data.basicsValid;
    final body = data.toBody(const BodyData());
    final m = BodyMetrics.compute(data: body, weightKg: valid ? data.weightKg : null, sex: sex, trainingDays: 5);
    final goal = data.goal ?? Goal.health;
    final target = body.targetKg;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Seu ponto de partida', style: text.headlineLarge),
        const SizedBox(height: 8),
        Text('Objetivo: ${goal.label.toLowerCase()}.', style: text.titleMedium),
        const SizedBox(height: 16),
        if (valid) MetricsGrid(metrics: m),
        if (valid && m.weeksToTarget != null && target != null && m.weeksToTarget! > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(16)),
            child: Text(
              'Num ritmo saudável (${formatKg(m.weeklyChangeKg!.abs()).replaceAll(' kg', '')} kg por semana), '
              'você chega a ${formatKg(target)} em ${etaText(m.weeksToTarget!)}.',
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
        if (!m.adult)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Para menores de 18 anos, calorias e metas de peso devem ser definidas com um médico ou nutricionista. '
              'Os treinos do app servem para todas as idades a partir de 12 anos, com cargas leves e boa técnica.',
              style: text.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'São estimativas para orientar. Um nutricionista ou médico ajusta esses números para você.',
          style: text.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onNext, child: const Text('Escolher meu treino')),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = AppScope.of(context);
    final clip = state.motions['squat_goblet'];
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  WelcomeDuoVideo(
                    fallback: clip == null
                        ? const SizedBox(height: 200)
                        : MotionView(
                            clip: clip,
                            style: const FigureStyle(primary: {'quadriceps'}, secondary: {'gluteos'}),
                            showControls: false,
                          ),
                  ),
                  const SizedBox(height: 28),
                  Text('Treino certo\ndesde o primeiro dia', style: text.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    'Cada exercício mostra o movimento, os músculos que trabalham e os erros mais comuns. '
                    'Tudo funciona sem internet.',
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  const PlateStripe(),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: onNext, child: const Text('Começar')),
              ),
              const SizedBox(height: 12),
              const RestoreFromGoogleButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SexPage extends StatelessWidget {
  const _SexPage({required this.sex, required this.name, required this.onPick, required this.onNext});

  final String? sex;
  final TextEditingController name;
  final ValueChanged<String> onPick;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Para quem é o treino?', style: text.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Os planos por formato de corpo e o boneco das animações mudam conforme o corpo masculino ou feminino.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _SexCard(label: 'Feminino', value: 'F', selected: sex == 'F', onTap: () => onPick('F'))),
              const SizedBox(width: 12),
              Expanded(child: _SexCard(label: 'Masculino', value: 'M', selected: sex == 'M', onTap: () => onPick('M'))),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Como quer ser chamado? (opcional)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onNext, child: const Text('Continuar')),
          ),
        ],
      ),
    );
  }
}

class _SexCard extends StatelessWidget {
  const _SexCard({required this.label, required this.value, required this.selected, required this.onTap});

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = AppScope.of(context);
    final clip = state.motions['lateral_raise'];
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 3 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 0.9,
                      child: Image.asset(
                        'assets/onboarding/sex_${value == 'M' ? 'm' : 'f'}.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => clip == null
                            ? const SizedBox.shrink()
                            : CustomPaint(
                        painter: FigurePainter(
                          clip: clip,
                          time: clip.keyTimes[2],
                          palette: paletteOf(context),
                          style: FigureStyle(male: value == 'M', showPath: false, showMuscles: false),
                          ghost: false,
                        ),
                      ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(label, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapePage extends StatelessWidget {
  const _ShapePage({required this.sex, required this.saving, required this.onPick});

  final String sex;
  final bool saving;
  final Future<void> Function(BodyPreset?) onPick;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shapes = state.presets.where((p) => p.sex == sex && p.shape != 'iniciante').toList();
    BodyPreset? five;
    BodyPreset? three;
    for (final p in state.presets) {
      if (p.shape == 'iniciante' && p.sex == sex) five = p;
      if (p.shape == 'iniciante' && p.sex == 'both') three = p;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Qual formato parece mais com o seu corpo?', style: text.headlineLarge),
        const SizedBox(height: 8),
        Text('Olhe para a largura dos ombros, da cintura e do quadril. Dá para trocar depois.', style: text.bodyMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            for (final (i, p) in shapes.indexed)
              Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: saving ? null : () => onPick(p),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: GmColors.cycle[i % 4].withAlpha(36),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: BodyShapeIcon(shape: p.shape, color: GmColors.cycle[i % 4]),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(p.name, style: text.titleMedium),
                        Text(p.summary.split('.').first, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (five != null)
          FilledButton.icon(
            onPressed: saving ? null : () => onPick(five),
            icon: const Icon(Icons.directions_walk_rounded),
            label: const Text('Nunca treinei ou não sei meu formato'),
          ),
        if (five != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text('Começa com o plano Primeiros passos: 5 dias por semana, de segunda a sexta.',
                style: text.bodySmall, textAlign: TextAlign.center),
          ),
        if (three != null)
          OutlinedButton(
            onPressed: saving ? null : () => onPick(three),
            child: const Text('Prefiro começar com 3 dias por semana'),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: saving ? null : () => onPick(null),
          child: const Text('Pular e montar meu treino sozinho'),
        ),
      ],
    );
  }
}
