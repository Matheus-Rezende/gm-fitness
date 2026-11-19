import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plan.dart';
import '../models/shared_plan.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../widgets/common.dart';
import '../widgets/share_text.dart';

/// Enviar o treino por código (personal → aluno), importar um treino
/// recebido e guardar treinos numa biblioteca.
class SharePlanScreen extends StatelessWidget {
  const SharePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final saved = state.savedPlans;
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar e receber treinos')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(
            'É personal? Monte o treino do aluno, guarde na biblioteca e envie por WhatsApp. '
            'O aluno cola a mensagem no app dele e o treino aparece pronto, com séries, cargas e técnicas.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.send_rounded,
            color: GmColors.blue,
            title: 'Enviar meu treino atual',
            subtitle: state.entries.isEmpty
                ? 'Adicione exercícios primeiro.'
                : '${state.entries.length} exercícios · ${state.plan.isSplit ? 'divisão ${splitName(state.plan.count)}' : 'por dia da semana'}',
            onTap: state.entries.isEmpty ? null : () => _send(context, state),
          ),
          _ActionCard(
            icon: Icons.download_rounded,
            color: GmColors.green,
            title: 'Importar treino recebido',
            subtitle: 'Cole a mensagem que o personal enviou.',
            onTap: () => showImportSheet(context),
          ),
          _ActionCard(
            icon: Icons.bookmark_add_outlined,
            color: GmColors.yellow,
            title: 'Guardar treino atual na biblioteca',
            subtitle: 'Para montar treinos de vários alunos ou trocar de treino depois.',
            onTap: state.entries.isEmpty ? null : () => _saveCurrent(context, state),
          ),
          const SizedBox(height: 20),
          Text('Biblioteca', style: text.titleLarge),
          const SizedBox(height: 6),
          if (saved.isEmpty)
            Text('Nenhum treino guardado ainda.', style: text.bodySmall)
          else
            for (final sp in saved) _SavedTile(saved: sp),
        ],
      ),
    );
  }

  static Future<String?> _askName(BuildContext context, String title, String initial) async {
    final ctrl = TextEditingController(text: initial);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex.: João · Hipertrofia ABC', border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
    ctrl.dispose();
    return name;
  }

  static String _defaultName(AppState state) =>
      state.plan.isSplit ? 'Treino ${splitName(state.plan.count)}' : 'Meu treino';

  static Future<void> _send(BuildContext context, AppState state) async {
    final name = await _askName(context, 'Nome do treino', _defaultName(state));
    if (name == null || !context.mounted) return;
    final shared = await shareText(state.exportShared(name).message());
    if (!shared && context.mounted) showSnack(context, 'Mensagem copiada. Cole no WhatsApp ou onde quiser enviar.');
  }

  static Future<void> _saveCurrent(BuildContext context, AppState state) async {
    final name = await _askName(context, 'Guardar como', _defaultName(state));
    if (name == null) return;
    await state.saveCurrentPlan(name);
    if (context.mounted) showSnack(context, 'Treino guardado na biblioteca.');
  }
}

/// Folha para colar e importar um treino recebido.
Future<void> showImportSheet(BuildContext context) async {
  var initial = '';
  try {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null && SharedPlan.containsCode(clip!.text!)) initial = clip.text!;
  } catch (_) {}
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _ImportSheet(initial: initial),
    ),
  );
}

class _ImportSheet extends StatefulWidget {
  const _ImportSheet({required this.initial});

  final String initial;

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  SharedPlan? _plan;

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _parse() => _plan = SharedPlan.decode(_ctrl.text);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final sp = _plan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Importar treino', style: text.headlineMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(_parse),
            decoration: const InputDecoration(
              labelText: 'Mensagem recebida',
              hintText: 'Cole aqui a mensagem com o código GMF1...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_ctrl.text.trim().isNotEmpty && sp == null)
            Text('Não encontrei um treino válido nesse texto. Confira se a mensagem foi colada inteira.',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
          if (sp != null) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sp.name, style: text.titleMedium),
                    if (sp.author.isNotEmpty) Text('Montado por ${sp.author}', style: text.bodySmall),
                    const SizedBox(height: 8),
                    for (var s = 0; s < sp.plan.slotCount; s++)
                      if (sp.entries.any((e) => e.weekday == s))
                        Text(
                          '${sp.plan.fullLabel(s)}: ${sp.entries.where((e) => e.weekday == s).length} exercícios',
                          style: text.bodySmall,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  if (state.entries.isNotEmpty) {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Trocar o treino atual?'),
                            content: const Text(
                                'Seus exercícios atuais serão substituídos. O histórico de treinos e a evolução não mudam. '
                                'Se quiser, guarde o treino atual na biblioteca antes.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Trocar')),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;
                  }
                  final n = await state.importShared(sp);
                  nav.pop();
                  messenger.showSnackBar(SnackBar(content: Text('Treino importado: $n exercícios.')));
                },
                icon: const Icon(Icons.check),
                label: const Text('Usar este treino'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await state.saveShared(sp);
                  nav.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Guardado na biblioteca.')));
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Só guardar na biblioteca'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.color, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: color == GmColors.yellow ? GmColors.ink : Colors.white,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.saved});

  final SavedPlan saved;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final sp = SharedPlan.decode(saved.code);
    final d = saved.date;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark_rounded),
        title: Text(saved.name),
        subtitle: Text(sp == null
            ? date
            : '$date · ${sp.entries.length} exercícios${sp.plan.isSplit ? ' · ${splitName(sp.plan.count)}' : ''}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opções',
          onSelected: (a) async {
            if (sp == null) return;
            switch (a) {
              case 'use':
                final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Usar "${saved.name}"?'),
                        content: const Text('Os exercícios atuais serão substituídos por este treino.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usar')),
                        ],
                      ),
                    ) ??
                    false;
                if (!ok) return;
                final n = await state.importShared(sp);
                if (context.mounted) showSnack(context, '"${saved.name}" em uso: $n exercícios.');
              case 'send':
                final shared = await shareText(sp.message());
                if (!shared && context.mounted) showSnack(context, 'Mensagem copiada.');
              case 'delete':
                await state.deleteSaved(saved.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'use', child: Text('Usar este treino')),
            PopupMenuItem(value: 'send', child: Text('Enviar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}
