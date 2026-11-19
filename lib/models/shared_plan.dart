import 'dart:convert';

import 'package:archive/archive.dart';

import 'exercise.dart';
import 'plan.dart';
import 'workout_entry.dart';

/// Treino completo empacotado num código de texto, para enviar a outra pessoa
/// (personal → aluno) ou guardar como modelo. O código vai junto de uma
/// mensagem e é reconhecido pelo prefixo `GMF1.`.
class SharedPlan {
  const SharedPlan({
    required this.name,
    this.author = '',
    required this.plan,
    required this.entries,
    this.customExercises = const [],
  });

  final String name;
  final String author;
  final TrainingPlan plan;

  /// Exercícios do treino (o id de cada um é refeito ao importar).
  final List<WorkoutEntry> entries;

  /// Exercícios criados pela pessoa que aparecem no treino.
  final List<Exercise> customExercises;

  static const prefix = 'GMF1.';
  static final _pattern = RegExp(r'GMF1\.([A-Za-z0-9_-]+)');

  String encode() {
    final data = {
      'v': 1,
      'n': name,
      if (author.isNotEmpty) 'a': author,
      'p': plan.toJson(),
      'e': [
        for (final e in entries)
          {
            ...e.toJson()..remove('id')..remove('history'),
          },
      ],
      if (customExercises.isNotEmpty) 'c': [for (final c in customExercises) c.toJson()],
    };
    final bytes = GZipEncoder().encodeBytes(utf8.encode(jsonEncode(data)));
    return prefix + base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Procura um código em qualquer texto (por exemplo, a mensagem inteira colada).
  static bool containsCode(String text) => _pattern.hasMatch(text);

  /// Lê o código; devolve null se o texto não tiver um código válido.
  static SharedPlan? decode(String text) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    try {
      var b64 = m.group(1)!;
      while (b64.length % 4 != 0) {
        b64 += '=';
      }
      final raw = GZipDecoder().decodeBytes(base64Url.decode(b64));
      final j = Map<String, dynamic>.from(jsonDecode(utf8.decode(raw)) as Map);
      if ((j['v'] as num?)?.toInt() != 1) return null;
      var i = 0;
      return SharedPlan(
        name: (j['n'] as String?) ?? 'Treino',
        author: (j['a'] as String?) ?? '',
        plan: TrainingPlan.fromJson(Map<String, dynamic>.from(j['p'] as Map)),
        entries: [
          for (final e in (j['e'] as List))
            WorkoutEntry.fromJson({...Map<String, dynamic>.from(e as Map), 'id': 'imp${i++}'}),
        ],
        customExercises: [
          for (final c in (j['c'] as List? ?? const []))
            Exercise.fromJson(Map<String, dynamic>.from(c as Map), custom: true),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// Mensagem pronta para enviar pelo WhatsApp ou outro app.
  String message() {
    final who = author.isEmpty ? '' : ' montado por $author';
    final kind = plan.isSplit ? 'Divisão ${splitName(plan.count)}' : 'Treino semanal';
    return 'Treino "$name"$who no GM Fitness ($kind, ${entries.length} exercícios).\n'
        'Para usar: abra o GM Fitness, toque em Treino > Organizar treinos > Importar treino '
        'e cole esta mensagem inteira.\n\n${encode()}';
  }
}

/// Treino guardado na biblioteca (útil para personais com vários alunos).
class SavedPlan {
  const SavedPlan({required this.id, required this.name, required this.date, required this.code});

  final String id;
  final String name;
  final DateTime date;
  final String code;

  factory SavedPlan.fromJson(Map<String, dynamic> j) => SavedPlan(
        id: j['id'] as String,
        name: j['name'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        code: j['code'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'date': date.toIso8601String(), 'code': code};
}
