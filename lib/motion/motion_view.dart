import 'package:flutter/material.dart';

import 'figure_painter.dart';
import 'motion_clip.dart';

FigurePalette paletteOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? FigurePalette.dark : FigurePalette.light;

/// Animação do exercício com fase atual, músculos em destaque, percurso,
/// controle de velocidade, tela cheia e as poses-chave.
class MotionView extends StatefulWidget {
  const MotionView({
    super.key,
    required this.clip,
    this.style = const FigureStyle(),
    this.showControls = true,
    this.showKeyPoses = true,
    this.fullscreen = false,
  });

  final MotionClip clip;
  final FigureStyle style;
  final bool showControls;
  final bool showKeyPoses;
  final bool fullscreen;

  @override
  State<MotionView> createState() => _MotionViewState();
}

class _MotionViewState extends State<MotionView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _speed = 1.0;
  bool _playing = true;
  late bool _muscles = widget.style.showMuscles;
  late bool _path = widget.style.showPath;

  Duration _period() {
    final ms = widget.clip.duration.inMilliseconds / _speed;
    return Duration(milliseconds: ms.round().clamp(200, 60000));
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _period());
    if (MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).disableAnimations) {
      _playing = false;
      _ctrl.value = widget.clip.keyTimes[2];
    } else {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(MotionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip != widget.clip) {
      _ctrl.duration = _period();
      _ctrl.value = 0;
      if (_playing) _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    });
  }

  void _setSpeed(double s) {
    setState(() {
      _speed = s;
      _ctrl.duration = _period();
      if (_playing) _ctrl.repeat();
    });
  }

  void _jumpTo(double t) {
    setState(() {
      _playing = false;
      _ctrl.stop();
      _ctrl.value = t;
    });
  }

  FigureStyle get _style => FigureStyle(
        male: widget.style.male,
        primary: widget.style.primary,
        secondary: widget.style.secondary,
        showMuscles: _muscles,
        showPath: _path,
      );

  void _openFullscreen() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenMotion(clip: widget.clip, style: _style),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = paletteOf(context);
    final clip = widget.clip;
    final hasMuscles = widget.style.primary.isNotEmpty || widget.style.secondary.isNotEmpty;

    final canvas = ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 20),
      child: AspectRatio(
        aspectRatio: clip.aspectRatio,
        child: GestureDetector(
          onTap: widget.showControls ? _toggle : null,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => CustomPaint(
                painter: FigurePainter(clip: clip, time: _ctrl.value, palette: palette, style: _style),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.showControls) return canvas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            canvas,
            Positioned(
              left: 10,
              top: 10,
              right: 56,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surface.withAlpha(220),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      clip.phaseAt(_ctrl.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.fullscreen)
              Positioned(
                right: 6,
                top: 6,
                child: IconButton(
                  tooltip: 'Ver em tela cheia',
                  onPressed: _openFullscreen,
                  style: IconButton.styleFrom(backgroundColor: scheme.surface.withAlpha(220)),
                  icon: const Icon(Icons.open_in_full_rounded, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filled(
              tooltip: _playing ? 'Pausar' : 'Reproduzir',
              onPressed: _toggle,
              icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in const [0.5, 1.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(s == 1.0 ? 'Normal' : 'Lento'),
                          selected: _speed == s,
                          onSelected: (_) => _setSpeed(s),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (hasMuscles)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('Músculos'),
                          selected: _muscles,
                          onSelected: (v) => setState(() => _muscles = v),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    FilterChip(
                      label: const Text('Percurso'),
                      selected: _path,
                      onSelected: (v) => setState(() => _path = v),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_muscles && hasMuscles)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                _Dot(color: const Color(0xFFFFB400).withAlpha(200)),
                const SizedBox(width: 6),
                Text('Músculo principal', style: theme.textTheme.bodySmall),
                const SizedBox(width: 14),
                _Dot(color: const Color(0xFFFFB400).withAlpha(90)),
                const SizedBox(width: 6),
                Text('Auxiliares', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        if (widget.showKeyPoses) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _KeyPose(
                    clip: clip,
                    time: clip.keyTimes[i],
                    label: const ['Início', 'Meio', 'Fim do movimento'][i],
                    style: _style,
                    onTap: () => _jumpTo(clip.keyTimes[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _KeyPose extends StatelessWidget {
  const _KeyPose({required this.clip, required this.time, required this.label, required this.style, required this.onTap});

  final MotionClip clip;
  final double time;
  final String label;
  final FigureStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: clip.aspectRatio,
              child: CustomPaint(
                painter: FigurePainter(
                  clip: clip,
                  time: time,
                  palette: paletteOf(context),
                  style: FigureStyle(male: style.male, primary: style.primary, secondary: style.secondary, showPath: false),
                  ghost: false,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}

class _FullscreenMotion extends StatelessWidget {
  const _FullscreenMotion({required this.clip, required this.style});

  final MotionClip clip;
  final FigureStyle style;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(clip.name)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: MotionView(clip: clip, style: style, fullscreen: true),
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura estática do exercício (pose mais distante do início).
class MotionThumb extends StatelessWidget {
  const MotionThumb({super.key, required this.clip, this.size = 56, this.male = false});

  final MotionClip? clip;
  final double size;
  final bool male;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = clip;
    if (c == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.fitness_center, color: scheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: FigurePainter(
              clip: c,
              time: c.keyTimes[2],
              palette: paletteOf(context),
              style: FigureStyle(male: male, showPath: false, showMuscles: false),
              ghost: false,
            ),
          ),
        ),
      ),
    );
  }
}
