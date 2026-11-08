import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/brand.dart';
import 'home_shell.dart';

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _ProfileSheet(),
    ),
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
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
        content: const Text('Sua lista de treinos, as cargas registradas, os exercícios que você criou e o perfil '
            'serão apagados. Não dá para desfazer.'),
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
    final preset = state.currentPreset;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Seu perfil', style: text.headlineMedium),
            const SizedBox(height: 16),
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
            Text('Muda o boneco das animações, os planos sugeridos e as dicas de cada exercício.', style: text.bodySmall),
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
            const SizedBox(height: 18),
            Text('Plano atual', style: text.labelLarge),
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
            const SizedBox(height: 24),
            const PlateStripe(height: 4),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const GmLogo(size: 32),
              title: const Text('Sobre o GM Fitness'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'GM Fitness',
                applicationVersion: '0.4.0',
                applicationIcon: const GmLogo(size: 44),
                children: const [
                  Text('Treinos para quem está começando na academia. Funciona sem internet: nada sai do seu '
                      'aparelho.'),
                  SizedBox(height: 12),
                  Text('As animações e os planos são uma orientação geral e não substituem um profissional de '
                      'educação física. Se sentir dor, pare o exercício.'),
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
      ),
    );
  }
}
