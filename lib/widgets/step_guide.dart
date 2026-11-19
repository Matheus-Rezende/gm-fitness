import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/gm_theme.dart';

/// Ponto marcado na ilustração, ligado a uma dica ("joelhos na direção dos pés").
/// x e y vão de 0 a 1 sobre a imagem.
class GuideCue {
  const GuideCue(this.x, this.y, this.text);

  final double x;
  final double y;
  final String text;
}

/// Seta mostrando para onde o corpo ou o peso se move.
class GuideArrow {
  const GuideArrow(this.x1, this.y1, this.x2, this.y2);

  final double x1, y1, x2, y2;
}

class GuideStep {
  const GuideStep({required this.image, required this.title, this.cues = const [], this.arrows = const [], this.wrong = false});

  final String image;
  final String title;
  final List<GuideCue> cues;
  final List<GuideArrow> arrows;

  /// Imagem de execução errada (moldura vermelha).
  final bool wrong;
}

class ExerciseGuide {
  const ExerciseGuide(this.steps);

  final List<GuideStep> steps;

  /// Passos do movimento (sem as imagens de erro).
  List<GuideStep> get moves => steps.where((s) => !s.wrong).toList();
}

/// Ilustrações passo a passo, carregadas de assets/guides.json.
class GuideRepo {
  GuideRepo._();

  static final instance = GuideRepo._();

  Map<String, ExerciseGuide>? _guides;
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/guides.json')) as Map<String, dynamic>;
      _guides = {
        for (final e in raw.entries)
          e.key: ExerciseGuide([
            for (final s in ((e.value as Map)['steps'] as List))
              GuideStep(
                image: 'assets/steps/${(s as Map)['img']}',
                title: (s['title'] as String?) ?? '',
                wrong: s['wrong'] == true,
                cues: [
                  for (final c in (s['cues'] as List? ?? const []))
                    GuideCue(((c as Map)['x'] as num).toDouble(), (c['y'] as num).toDouble(), c['t'] as String),
                ],
                arrows: [
                  for (final a in (s['arrows'] as List? ?? const []))
                    GuideArrow((a[0] as num).toDouble(), (a[1] as num).toDouble(), (a[2] as num).toDouble(),
                        (a[3] as num).toDouble()),
                ],
              ),
          ]),
      };
    } catch (_) {
      _guides = {};
    }
  }

  /// Guia do exercício, se já carregado e existente.
  ExerciseGuide? of(String exerciseId) => _guides?[exerciseId];

  bool get loaded => _guides != null;
}

/// Passos do exercício em ilustrações, com marcadores numerados, setas e um
/// botão para ver os passos em sequência, como um movimento.
class StepGuideView extends StatefulWidget {
  const StepGuideView({super.key, required this.guide});

  final ExerciseGuide guide;

  @override
  State<StepGuideView> createState() => _StepGuideViewState();
}

class _StepGuideViewState extends State<StepGuideView> {
  int _index = 0;
  Timer? _timer;

  List<GuideStep> get _steps => widget.guide.steps;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _go(int i) => setState(() => _index = i.clamp(0, _steps.length - 1));

  void _togglePlay() {
    if (_timer != null) {
      setState(() {
        _timer?.cancel();
        _timer = null;
      });
      return;
    }
    final moves = [for (var i = 0; i < _steps.length; i++) if (!_steps[i].wrong) i];
    if (moves.length < 2) return;
    var k = math.max(0, moves.indexOf(_index));
    setState(() {
      _index = moves[k];
      _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
        if (!mounted) return;
        k = (k + 1) % moves.length;
        setState(() => _index = moves[k]);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final step = _steps[_index];
    final playing = _timer != null;
    final canPlay = widget.guide.moves.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _go(_index + 1);
                if (v > 200) _go(_index - 1);
              },
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: step.wrong ? scheme.error : scheme.outlineVariant, width: step.wrong ? 3 : 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: playing ? 450 : 220),
                      child: Stack(
                        key: ValueKey(_index),
                        fit: StackFit.expand,
                        children: [
                          Image.asset(step.image, fit: BoxFit.contain),
                          if (!playing) CustomPaint(painter: _GuidePainter(step)),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _Badge(
                              text: step.wrong ? 'Errado' : 'Passo ${_moveNumber(_index)}',
                              color: step.wrong ? scheme.error : GmColors.ink,
                              icon: step.wrong ? Icons.close_rounded : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'Passo anterior',
              onPressed: _index == 0 || playing ? null : () => _go(_index - 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    GestureDetector(
                      onTap: playing ? null : () => _go(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? (_steps[i].wrong ? scheme.error : scheme.primary)
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (canPlay)
              TextButton.icon(
                onPressed: _togglePlay,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(playing ? 'Pausar' : 'Ver movimento'),
              ),
            IconButton(
              tooltip: 'Próximo passo',
              onPressed: _index >= _steps.length - 1 || playing ? null : () => _go(_index + 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        Text(step.title, style: text.titleMedium?.copyWith(color: step.wrong ? scheme.error : null)),
        const SizedBox(height: 6),
        for (final (i, c) in step.cues.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pin(number: i + 1, wrong: step.wrong, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 1), child: Text(c.text))),
              ],
            ),
          ),
      ],
    );
  }

  int _moveNumber(int index) => _steps.take(index + 1).where((s) => !s.wrong).length;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16, color: Colors.white),
            Text(text,
                style: const TextStyle(
                    fontFamily: display, fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          ],
        ),
      );
}

class _Pin extends StatelessWidget {
  const _Pin({required this.number, this.wrong = false, this.size = 26});

  final int number;
  final bool wrong;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: wrong ? Theme.of(context).colorScheme.error : GmColors.yellow,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text('$number',
            style: TextStyle(
                fontFamily: display,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.55,
                color: wrong ? Colors.white : GmColors.ink)),
      );
}

/// Setas e marcadores numerados por cima da ilustração.
class _GuidePainter extends CustomPainter {
  _GuidePainter(this.step);

  final GuideStep step;

  @override
  void paint(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = GmColors.red
      ..strokeWidth = size.width * 0.012
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final halo = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.028
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final a in step.arrows) {
      final p1 = Offset(a.x1 * size.width, a.y1 * size.height);
      final p2 = Offset(a.x2 * size.width, a.y2 * size.height);
      final dir = p2 - p1;
      final len = dir.distance;
      if (len < 1) continue;
      final u = dir / len;
      final n = Offset(-u.dy, u.dx);
      final head = size.width * 0.04;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..moveTo(p2.dx - u.dx * head + n.dx * head * 0.7, p2.dy - u.dy * head + n.dy * head * 0.7)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p2.dx - u.dx * head - n.dx * head * 0.7, p2.dy - u.dy * head - n.dy * head * 0.7);
      canvas.drawPath(path, halo);
      canvas.drawPath(path, arrowPaint);
    }
    final r = size.width * 0.04;
    for (final (i, c) in step.cues.indexed) {
      final o = Offset(c.x * size.width, c.y * size.height);
      canvas.drawCircle(o + const Offset(0, 1.5), r + 2, Paint()..color = Colors.black26);
      canvas.drawCircle(o, r + 2, Paint()..color = Colors.white);
      canvas.drawCircle(o, r, Paint()..color = step.wrong ? GmColors.red : GmColors.yellow);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontFamily: display,
            fontWeight: FontWeight.w800,
            fontSize: r * 1.3,
            color: step.wrong ? Colors.white : GmColors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.step != step;
}
