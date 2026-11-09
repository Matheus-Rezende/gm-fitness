import 'package:flutter/material.dart';

import '../models/body.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import '../update/update_ui.dart';
import '../update/updater.dart';
import '../version.dart';
import '../widgets/body_widgets.dart';
import '../widgets/brand.dart';
import 'body_edit_screen.dart';
import 'home_shell.dart';

/// Abre o perfil em tela cheia.
Future<void> showProfileSheet(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: AppScope.read(context).name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _clear(AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar meus dados?'),
        content: const Text('Sua lista de treinos, as cargas, o histórico, as pesagens, os exercícios que você criou '
            'e o perfil serão apagados. Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar dados')),
        ],
      ),
    );
    if (ok != true) return;
    await state.clearAll();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final preset = state.currentPreset;
    final b = state.body;
    final age = b.ageAt(DateTime.now());
    String or(String? v) => v ?? 'Não informado';

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text('Treino para corpo', style: text.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'F', label: Text('Feminino'), icon: Icon(Icons.female_rounded)),
              ButtonSegment(value: 'M', label: Text('Masculino'), icon: Icon(Icons.male_rounded)),
            ],
            selected: {state.sex},
            onSelectionChanged: (s) => state.setProfile(sex: s.first),
          ),
          const SizedBox(height: 6),
          Text('Muda o boneco das animações, os planos sugeridos, as dicas e os cálculos de calorias.',
              style: text.bodySmall),
          const SizedBox(height: 18),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome'),
            onSubmitted: (v) => state.setProfile(name: v),
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              state.setProfile(name: _name.text);
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Text('Corpo e objetivo', style: text.titleLarge)),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BodyEditScreen())),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _Row('Objetivo', or(b.goal?.label)),
                _Row('Idade', age == null ? or(null) : '$age anos'),
                _Row('Altura', b.heightCm == null ? or(null) : '${b.heightCm!.round()} cm'),
                _Row('Peso atual', state.currentWeight == null ? or(null) : formatKg(state.currentWeight!)),
                _Row('Peso-meta', b.targetKg == null ? 'Sem meta' : formatKg(b.targetKg!)),
                _Row('Cintura', b.waistCm == null ? or(null) : '${formatNumber(b.waistCm!)} cm'),
                _Row('Atividade', or(b.activity?.label), last: true),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Plano atual', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(preset?.name ?? 'Nenhum plano. Sua lista foi montada à mão.', style: text.titleMedium),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              homeTab.value = 2;
            },
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Trocar plano'),
          ),
          if (Updater.instance.supported) ...[
            const SizedBox(height: 22),
            const _UpdatesCard(),
          ],
          const SizedBox(height: 24),
          const PlateStripe(height: 4),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const GmLogo(size: 32),
            title: const Text('Sobre o GM Fitness'),
            subtitle: const Text('Versão $kAppVersion'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'GM Fitness',
              applicationVersion: kAppVersion,
              applicationIcon: const GmLogo(size: 44),
              children: const [
                Text('Treinos para quem está começando na academia. Seus treinos e dados ficam só no seu '
                    'aparelho. A internet é usada apenas para procurar atualizações do app.'),
                SizedBox(height: 12),
                Text('As animações, os planos e os cálculos são uma orientação geral e não substituem um '
                    'profissional de educação física, nutricionista ou médico. Se sentir dor, pare o exercício.'),
                SizedBox(height: 12),
                Text('Fontes Barlow e Barlow Condensed, licença SIL Open Font License.'),
              ],
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Apagar meus dados'),
            onTap: () => _clear(state),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: scheme.outlineVariant.withAlpha(120))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}

class _UpdatesCard extends StatelessWidget {
  const _UpdatesCard();

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
