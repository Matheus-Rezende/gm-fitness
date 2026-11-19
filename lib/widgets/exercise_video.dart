import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'step_guide.dart';

/// Exercícios que têm vídeo gravado (homem em `<id>_m.mp4`, mulher em `<id>_f.mp4`).
const kExerciseVideos = <String>{
  'abdominal_bicicleta',
  'abdominal_supra',
  'abducao_em_pe_elastico',
  'abducao_polia',
  'agachamento_barra',
  'agachamento_bulgaro',
  'agachamento_goblet',
  'agachamento_smith',
  'barra_fixa_assistida',
  'bicicleta_ergometrica',
  'cadeira_abdutora',
  'cadeira_adutora',
  'cadeira_extensora',
  'cadeira_flexora',
  'caminhada_esteira',
  'caminhada_fazendeiro',
  'caminhada_inclinada',
  'coice_polia',
  'coice_quatro_apoios',
  'corrida_esteira',
  'corrida_intervalada',
  'crossover',
  'dead_bug',
  'desenvolvimento_halteres',
  'elevacao_lateral',
  'elevacao_pelvica',
  'face_pull',
  'flexao_inclinada',
  'hiperextensao_lombar',
  'leg_press_45',
  'mesa_flexora',
  'panturrilha_em_pe',
  'panturrilha_sentado',
  'perdigueiro',
  'ponte_gluteo',
  'prancha',
  'prancha_joelhos',
  'prancha_lateral',
  'pull_through',
  'pulldown_bracos_estendidos',
  'puxada_frontal',
  'remada_curvada_barra',
  'remada_curvada_halteres',
  'remada_sentada',
  'remada_unilateral',
  'remo_ergometro',
  'rosca_direta_barra',
  'rosca_direta_halteres',
  'rosca_martelo',
  'rosca_polia',
  'stiff_barra',
  'stiff_halteres',
  'subida_banco',
  'supino_inclinado_halteres',
  'supino_reto_halteres',
  'triceps_corda',
  'triceps_polia',
  'voador',
  'voador_invertido',
};

/// Exercícios que, por enquanto, só têm o vídeo do homem (usado também para a mulher).
const kExerciseVideosMaleOnly = <String>{
  'voador_invertido',
};

/// Caminho do vídeo do exercício para o sexo do usuário, ou null se não houver vídeo.
String? exerciseVideoAsset(String exerciseId, {required bool male}) {
  if (!kExerciseVideos.contains(exerciseId)) return null;
  final useMale = male || kExerciseVideosMaleOnly.contains(exerciseId);
  return 'assets/videos/${exerciseId}_${useMale ? 'm' : 'f'}.mp4';
}

/// Vídeo em loop, sem som, que começa sozinho. Toque para pausar ou continuar.
/// Se o vídeo não puder ser aberto (ou em testes), mostra [fallback].
class ExerciseVideo extends StatefulWidget {
  const ExerciseVideo({super.key, required this.asset, required this.fallback, this.controls = true});

  final String asset;
  final Widget fallback;

  /// Toque para pausar e barra de progresso (desligados na tela de boas-vindas).
  final bool controls;

  @override
  State<ExerciseVideo> createState() => _ExerciseVideoState();
}

class _ExerciseVideoState extends State<ExerciseVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    if (_inTest) {
      _failed = true;
      return;
    }
    final c = VideoPlayerController.asset(
      widget.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = c;
    c.initialize().then((_) async {
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (mounted) setState(() {});
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
    c.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  void _toggle() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    final c = _controller;
    final scheme = Theme.of(context).colorScheme;
    final ready = c != null && c.value.isInitialized;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: ready ? c.value.aspectRatio : 16 / 9,
        child: ready && !widget.controls
            ? VideoPlayer(c)
            : ready
            ? GestureDetector(
                onTap: _toggle,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(c),
                    if (!c.value.isPlaying)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: scheme.primary,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                color: scheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}

/// Mostra o vídeo real do exercício quando existe, com a opção de ver o
/// boneco (desenho 2D com os músculos trabalhados). Sem vídeo, só o boneco.
class ExerciseMedia extends StatefulWidget {
  const ExerciseMedia({super.key, required this.videoAsset, required this.figure, this.guide, this.male = true});

  final String? videoAsset;
  final Widget figure;

  /// Ilustrações passo a passo, opção ao lado do vídeo.
  final ExerciseGuide? guide;
  final bool male;

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

enum _Media { steps, video, figure }

class _ExerciseMediaState extends State<ExerciseMedia> {
  _Media? _picked;

  @override
  Widget build(BuildContext context) {
    final asset = widget.videoAsset;
    final guide = widget.guide;
    // O vídeo vem primeiro; as ilustrações são a segunda opção. O boneco 3D só
    // aparece enquanto o exercício não tem vídeo nem ilustração.
    final options = [
      if (asset != null) _Media.video,
      if (guide != null) _Media.steps,
      if (asset == null && guide == null) _Media.figure,
    ];
    final mode = options.contains(_picked) ? _picked! : options.first;
    Widget body(_Media m) => switch (m) {
          _Media.steps => StepGuideView(guide: guide!, male: widget.male),
          _Media.video => ExerciseVideo(key: ValueKey(asset), asset: asset!, fallback: widget.figure),
          _Media.figure => widget.figure,
        };
    if (options.length == 1) return body(mode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_Media>(
            showSelectedIcon: false,
            segments: [
              for (final m in options)
                switch (m) {
                  _Media.steps =>
                    const ButtonSegment(value: _Media.steps, icon: Icon(Icons.burst_mode_outlined), label: Text('Passos')),
                  _Media.video =>
                    const ButtonSegment(value: _Media.video, icon: Icon(Icons.videocam_outlined), label: Text('Vídeo')),
                  _Media.figure =>
                    const ButtonSegment(value: _Media.figure, icon: Icon(Icons.accessibility_new), label: Text('Boneco 3D')),
                },
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => _picked = s.first),
          ),
        ),
        const SizedBox(height: 8),
        body(mode),
      ],
    );
  }
}

/// Vídeo da tela de boas-vindas: ele e ela lado a lado fazendo o mesmo exercício.
class WelcomeDuoVideo extends StatelessWidget {
  const WelcomeDuoVideo({super.key, required this.fallback});

  static const asset = 'assets/videos/onboarding_duo.mp4';

  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          ExerciseVideo(asset: asset, fallback: fallback, controls: false),
        ],
      ),
    );
  }
}
