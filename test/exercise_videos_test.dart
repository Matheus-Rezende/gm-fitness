import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/widgets/exercise_video.dart';

void main() {
  test('cada exercício com vídeo tem o arquivo do homem e da mulher', () {
    for (final id in kExerciseVideos) {
      for (final male in [true, false]) {
        final path = exerciseVideoAsset(id, male: male)!;
        expect(File(path).existsSync(), isTrue, reason: 'falta $path');
      }
    }
  });

  test('os vídeos pertencem a exercícios do catálogo', () {
    final data = jsonDecode(File('assets/exercises.json').readAsStringSync());
    final list = (data is List ? data : (data as Map)['exercises']) as List;
    final ids = list.map((e) => (e as Map)['id']).toSet();
    for (final id in kExerciseVideos) {
      expect(ids.contains(id), isTrue, reason: '$id não existe em exercises.json');
    }
    expect(exerciseVideoAsset('nao_existe', male: true), isNull);
  });
}
