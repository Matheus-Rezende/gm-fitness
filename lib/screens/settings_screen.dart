import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cloud/cloud_ui.dart';
import '../state/app_state.dart';
import '../state/settings.dart';
import '../theme/gm_theme.dart';
import '../update/update_ui.dart';
import '../update/updater.dart';
import '../version.dart';
import '../widgets/brand.dart';

Future<void> openSettings(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));

/// Configurações: aparência, avisos do treino, atualizações, sobre e dados.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clear(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text('Sua lista de treinos, as cargas, o histórico, as pesagens, os exercícios que você criou '
            'e o perfil serão apagados deste aparelho. As configurações de aparência continuam. Não dá para desfazer. '
            'Se você entrou com a conta Google, o backup no Drive não é apagado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GmColors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar dados'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.clearAll();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.settings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const _Header('Aparência', Icons.palette_outlined),
            _Group(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema', style: text.titleMedium),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto)),
                          ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Escuro'), icon: Icon(Icons.dark_mode)),
                        ],
                        selected: {s.themeMode},
                        onSelectionChanged: (v) => s.setThemeMode(v.first),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.themeMode == ThemeMode.system
                          ? 'Segue o tema do celular: claro de dia e escuro quando o aparelho estiver no modo escuro.'
                          : s.themeMode == ThemeMode.dark
                              ? 'Fundo escuro, bom para treinar à noite e economizar bateria em telas OLED.'
                              : 'Fundo claro, mais fácil de ler sob luz forte.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const _Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cor de destaque', style: text.titleMedium),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final a in Accent.values)
                          Expanded(child: _AccentDot(accent: a, selected: s.accent == a, onTap: () => s.setAccent(a))),
                      ],
                    ),
                  ],
                ),
              ),
              const _Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tamanho do texto', style: text.titleMedium),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<double>(
                        showSelectedIcon: false,
                        segments: [for (final (v, l) in textScales) ButtonSegment(value: v, label: Text(l))],
                        selected: {s.textScale},
                        onSelectionChanged: (v) => s.setTextScale(v.first),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const _Header('Treino', Icons.timer_outlined),
            _Group(children: [
              SwitchListTile(
                value: s.restSound,
                onChanged: s.setRestSound,
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Som no fim do descanso'),
              ),
              const _Divider(),
              SwitchListTile(
                value: s.restVibration,
                onChanged: s.setRestVibration,
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Vibrar no fim do descanso'),
              ),
            ]),
            if (Updater.instance.supported) ...[
              const _Header('Atualizações', Icons.system_update_outlined),
              const UpdatesCard(),
            ],
            const _Header('Sobre o app', Icons.info_outline_rounded),
            _Group(children: [
              ListTile(
                leading: const GmLogo(size: 32),
                title: const Text('GM Fitness'),
                subtitle: const Text('Versão $kAppVersion'),
              ),
              const _Divider(),
              ListTile(
                leading: const Icon(Icons.new_releases_outlined),
                title: const Text('Novidades'),
                subtitle: const Text('O que mudou em cada versão'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangelogScreen())),
              ),
              const _Divider(),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('Privacidade'),
                subtitle: const Text('Seus treinos, medidas e pesagens ficam só neste celular. A internet é usada '
                    'apenas para procurar atualizações.'),
              ),
              const _Divider(),
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Aviso de saúde'),
                subtitle: const Text('As animações, os planos e os cálculos são uma orientação geral e não substituem '
                    'educador físico, nutricionista ou médico. Se sentir dor, pare o exercício.'),
              ),
              const _Divider(),
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text('Código-fonte'),
                subtitle: const Text('github.com/$kReleasesRepo'),
                trailing: const Icon(Icons.copy_rounded, size: 18),
                onTap: () async {
                  await Clipboard.setData(const ClipboardData(text: 'https://github.com/$kReleasesRepo'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço copiado.')));
                  }
                },
              ),
              const _Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licenças'),
                subtitle: const Text('Flutter, pacotes e fontes Barlow (SIL Open Font License)'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'GM Fitness',
                  applicationVersion: kAppVersion,
                  applicationIcon: const Padding(padding: EdgeInsets.all(8), child: GmLogo(size: 48)),
                ),
              ),
            ]),
            const _Header('Conta Google e backup', Icons.cloud_outlined),
            const _Group(children: [CloudSection()]),
            const _Header('Dados', Icons.storage_outlined),
            _Group(children: [
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                title: Text('Apagar meus dados', style: TextStyle(color: scheme.error)),
                subtitle: const Text('Volta o app para a primeira abertura'),
                onTap: () => _clear(context, state),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 14, endIndent: 14);
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.accent, required this.selected, required this.onTap});

  final Accent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = dark ? accentForDark(accent.color) : accent.color;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cor ${accent.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: selected ? Icon(Icons.check_rounded, color: dark ? GmColors.night : Colors.white) : null,
              ),
              const SizedBox(height: 4),
              Text(accent.label, style: text.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de novidades de todas as versões (vem do CHANGELOG.md).
class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novidades')),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString('CHANGELOG.md'),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final md = snap.data!;
          final start = md.indexOf('\n## ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [ReleaseNotes(start < 0 ? md : md.substring(start).replaceAll('\n## ', '\n## Versão '))],
          );
        },
      ),
    );
  }
}

class UpdatesCard extends StatelessWidget {
  const UpdatesCard({super.key});

  String _when(DateTime? t) {
    if (t == null) return 'ainda não procurou';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'agora há pouco';
    if (d.inHours < 1) return 'há ${d.inMinutes} min';
    if (d.inDays < 1) return 'há ${d.inHours} h';
    return 'há ${d.inDays} dia${d.inDays == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    final up = Updater.instance;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: up,
      builder: (context, _) {
        final u = up.available;
        final checking = up.stage == UpdateStage.checking;
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          decoration: BoxDecoration(
            color: u != null ? GmColors.yellow : scheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.system_update_rounded, color: u != null ? GmColors.ink : scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u != null ? 'Versão ${u.version} disponível' : 'Atualizações',
                            style: text.titleMedium?.copyWith(color: u != null ? GmColors.ink : null)),
                        Text(
                          u != null
                              ? 'Você está na $kAppVersion'
                              : 'Versão $kAppVersion · última busca ${_when(up.lastCheck)}',
                          style: text.bodySmall?.copyWith(color: u != null ? GmColors.ink : null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (up.message != null && u == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 6),
                  child: Text(up.message!, style: text.bodySmall?.copyWith(color: GmColors.red)),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (u != null)
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: GmColors.ink, foregroundColor: Colors.white),
                      onPressed: () => showUpdateSheet(context),
                      child: const Text('Ver e atualizar'),
                    )
                  else
                    OutlinedButton(
                      onPressed: checking
                          ? null
                          : () async {
                              final found = await up.check(force: true);
                              if (found == null && context.mounted && up.message == null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(content: Text('Você já está na versão mais nova.')));
                              }
                            },
                      child: Text(checking ? 'Procurando…' : 'Procurar agora'),
                    ),
                  const Spacer(),
                  if (u == null) ...[
                    Text('Avisar sozinho', style: text.bodySmall),
                    Switch(value: up.autoCheck, onChanged: up.setAutoCheck),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
