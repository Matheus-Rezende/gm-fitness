import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../update/update_ui.dart';
import 'cloud_sync.dart';

/// Mensagens da sincronização (barra no rodapé de qualquer tela).
final cloudMessengerKey = GlobalKey<ScaffoldMessengerState>();

String _when(DateTime? t) {
  if (t == null) return 'nunca';
  final l = t.toLocal();
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final hm = '${two(l.hour)}:${two(l.minute)}';
  if (l.year == now.year && l.month == now.month && l.day == now.day) return 'hoje às $hm';
  final y = now.subtract(const Duration(days: 1));
  if (l.year == y.year && l.month == y.month && l.day == y.day) return 'ontem às $hm';
  return '${two(l.day)}/${two(l.month)}/${l.year} às $hm';
}

/// Fica acima do app: pergunta qual versão vale quando a nuvem e o aparelho
/// têm dados diferentes, e mostra os avisos da sincronização.
class CloudPrompt extends StatefulWidget {
  const CloudPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<CloudPrompt> createState() => _CloudPromptState();
}

class _CloudPromptState extends State<CloudPrompt> {
  final _sync = CloudSync.instance;
  bool _asking = false;
  String? _shown;

  @override
  void initState() {
    super.initState();
    _sync.addListener(_onChange);
  }

  @override
  void dispose() {
    _sync.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final msg = _sync.message;
    if (msg != null && msg != _shown) {
      _shown = msg;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cloudMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
        _sync.clearMessage();
        _shown = null;
      });
    }
    if (_sync.pendingCloud != null && !_asking) {
      _asking = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
    }
  }

  Future<void> _ask() async {
    final ctx = updateNavigatorKey.currentContext;
    final cloud = _sync.pendingCloud;
    if (ctx == null || cloud == null) {
      _asking = false;
      return;
    }
    final state = AppScope.of(ctx);
    final cloudAt = DateTime.tryParse((cloud['savedAt'] as String?) ?? '');
    final choice = await showDialog<SyncChoice>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.cloud_sync_outlined),
        title: const Text('Qual progresso usar?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sua conta já tem um backup diferente do que está neste aparelho.'),
            const SizedBox(height: 14),
            _Option(
              icon: Icons.cloud_outlined,
              title: 'No Google Drive (${_when(cloudAt)})',
              subtitle: AppState.summaryOf(cloud),
            ),
            const SizedBox(height: 10),
            _Option(icon: Icons.phone_android_rounded, title: 'Neste aparelho', subtitle: state.dataSummary),
            const SizedBox(height: 12),
            Text('A versão que você não escolher será substituída.', style: Theme.of(c).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, SyncChoice.useDevice), child: const Text('Manter o do aparelho')),
          FilledButton(onPressed: () => Navigator.pop(c, SyncChoice.useCloud), child: const Text('Usar o do Drive')),
        ],
      ),
    );
    await _sync.resolve(choice ?? SyncChoice.useDevice);
    _asking = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleSmall),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bloco "Conta Google e backup" das configurações.
class CloudSection extends StatelessWidget {
  const CloudSection({super.key});

  Future<void> _confirmRestore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restaurar do Drive?'),
        content: const Text('Os dados deste aparelho serão trocados pelos do último backup da sua conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (ok == true) await CloudSync.instance.restoreNow();
  }

  @override
  Widget build(BuildContext context) {
    final sync = CloudSync.instance;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        if (!sync.supported) {
          return const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Backup na conta Google'),
            subtitle: Text('Ainda não disponível nesta versão do app.'),
          );
        }
        final u = sync.user;
        if (u == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salve seu progresso na sua conta Google', style: text.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Treinos, cargas, histórico, pesagens e configurações ficam guardados numa pasta escondida do '
                  'GM Fitness no seu Google Drive. Se trocar de celular ou apagar o app, é só entrar de novo.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: sync.busy ? null : sync.signIn,
                    icon: sync.busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const GoogleLogo(size: 20, onColor: true),
                    label: const Text('Entrar com Google'),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            ListTile(
              leading: GoogleUserCircleAvatar(identity: u),
              title: Text(u.displayName ?? u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: sync.busy
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Icon(Icons.cloud_done_outlined, color: scheme.primary),
              title: const Text('Backup automático ligado'),
              subtitle: Text('Último backup: ${_when(sync.lastBackup)}'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: sync.busy ? null : () => sync.backupNow(userAsked: true),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Fazer backup agora'),
                  ),
                  OutlinedButton.icon(
                    onPressed: sync.busy ? null : () => _confirmRestore(context),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('Restaurar'),
                  ),
                  TextButton(
                    onPressed: sync.busy ? null : sync.signOut,
                    style: TextButton.styleFrom(foregroundColor: GmColors.red),
                    child: const Text('Sair da conta'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Botão do primeiro acesso: entrar com a conta Google (restaura o progresso
/// se já houver backup) e o aviso de que, sem entrar, os dados ficam só no
/// aparelho.
class RestoreFromGoogleButton extends StatelessWidget {
  const RestoreFromGoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = CloudSync.instance;
    if (!sync.supported) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final u = sync.user;
        if (u != null) {
          return Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Conectado como ${u.email}. Seu progresso será salvo no Google Drive.',
                    style: text.bodySmall),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: sync.busy ? null : sync.signIn,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: sync.busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const GoogleLogo(size: 20),
              label: const Text('Entrar com Google'),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Entrando, seu progresso fica salvo na sua conta e volta se você trocar de celular. '
                    'Sem entrar, os dados ficam só neste aparelho e podem ser perdidos se o app for apagado.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


/// "G" colorido do Google, desenhado (usado nos botões de login, como pede a
/// identidade visual do Google).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20, this.onColor = false});

  final double size;

  /// Sobre botão preenchido: desenha num círculo branco para o G aparecer.
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final g = CustomPaint(size: Size.square(size), painter: _GPainter());
    if (!onColor) return g;
    return Container(
      padding: EdgeInsets.all(size * 0.12),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: g,
    );
  }
}

class _GPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4), _green = Color(0xFF34A853), _yellow = Color(0xFFFBBC05), _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final r = (s - stroke) / 2;
    final c = Offset(s / 2, s / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint p(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    double deg(double d) => d * math.pi / 180;
    // ângulos a partir do eixo x, sentido horário (como no canvas)
    canvas.drawArc(rect, deg(-45), deg(-90), false, p(_red)); // topo
    canvas.drawArc(rect, deg(-135), deg(-90), false, p(_yellow)); // esquerda
    canvas.drawArc(rect, deg(135), deg(-90), false, p(_green)); // baixo
    canvas.drawArc(rect, deg(45), deg(-45), false, p(_blue)); // direita, até o meio
    // barra horizontal azul
    final bar = Paint()..color = _blue;
    canvas.drawRect(Rect.fromLTRB(s / 2, s / 2 - stroke / 2, s / 2 + r + stroke / 2, s / 2 + stroke / 2), bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
