import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/preset.dart';
import '../models/workout_entry.dart';
import '../motion/motion_clip.dart';

MotionLibrary _parseMotions(String source) => MotionLibrary.parse(source);

/// Estado do app: catálogo (vem dos assets, sem internet) e dados do
/// usuário (guardados no aparelho).
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.meta, this._builtIn, this.presets, this.motions);

  static const _kEntries = 'entries_v1';
  static const _kCustom = 'custom_exercises_v1';

  final SharedPreferences _prefs;
  final CatalogMeta meta;
  final List<Exercise> _builtIn;
  final List<BodyPreset> presets;
  final MotionLibrary motions;

  List<Exercise> _custom = [];
  List<WorkoutEntry> _entries = [];
  int _idSeq = 0;

  static Future<AppState> load() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/exercises.json'),
      rootBundle.loadString('assets/presets.json'),
      rootBundle.loadString('assets/motions.json'),
      SharedPreferences.getInstance(),
    ]);
    final exJson = jsonDecode(results[0] as String) as Map<String, dynamic>;
    final prJson = jsonDecode(results[1] as String) as Map<String, dynamic>;
    final motions = await compute(_parseMotions, results[2] as String);
    final meta = CatalogMeta.fromJson(Map<String, dynamic>.from(exJson['meta'] as Map));
    final builtIn = [
      for (final e in (exJson['exercises'] as List)) Exercise.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
    final presets = [
      for (final p in (prJson['presets'] as List)) BodyPreset.fromJson(Map<String, dynamic>.from(p as Map)),
    ];
    final state = AppState._(results[3] as SharedPreferences, meta, builtIn, presets, motions);
    state._restore();
    return state;
  }

  void _restore() {
    try {
      final c = _prefs.getString(_kCustom);
      if (c != null) {
        _custom = [
          for (final e in (jsonDecode(c) as List)) Exercise.fromJson(Map<String, dynamic>.from(e as Map), custom: true),
        ];
      }
      final s = _prefs.getString(_kEntries);
      if (s != null) {
        _entries = [for (final e in (jsonDecode(s) as List)) WorkoutEntry.fromJson(Map<String, dynamic>.from(e as Map))];
      }
    } catch (e) {
      debugPrint('Falha ao ler dados salvos: $e');
    }
    // Ignora itens cujo exercício não existe mais.
    _entries = _entries.where((e) => exercise(e.exerciseId) != null).toList();
  }

  Future<void> _save() async {
    await _prefs.setString(_kCustom, jsonEncode([for (final e in _custom) e.toJson()]));
    await _prefs.setString(_kEntries, jsonEncode([for (final e in _entries) e.toJson()]));
  }

  String _newId(String prefix) {
    _idSeq++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSeq';
  }

  // ------------------------------------------------------------ catálogo

  List<Exercise> get allExercises {
    final list = [..._builtIn, ..._custom];
    list.sort((a, b) => normalize(a.name).compareTo(normalize(b.name)));
    return list;
  }

  List<Exercise> get customExercises => List.unmodifiable(_custom);

  Exercise? exercise(String id) {
    for (final e in _custom) {
      if (e.id == id) return e;
    }
    for (final e in _builtIn) {
      if (e.id == id) return e;
    }
    return null;
  }

  MotionClip? clipFor(Exercise e) => motions[e.anim];

  /// Grupos musculares que aparecem no catálogo, na ordem definida.
  List<String> get groupsInUse {
    final used = {for (final e in allExercises) e.group};
    return [for (final g in meta.groups.keys) if (used.contains(g)) g];
  }

  Future<Exercise> saveCustom({
    String? id,
    required String name,
    required String group,
    required String equipment,
    required String level,
    String? anim,
    required List<String> steps,
    required List<String> tips,
  }) async {
    final ex = Exercise(
      id: id ?? _newId('custom'),
      name: name.trim(),
      group: group,
      equipment: equipment,
      level: level,
      anim: anim,
      steps: steps,
      tips: tips,
      custom: true,
    );
    final i = _custom.indexWhere((e) => e.id == ex.id);
    if (i >= 0) {
      _custom[i] = ex;
    } else {
      _custom.add(ex);
    }
    notifyListeners();
    await _save();
    return ex;
  }

  Future<void> deleteCustom(String id) async {
    _custom.removeWhere((e) => e.id == id);
    _entries.removeWhere((e) => e.exerciseId == id);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ lista do usuário

  List<WorkoutEntry> get entries => List.unmodifiable(_entries);

  List<WorkoutEntry> entriesFor(String exerciseId) => _entries.where((e) => e.exerciseId == exerciseId).toList();

  List<WorkoutEntry> entriesOnDay(int weekday) => _entries.where((e) => e.weekday == weekday).toList();

  WorkoutEntry? entry(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<WorkoutEntry> addEntry(String exerciseId,
      {int weekday = -1, int sets = 3, String reps = '12', double loadKg = 0, int rest = 60}) async {
    final e = WorkoutEntry(
      id: _newId('e'),
      exerciseId: exerciseId,
      weekday: weekday,
      sets: sets,
      reps: reps,
      loadKg: loadKg,
      rest: rest,
      history: loadKg > 0 ? [LoadRecord(DateTime.now(), loadKg)] : const [],
    );
    _entries.add(e);
    notifyListeners();
    await _save();
    return e;
  }

  /// Atualiza a entrada. Quando a carga muda, registra no histórico.
  Future<void> updateEntry(WorkoutEntry updated) async {
    final i = _entries.indexWhere((e) => e.id == updated.id);
    if (i < 0) return;
    final old = _entries[i];
    var next = updated;
    if (updated.loadKg != old.loadKg) {
      final now = DateTime.now();
      final hist = [...old.history];
      if (hist.isNotEmpty && _sameDay(hist.last.date, now)) {
        hist[hist.length - 1] = LoadRecord(now, updated.loadKg);
      } else {
        hist.add(LoadRecord(now, updated.loadKg));
      }
      next = updated.copyWith(history: hist.length > 60 ? hist.sublist(hist.length - 60) : hist);
    }
    _entries[i] = next;
    notifyListeners();
    await _save();
  }

  Future<void> setLoad(String entryId, double kg) async {
    final e = entry(entryId);
    if (e == null) return;
    await updateEntry(e.copyWith(loadKg: kg < 0 ? 0 : kg));
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> reorderDay(int weekday, int oldIndex, int newIndex) async {
    final day = entriesOnDay(weekday);
    if (oldIndex < 0 || oldIndex >= day.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = day.removeAt(oldIndex);
    day.insert(newIndex.clamp(0, day.length), moved);
    final others = _entries.where((e) => e.weekday != weekday).toList();
    _entries = [...others, ...day];
    notifyListeners();
    await _save();
  }

  /// Aplica uma pré-definição. Com [replace], apaga a lista atual antes;
  /// cargas já registradas para o mesmo exercício são reaproveitadas.
  Future<int> applyPreset(BodyPreset preset, {required bool replace}) async {
    final knownLoads = <String, double>{};
    for (final e in _entries) {
      if (e.loadKg > 0) knownLoads[e.exerciseId] = e.loadKg;
    }
    if (replace) _entries.clear();
    var added = 0;
    for (final d in preset.days) {
      for (final it in d.items) {
        if (exercise(it.exercise) == null) continue;
        final load = knownLoads[it.exercise] ?? 0;
        _entries.add(WorkoutEntry(
          id: _newId('e'),
          exerciseId: it.exercise,
          weekday: d.weekday,
          sets: it.sets,
          reps: it.reps,
          rest: it.rest,
          loadKg: load,
          history: load > 0 ? [LoadRecord(DateTime.now(), load)] : const [],
        ));
        added++;
      }
    }
    notifyListeners();
    await _save();
    return added;
  }

  Future<void> clearAll() async {
    _entries.clear();
    _custom.clear();
    notifyListeners();
    await _save();
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Disponibiliza o [AppState] para a árvore de widgets.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope!.notifier!;
  }
}
