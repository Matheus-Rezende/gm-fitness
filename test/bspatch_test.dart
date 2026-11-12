import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/update/bspatch.dart';
import 'package:gm_fitness/update/updater.dart';

void main() {
  test('bspatch monta o arquivo novo a partir do antigo e do patch', () {
    final old = File('test/fixtures/bspatch_old.bin').readAsBytesSync();
    final expected = File('test/fixtures/bspatch_new.bin').readAsBytesSync();
    final patch = File('test/fixtures/bspatch.patch').readAsBytesSync();
    expect(bspatch(old, patch), expected);
  });

  test('bspatch recusa arquivo que não é patch', () {
    expect(() => bspatch(File('test/fixtures/bspatch_old.bin').readAsBytesSync(),
        File('test/fixtures/bspatch_new.bin').readAsBytesSync()), throwsFormatException);
  });

  test('Release com update.json e APKs por processador', () {
    final info = parseRelease({
      'tag_name': 'v0.15.0',
      'body': 'Novidades',
      'assets': [
        {'name': 'gm-fitness-v0.15.0-arm64-v8a.apk', 'browser_download_url': 'https://x/arm64.apk', 'size': 30},
        {'name': 'gm-fitness-v0.15.0.apk', 'browser_download_url': 'https://x/uni.apk', 'size': 70},
        {'name': 'update.json', 'browser_download_url': 'https://x/update.json', 'size': 1},
      ],
    })!;
    expect(info.apkUrl, 'https://x/uni.apk');
    expect(info.manifestUrl, 'https://x/update.json');
    final p = info.copyWith(patchUrl: 'https://x/p.patch', patchSize: 3 * 1048576);
    expect(p.isPatch, isTrue);
    expect(p.sizeLabel, '3 MB');
  });
}
