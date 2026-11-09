import 'package:flutter/material.dart';

import '../models/body.dart';
import '../models/workout_entry.dart';
import '../state/app_state.dart';
import '../update/updater.dart';
import '../widgets/body_widgets.dart';
import '../widgets/brand.dart';
import 'body_edit_screen.dart';
import 'home_shell.dart';
import 'settings_screen.dart';

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
      appBar: AppBar(
        title: const Text('Meu perfil'),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            onPressed: () => openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
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
          ListenableBuilder(
            listenable: Updater.instance,
            builder: (context, _) => Updater.instance.available == null
                ? const SizedBox.shrink()
                : const Padding(padding: EdgeInsets.only(top: 22), child: UpdatesCard()),
          ),
          const SizedBox(height: 24),
          const PlateStripe(height: 4),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            subtitle: const Text('Tema, cores, texto, avisos, atualizações e sobre o app'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openSettings(context),
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
