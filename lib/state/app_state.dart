import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/body.dart';
import '../models/exercise.dart';
import '../models/preset.dart';
import '../models/session.dart';
import '../models/workout_entry.dart';
import '../motion/motion_clip.dart';

MotionLibrary _parseMotions(String source) => MotionLibrary.parse(source);

/// Estado do app: catálogo (vem dos assets, sem internet) e dados do
/// usuário (guardados no aparelho).
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.meta, this._builtIn, this.presets, this.motions);

  static const _kEntries = 'entries_v1';
  static const _kCustom = 'custom_exercises_v1';
  static const _kProfile = 'profile_v1';
  static const _kDone = 'done_v1';
  static const _kActive = 'active_session_v1';
  static const _kSessions = 'sessions_v1';
  static const _kBody = 'body_v1';
  static const _kWeights = 'weights_v1';

  final SharedPreferences _prefs;
  final CatalogMeta meta;
  final List<Exercise> _builtIn;
  final List<BodyPreset> presets;
  final MotionLibrary motions;

  List<Exercise> _custom = [];
  List<WorkoutEntry> _entries = [];
  int _idSeq = 0;

  // perfil
  String _sex = 'F';
  String _name = '';
  String? _presetId;
  bool _onboarded = false;

  // corpo: dados informados e histórico de pesagens (mais antiga primeiro)
  BodyData _body = const BodyData();
  List<WeightRecord> _weights = [];

  // exercícios marcados como feitos, por data (aaaa-mm-dd)
  Map<String, Set<String>> _done = {};

  // treino em andamento e histórico de treinos concluídos
  ActiveSession? _active;
  List<WorkoutSession> _sessions = [];

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
      final pr = _prefs.getString(_kProfile);
      if (pr != null) {
        final m = Map<String, dynamic>.from(jsonDecode(pr) as Map);
        _sex = m['sex'] == 'M' ? 'M' : 'F';
        _name = (m['name'] as String?) ?? '';
        _presetId = m['presetId'] as String?;
        _onboarded = m['onboarded'] == true;
      }
      final bd = _prefs.getString(_kBody);
      if (bd != null) _body = BodyData.fromJson(Map<String, dynamic>.from(jsonDecode(bd) as Map));
      final wg = _prefs.getString(_kWeights);
      if (wg != null) {
        _weights = [for (final e in (jsonDecode(wg) as List)) WeightRecord.fromJson(Map<String, dynamic>.from(e as Map))]
          ..sort((a, b) => a.date.compareTo(b.date));
      }
      final ac = _prefs.getString(_kActive);
      if (ac != null) _active = ActiveSession.fromJson(Map<String, dynamic>.from(jsonDecode(ac) as Map));
      final ss = _prefs.getString(_kSessions);
      if (ss != null) {
        _sessions = [
          for (final e in (jsonDecode(ss) as List)) WorkoutSession.fromJson(Map<String, dynamic>.from(e as Map)),
        ];
      }
      final dn = _prefs.getString(_kDone);
      if (dn != null) {
        final m = Map<String, dynamic>.from(jsonDecode(dn) as Map);
        _done = {for (final e in m.entries) e.key: {for (final v in (e.value as List)) v.toString()}};
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
    await _prefs.setString(
        _kProfile, jsonEncode({'sex': _sex, 'name': _name, 'presetId': _presetId, 'onboarded': _onboarded}));
    await _prefs.setString(_kBody, jsonEncode(_body.toJson()));
    await _prefs.setString(_kWeights, jsonEncode([for (final w in _weights) w.toJson()]));
    // guarda só as últimas 8 semanas de marcações
    final keys = _done.keys.toList()..sort();
    if (keys.length > 56) {
      for (final k in keys.take(keys.length - 56)) {
        _done.remove(k);
      }
    }
    await _prefs.setString(_kDone, jsonEncode({for (final e in _done.entries) e.key: e.value.toList()}));
    if (_active == null) {
      await _prefs.remove(_kActive);
    } else {
      await _prefs.setString(_kActive, jsonEncode(_active!.toJson()));
    }
    if (_sessions.length > 120) _sessions = _sessions.sublist(_sessions.length - 120);
    await _prefs.setString(_kSessions, jsonEncode([for (final x in _sessions) x.toJson()]));
  }

  // ------------------------------------------------------------ treino cronometrado

  ActiveSession? get activeSession => _active;

  /// Treinos concluídos, do mais recente para o mais antigo.
  List<WorkoutSession> get sessions => _sessions.reversed.toList();

  Future<void> startSession(int weekday) async {
    _active = ActiveSession(weekday: weekday, startedAt: DateTime.now());
    notifyListeners();
    await _save();
  }

  int setsDoneFor(String entryId) => _active?.sets[entryId] ?? 0;

  Future<void> markSet(String entryId, int count) async {
    final a = _active;
    final e = entry(entryId);
    if (a == null || e == null) return;
    a.sets[entryId] = count.clamp(0, e.sets);
    final today = _done.putIfAbsent(dayKey(DateTime.now()), () => <String>{});
    if (a.sets[entryId]! >= e.sets) {
      today.add(entryId);
    } else {
      today.remove(entryId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> setFeel(String entryId, Feel? feel) async {
    final a = _active;
    if (a == null) return;
    if (feel == null) {
      a.feel.remove(entryId);
    } else {
      a.feel[entryId] = feel;
    }
    notifyListeners();
    await _save();
  }

  Future<void> cancelSession() async {
    _active = null;
    notifyListeners();
    await _save();
  }

  /// Encerra o treino em andamento com a percepção de esforço [rpe] (0 a 10).
  Future<WorkoutSession?> finishSession(int rpe) async {
    final a = _active;
    if (a == null) return null;
    final items = <SessionItem>[];
    for (final e in entriesOnDay(a.weekday)) {
      final ex = exercise(e.exerciseId);
      if (ex == null) continue;
      items.add(SessionItem(
        entryId: e.id,
        exerciseId: e.exerciseId,
        name: ex.name,
        setsDone: a.sets[e.id] ?? 0,
        setsPlanned: e.sets,
        reps: e.reps,
        loadKg: e.loadKg,
        feel: a.feel[e.id],
      ));
    }
    final s = WorkoutSession(
      id: _newId('s'),
      weekday: a.weekday,
      startedAt: a.startedAt,
      duration: a.elapsed,
      rpe: rpe.clamp(0, 10),
      items: items,
    );
    _sessions.add(s);
    _active = null;
    notifyListeners();
    await _save();
    return s;
  }

  /// Média da carga das últimas sessões antes de [s] (para comparar).
  double? averageLoadBefore(WorkoutSession s, {int count = 5}) {
    final prev = _sessions.where((x) => x.id != s.id && x.startedAt.isBefore(s.startedAt)).toList();
    if (prev.isEmpty) return null;
    final last = prev.sublist(prev.length > count ? prev.length - count : 0);
    return last.map((x) => x.sessionLoad).reduce((a, b) => a + b) / last.length;
  }

  Future<void> applyLoads(Map<String, double> loads) async {
    for (final e in loads.entries) {
      final cur = entry(e.key);
      if (cur != null && cur.loadKg != e.value) await updateEntry(cur.copyWith(loadKg: e.value));
    }
  }

  // ------------------------------------------------------------ corpo e objetivo

  BodyData get body => _body;

  /// Pesagens, da mais antiga para a mais recente.
  List<WeightRecord> get weights => List.unmodifiable(_weights);

  double? get currentWeight => _weights.isEmpty ? null : _weights.last.kg;
  double? get startWeight => _weights.isEmpty ? null : _weights.first.kg;

  /// Dias de treino por semana, pelo plano atual ou pela lista montada.
  int get trainingDays {
    final days = {for (final e in _entries) if (e.weekday >= 0) e.weekday};
    return days.isEmpty ? (currentPreset?.days.length ?? 3) : days.length;
  }

  BodyMetrics get metrics =>
      BodyMetrics.compute(data: _body, weightKg: currentWeight, sex: _sex, trainingDays: trainingDays);

  Future<void> setBody(BodyData data) async {
    _body = data;
    notifyListeners();
    await _save();
  }

  /// Registra uma pesagem. Se já houver uma no mesmo dia, ela é substituída.
  Future<void> addWeight(double kg, [DateTime? date]) async {
    final d = date ?? DateTime.now();
    _weights.removeWhere((w) => _sameDay(w.date, d));
    _weights.add(WeightRecord(d, kg));
    _weights.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
    await _save();
  }

  Future<void> removeWeight(WeightRecord r) async {
    _weights.removeWhere((w) => w.date == r.date && w.kg == r.kg);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ perfil

  /// 'F' (feminino) ou 'M' (masculino).
  String get sex => _sex;
  bool get isMale => _sex == 'M';
  String get name => _name;
  bool get onboarded => _onboarded;
  BodyPreset? get currentPreset {
    for (final p in presets) {
      if (p.id == _presetId) return p;
    }
    return null;
  }

  Future<void> setProfile({String? sex, String? name, String? presetId, bool clearPreset = false, bool? onboarded}) async {
    if (sex != null) _sex = sex == 'M' ? 'M' : 'F';
    if (name != null) _name = name.trim();
    if (clearPreset) _presetId = null;
    if (presetId != null) _presetId = presetId;
    if (onboarded != null) _onboarded = onboarded;
    notifyListeners();
    await _save();
  }

  /// Planos que servem para o gênero do perfil.
  List<BodyPreset> get presetsForUser => presets.where((p) => p.fits(_sex)).toList();

  /// Exercícios usados nos planos do gênero do perfil.
  Set<String> get recommendedIds => {
        for (final p in presetsForUser)
          for (final d in p.days)
            for (final i in d.items) i.exercise,
      };

  // ------------------------------------------------------------ feitos hoje

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDone(String entryId, [DateTime? day]) => _done[dayKey(day ?? DateTime.now())]?.contains(entryId) ?? false;

  Future<void> toggleDone(String entryId) async {
    final k = dayKey(DateTime.now());
    final set = _done.putIfAbsent(k, () => <String>{});
    if (!set.remove(entryId)) set.add(entryId);
    notifyListeners();
    await _save();
  }

  /// Quantos dias da semana atual (segunda a domingo) tiveram algum exercício feito.
  List<bool> weekActivity([DateTime? now]) {
    final today = now ?? DateTime.now();
    final monday = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
    return [
      for (var i = 0; i < 7; i++) (_done[dayKey(monday.add(Duration(days: i)))]?.isNotEmpty ?? false),
    ];
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

  /// Move um item dentro do dia. [newIndex] já é a posição final do item.
  Future<void> reorderDay(int weekday, int oldIndex, int newIndex) async {
    final day = entriesOnDay(weekday);
    if (oldIndex < 0 || oldIndex >= day.length) return;
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
    _presetId = preset.id;
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
    _done.clear();
    _active = null;
    _sessions.clear();
    _body = const BodyData();
    _weights.clear();
    _presetId = null;
    _onboarded = false;
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
