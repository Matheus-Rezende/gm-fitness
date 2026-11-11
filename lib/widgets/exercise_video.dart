import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Exercícios que têm vídeo gravado (homem em `<id>_m.mp4`, mulher em `<id>_f.mp4`).
const kExerciseVideos = <String>{
  'abdominal_supra',
  'abducao_em_pe_elastico',
  'agachamento_goblet',
  'bicicleta_ergometrica',
  'cadeira_abdutora',
  'cadeira_extensora',
  'cadeira_flexora',
  'caminhada_esteira',
  'caminhada_inclinada',
  'coice_quatro_apoios',
  'dead_bug',
  'desenvolvimento_halteres',
  'elevacao_lateral',
  'face_pull',
  'flexao_inclinada',
  'leg_press_45',
  'panturrilha_em_pe',
  'perdigueiro',
  'ponte_gluteo',
  'prancha',
  'prancha_joelhos',
  'prancha_lateral',
  'puxada_frontal',
  'remada_sentada',
  'remada_unilateral',
  'rosca_direta_halteres',
  'rosca_martelo',
  'stiff_halteres',
  'subida_banco',
  'supino_inclinado_halteres',
  'supino_reto_halteres',
  'triceps_corda',
  'triceps_polia',
};

/// Caminho do vídeo do exercício para o sexo do usuário, ou null se não houver vídeo.
String? exerciseVideoAsset(String exerciseId, {required bool male}) {
  if (!kExerciseVideos.contains(exerciseId)) return null;
  return 'assets/videos/${exerciseId}_${male ? 'm' : 'f'}.mp4';
}

/// Vídeo em loop, sem som, que começa sozinho. Toque para pausar ou continuar.
/// Se o vídeo não puder ser aberto (ou em testes), mostra [fallback].
class ExerciseVideo extends StatefulWidget {
  const ExerciseVideo({super.key, required this.asset, required this.fallback});

  final String asset;
  final Widget fallback;

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
        child: ready
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

/// Mostra o vídeo do exercício quando existe, com opção de ver o boneco 3D.
class ExerciseMedia extends StatefulWidget {
  const ExerciseMedia({super.key, required this.videoAsset, required this.figure});

  final String? videoAsset;
  final Widget figure;

  @override
  State<ExerciseMedia> createState() => _ExerciseMediaState();
}

class _ExerciseMediaState extends State<ExerciseMedia> {
  bool _showVideo = true;

  @override
  Widget build(BuildContext context) {
    final asset = widget.videoAsset;
    if (asset == null) return widget.figure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.videocam_outlined), label: Text('Vídeo')),
              ButtonSegment(value: false, icon: Icon(Icons.accessibility_new), label: Text('Boneco 3D')),
            ],
            selected: {_showVideo},
            onSelectionChanged: (s) => setState(() => _showVideo = s.first),
          ),
        ),
        const SizedBox(height: 8),
        if (_showVideo) ExerciseVideo(key: ValueKey(asset), asset: asset, fallback: widget.figure) else widget.figure,
      ],
    );
  }
}
