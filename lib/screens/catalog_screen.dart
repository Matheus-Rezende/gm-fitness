import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../motion/motion_view.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'custom_exercise_screen.dart';
import 'exercise_detail_screen.dart';

/// Catálogo de exercícios. Em [pickMode], tocar num exercício devolve o id.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _group;
  String? _equipment;
  bool _onlyMine = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Exercise> _filter(AppState state) {
    final q = normalize(_query.trim());
    final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return state.allExercises.where((e) {
      if (_group != null && e.group != _group && !e.secondary.contains(_group)) return false;
      if (_equipment != null && e.equipment != _equipment) return false;
      if (_onlyMine && !e.custom) return false;
      if (words.isEmpty) return true;
      final key = e.searchKey(state.meta.group(e.group), state.meta.equip(e.equipment));
      return words.every(key.contains);
    }).toList()
      ..sort((a, b) {
        // Com filtro de grupo, quem trabalha o grupo como principal vem primeiro.
        if (_group != null) {
          final pa = a.group == _group ? 0 : 1;
          final pb = b.group == _group ? 0 : 1;
          if (pa != pb) return pa - pb;
        }
        return normalize(a.name).compareTo(normalize(b.name));
      });
  }

  Future<void> _create() async {
    final ex = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const CustomExerciseScreen()),
    );
    if (ex == null || !mounted) return;
    if (widget.pickMode) {
      Navigator.pop(context, ex.id);
    } else {
      showSnack(context, '"${ex.name}" criado');
    }
  }

  Future<void> _pickEquipment(AppState state) async {
    final options = {'': 'Todos os equipamentos', ...state.meta.equipment};
    final v = await pickOption(context, title: 'Equipamento', options: options, current: _equipment ?? '');
    if (v == null) return;
    setState(() => _equipment = v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final list = _filter(state);
    final inMyList = {for (final e in state.entries) e.exerciseId};

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Escolha um exercício' : 'Exercícios'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por equipamento',
            onPressed: () => _pickEquipment(state),
            icon: Badge(
              isLabelVisible: _equipment != null,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar exercício, músculo ou equipamento',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: widget.pickMode ? 'fab_pick' : 'fab_catalog',
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Criar exercício'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _group == null && !_onlyMine,
                    onSelected: (_) => setState(() {
                      _group = null;
                      _onlyMine = false;
                    }),
                  ),
                ),
                if (state.customExercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('Criados por mim'),
                      selected: _onlyMine,
                      onSelected: (v) => setState(() => _onlyMine = v),
                    ),
                  ),
                for (final g in state.groupsInUse)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(state.meta.group(g)),
                      selected: _group == g,
                      onSelected: (_) => setState(() => _group = _group == g ? null : g),
                    ),
                  ),
              ],
            ),
          ),
          if (_equipment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(state.meta.equip(_equipment!)),
                  onDeleted: () => setState(() => _equipment = null),
                ),
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Nenhum exercício encontrado.', style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _create,
                            icon: const Icon(Icons.add),
                            label: const Text('Criar este exercício'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
                    itemBuilder: (context, i) {
                      final e = list[i];
                      final mine = inMyList.contains(e.id);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: MotionThumb(clip: state.clipFor(e), size: 60),
                        title: Text(e.name),
                        subtitle: Text(
                          '${state.meta.group(e.group)} · ${state.meta.equip(e.equipment)} · ${state.meta.level(e.level)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: e.custom
                            ? Icon(Icons.person_outline, color: scheme.tertiary)
                            : (mine ? Icon(Icons.check_circle, color: scheme.primary) : null),
                        onTap: () {
                          if (widget.pickMode) {
                            Navigator.pop(context, e.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exerciseId: e.id)),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
