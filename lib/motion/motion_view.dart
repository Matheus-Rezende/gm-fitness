import 'package:flutter/material.dart';

import 'figure_painter.dart';
import 'motion_clip.dart';

FigurePalette paletteOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? FigurePalette.dark : FigurePalette.light;

/// Animação em loop do exercício, com fase atual, pausa e velocidade.
class MotionView extends StatefulWidget {
  const MotionView({super.key, required this.clip, this.showControls = true});

  final MotionClip clip;
  final bool showControls;

  @override
  State<MotionView> createState() => _MotionViewState();
}

class _MotionViewState extends State<MotionView> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _speed = 1.0;
  bool _playing = true;

  Duration _period() {
    final ms = widget.clip.duration.inMilliseconds / _speed;
    return Duration(milliseconds: ms.round().clamp(200, 60000));
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _period())..repeat();
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = paletteOf(context);
    final clip = widget.clip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: clip.aspectRatio,
            child: GestureDetector(
              onTap: widget.showControls ? _toggle : null,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => CustomPaint(
                    painter: FigurePainter(clip: clip, time: _ctrl.value, palette: palette),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.showControls)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: _playing ? 'Pausar' : 'Reproduzir',
                  onPressed: _toggle,
                  icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) => Text(
                      clip.phaseAt(_ctrl.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary),
                    ),
                  ),
                ),
                for (final s in const [0.5, 1.0])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(s == 1.0 ? '1x' : '0,5x'),
                      selected: _speed == s,
                      onSelected: (_) => _setSpeed(s),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Miniatura estática do exercício (um quadro do meio do movimento).
class MotionThumb extends StatelessWidget {
  const MotionThumb({super.key, required this.clip, this.size = 56});

  final MotionClip? clip;
  final double size;

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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.fitness_center, color: scheme.onSurfaceVariant),
      );
    }
    var t = 0.45;
    if (c.phases.length >= 3 && c.frameCount > 0) {
      t = c.phases[2].start / c.frameCount;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: CustomPaint(painter: FigurePainter(clip: c, time: t, palette: paletteOf(context))),
        ),
      ),
    );
  }
}
