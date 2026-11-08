const weekdayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String weekdayLabel(int d) => d >= 0 && d < 7 ? weekdayNames[d] : 'Sem dia';

List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class PresetItem {
  const PresetItem({required this.exercise, required this.sets, required this.reps, this.rest = 60, this.note = ''});

  final String exercise;
  final int sets;
  final String reps;
  final int rest;
  final String note;

  factory PresetItem.fromJson(Map<String, dynamic> j) => PresetItem(
        exercise: j['exercise'] as String,
        sets: (j['sets'] as num).toInt(),
        reps: j['reps'].toString(),
        rest: (j['rest'] as num?)?.toInt() ?? 60,
        note: (j['note'] as String?) ?? '',
      );
}

class PresetDay {
  const PresetDay({required this.weekday, required this.title, required this.items});

  final int weekday;
  final String title;
  final List<PresetItem> items;

  factory PresetDay.fromJson(Map<String, dynamic> j) => PresetDay(
        weekday: (j['weekday'] as num).toInt(),
        title: j['title'] as String,
        items: [for (final i in (j['items'] as List)) PresetItem.fromJson(Map<String, dynamic>.from(i as Map))],
      );
}

class BodyPreset {
  const BodyPreset({
    required this.id,
    required this.name,
    required this.shape,
    required this.summary,
    required this.description,
    required this.goals,
    required this.focus,
    required this.caution,
    required this.days,
  });

  final String id;
  final String name;
  final String shape;
  final String summary;
  final String description;
  final List<String> goals;
  final List<String> focus;
  final List<String> caution;
  final List<PresetDay> days;

  factory BodyPreset.fromJson(Map<String, dynamic> j) => BodyPreset(
        id: j['id'] as String,
        name: j['name'] as String,
        shape: j['shape'] as String,
        summary: j['summary'] as String,
        description: j['description'] as String,
        goals: _strings(j['goals']),
        focus: _strings(j['focus']),
        caution: _strings(j['caution']),
        days: [for (final d in (j['days'] as List)) PresetDay.fromJson(Map<String, dynamic>.from(d as Map))],
      );
}
