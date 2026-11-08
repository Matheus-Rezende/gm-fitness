List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.equipment,
    required this.level,
    this.anim,
    this.secondary = const [],
    this.steps = const [],
    this.tips = const [],
    this.mistakes = const [],
    this.custom = false,
  });

  final String id;
  final String name;
  final String group;
  final String equipment;
  final String level;
  final String? anim;
  final List<String> secondary;
  final List<String> steps;
  final List<String> tips;
  final List<String> mistakes;
  final bool custom;

  factory Exercise.fromJson(Map<String, dynamic> j, {bool custom = false}) => Exercise(
        id: j['id'] as String,
        name: j['name'] as String,
        group: j['group'] as String,
        equipment: j['equipment'] as String,
        level: (j['level'] as String?) ?? 'iniciante',
        anim: j['anim'] as String?,
        secondary: _strings(j['secondary']),
        steps: _strings(j['steps']),
        tips: _strings(j['tips']),
        mistakes: _strings(j['mistakes']),
        custom: custom || j['custom'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'equipment': equipment,
        'level': level,
        'anim': anim,
        'secondary': secondary,
        'steps': steps,
        'tips': tips,
        'mistakes': mistakes,
        'custom': custom,
      };

  /// Texto usado na busca (nome, grupo e equipamento, sem acentos).
  String searchKey(String groupLabel, String equipmentLabel) =>
      normalize('$name $groupLabel $equipmentLabel');
}

/// Remove acentos e deixa minúsculo, para a busca ignorar diferenças de grafia.
String normalize(String s) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString();
}

class CatalogMeta {
  const CatalogMeta({required this.groups, required this.equipment, required this.levels});

  final Map<String, String> groups;
  final Map<String, String> equipment;
  final Map<String, String> levels;

  String group(String key) => groups[key] ?? key;
  String equip(String key) => equipment[key] ?? key;
  String level(String key) => levels[key] ?? key;

  factory CatalogMeta.fromJson(Map<String, dynamic> j) => CatalogMeta(
        groups: Map<String, String>.from(j['groups'] as Map),
        equipment: Map<String, String>.from(j['equipment'] as Map),
        levels: Map<String, String>.from(j['levels'] as Map),
      );
}
