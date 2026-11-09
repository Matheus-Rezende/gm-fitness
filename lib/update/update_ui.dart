import 'package:flutter/material.dart';

import '../theme/gm_theme.dart';
import '../version.dart';
import 'updater.dart';

/// Procura atualizações ao abrir o app e ao voltar para ele, e avisa quando há
/// uma versão nova.
class UpdateWatcher extends StatefulWidget {
  const UpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends State<UpdateWatcher> with WidgetsBindingObserver {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final up = Updater.instance;
    if (!up.supported || _showing) return;
    final info = await up.check();
    if (info == null || !mounted || _showing || await up.isSnoozed(info)) return;
    if (!mounted) return;
    _showing = true;
    final later = await showUpdateSheet(context);
    _showing = false;
    if (later) await up.snooze(info);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Mostra a versão nova com as novidades. Retorna true se a pessoa escolheu "Depois".
Future<bool> showUpdateSheet(BuildContext context) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _UpdateSheet(),
  );
  return r ?? true;
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet();

  @override
  Widget build(BuildContext context) {
    final up = Updater.instance;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: up,
      builder: (context, _) {
        final u = up.available;
        if (u == null) {
          return const SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Text('O app está atualizado.')));
        }
        final busy = up.stage == UpdateStage.downloading || up.stage == UpdateStage.installing;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: GmColors.yellow, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.system_update_rounded, color: GmColors.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nova versão ${u.version}', style: text.headlineSmall),
                            Text('Você está na $kAppVersion${u.apkSize > 0 ? ' · download de ${u.sizeLabel}' : ''}',
                                style: text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (u.notes.isNotEmpty)
                    Flexible(
                      child: SingleChildScrollView(child: ReleaseNotes(u.notes)),
                    ),
                  const SizedBox(height: 12),
                  if (up.stage == UpdateStage.downloading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: up.progress, minHeight: 8),
                    ),
                    const SizedBox(height: 6),
                    Text('Baixando… ${((up.progress ?? 0) * 100).round()}%', style: text.bodySmall),
                    const SizedBox(height: 8),
                  ],
                  if (up.message != null && up.stage == UpdateStage.failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(up.message!, style: text.bodyMedium?.copyWith(color: GmColors.red)),
                    ),
                  Text(
                    'Seus treinos e dados continuam salvos. O Android vai pedir para confirmar a instalação.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : up.downloadAndInstall,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(up.stage == UpdateStage.failed ? 'Tentar de novo' : 'Atualizar agora'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(busy ? 'Continuar usando o app' : 'Depois'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mostra as notas da versão (um markdown simples: títulos e listas).
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final children = <Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trim().replaceAll('**', '').replaceAll('`', '');
      if (line.isEmpty) continue;
      if (line.startsWith('#')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(line.replaceFirst(RegExp(r'^#+\s*'), ''), style: text.titleMedium),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7, right: 8),
                child: Icon(Icons.circle, size: 6, color: GmColors.blue),
              ),
              Expanded(child: Text(line.substring(2), style: text.bodyMedium)),
            ],
          ),
        ));
      } else {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(line, style: text.bodyMedium)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
