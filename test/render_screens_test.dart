import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fitness/main.dart';
import 'package:gm_fitness/update/update_ui.dart';
import 'package:gm_fitness/update/updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Capturas das telas em build/screens/ (só com RENDER_PREVIEWS=1), para
/// conferir o layout fora do aparelho.
void main() {
  final enabled = Platform.environment['RENDER_PREVIEWS'] == '1';
  final shot = GlobalKey();

  Future<void> loadFonts() async {
    Future<ByteData> bytes(String path) async => ByteData.sublistView(await File(path).readAsBytes());
    final barlow = FontLoader('Barlow');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      barlow.addFont(bytes('assets/fonts/Barlow-$w.ttf'));
    }
    await barlow.load();
    final cond = FontLoader('BarlowCondensed');
    for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
      cond.addFont(bytes('assets/fonts/BarlowCondensed-$w.ttf'));
    }
    await cond.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(bytes('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  }

  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await settle(tester, 4);
    final boundary = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final img = await boundary.toImage(pixelRatio: 1.5);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    Directory('build/screens').createSync(recursive: true);
    File('build/screens/$name.png').writeAsBytesSync(bytes!);
  }

  Future<void> waitFor(WidgetTester tester, Finder f) async {
    for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    if (f.evaluate().isEmpty) {
      await tester.dragUntilVisible(f, find.byType(ListView).last, const Offset(0, -250));
    }
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle(tester, 6);
  }

  Widget app() => RepaintBoundary(key: shot, child: const GmFitnessApp());

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('telas da introdução', (tester) async {
    phone(tester);
    await tester.runAsync(loadFonts);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app());
    await waitFor(tester, find.text('Começar'));
    await settle(tester, 4);
    await tap(tester, find.text('Começar'));
    await tap(tester, find.text('Masculino'));
    await tap(tester, find.text('Continuar'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Idade'), '34');
    await tester.enterText(find.widgetWithText(TextFormField, 'Altura'), '178');
    await tester.enterText(find.widgetWithText(TextFormField, 'Peso atual'), '96,5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cintura (opcional)'), '102');
    await settle(tester, 2);
    await capture(tester, '01_sobre_voce');
    await tap(tester, find.text('Continuar').last);
    await tap(tester, find.text('Emagrecer'));
    await tap(tester, find.text('Levemente ativo'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Peso que quer alcançar (opcional)'), '82');
    await settle(tester, 2);
    await capture(tester, '02_objetivo');
    await tap(tester, find.text('Continuar').last);
    await capture(tester, '03_ponto_de_partida');
  }, skip: !enabled);

  testWidgets('evolução, perfil e atualização', (tester) async {
    phone(tester);
    await tester.runAsync(loadFonts);
    final now = DateTime.now();
    String day(int ago) => now.subtract(Duration(days: ago)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      'profile_v1': '{"sex":"F","name":"Ana","onboarded":true}',
      'body_v1': '{"birthYear":${now.year - 29},"heightCm":163,"waistCm":88,"targetKg":64,'
          '"goal":"loseFat","activity":"light"}',
      'weights_v1': '[{"date":"${day(42)}","kg":78.4},{"date":"${day(35)}","kg":77.6},'
          '{"date":"${day(28)}","kg":77.9},{"date":"${day(21)}","kg":76.8},{"date":"${day(14)}","kg":76.1},'
          '{"date":"${day(7)}","kg":75.7},{"date":"${day(0)}","kg":75.2}]',
    });
    await tester.pumpWidget(app());
    await waitFor(tester, find.byType(NavigationBar));
    await settle(tester, 4);
    if (find.byType(NavigationBar).evaluate().isEmpty) {
      await capture(tester, '00_debug');
      final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).join(' | ');
      fail('App não abriu nas abas. Textos na tela: $texts');
    }
    await tap(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text('Evolução')));
    await capture(tester, '04_evolucao');
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await capture(tester, '05_evolucao_2');
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await capture(tester, '06_evolucao_3');

    await tap(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text('Treino')));
    await tap(tester, find.byTooltip('Meu perfil'));
    await capture(tester, '07_perfil');
    await tap(tester, find.text('Editar'));
    await capture(tester, '08_editar_corpo');
    await tester.pageBack();
    await settle(tester);

    Updater.instance.available = const UpdateInfo(
      version: '0.6.0',
      notes: '- **Novidade**: exemplo de item da lista de novidades.\n- Outra melhoria no treino cronometrado.',
      apkUrl: 'https://example.com/app.apk',
      apkSize: 54403070,
    );
    final ctx = tester.element(find.byType(Scaffold).last);
    showUpdateSheet(ctx);
    await settle(tester);
    await capture(tester, '09_atualizacao');
  }, skip: !enabled);
}
