import 'package:flutter/services.dart';

const _channel = MethodChannel('gm_fitness/updater');

/// Abre a folha de compartilhamento do Android com o texto. Se não der,
/// copia o texto e devolve false (a tela avisa que foi copiado).
Future<bool> shareText(String text, {String title = 'Enviar treino'}) async {
  try {
    final ok = await _channel.invokeMethod<bool>('shareText', {'text': text, 'title': title});
    if (ok == true) return true;
  } catch (_) {}
  await Clipboard.setData(ClipboardData(text: text));
  return false;
}
