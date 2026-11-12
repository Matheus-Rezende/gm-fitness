import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../version.dart';

/// Repositório onde as versões são publicadas (página de Releases).
const kReleasesRepo = 'Matheus-Rezende/gm-fitness';

/// Uma versão publicada.
class UpdateInfo {
  const UpdateInfo({required this.version, required this.notes, required this.apkUrl, required this.apkSize});

  final String version;
  final String notes;
  final String apkUrl;
  final int apkSize;

  String get sizeLabel => '${(apkSize / 1048576).toStringAsFixed(0)} MB';
}

/// Compara versões "1.2.3" (ignora o "v" e o "+build"). Negativo se [a] < [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(RegExp(r'\d+').firstMatch(p)?.group(0) ?? '') ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// Lê a resposta da API de Releases do GitHub. Só considera versões com APK.
UpdateInfo? parseRelease(Map<String, dynamic> j) {
  if (j['draft'] == true || j['prerelease'] == true) return null;
  final tag = j['tag_name'] as String?;
  if (tag == null) return null;
  for (final a in (j['assets'] as List? ?? const [])) {
    final m = a as Map;
    final name = (m['name'] ?? '').toString();
    if (name.endsWith('.apk')) {
      final body = (j['body'] ?? '').toString().replaceAll('\r\n', '\n');
      final notes = body.split(RegExp(r'^## Como instalar', multiLine: true)).first.trim();
      return UpdateInfo(
        version: tag.replaceFirst(RegExp(r'^[vV]'), ''),
        notes: notes,
        apkUrl: (m['browser_download_url'] ?? '').toString(),
        apkSize: (m['size'] as num?)?.toInt() ?? 0,
      );
    }
  }
  return null;
}

enum UpdateStage { idle, checking, downloading, installing, failed }

/// Procura, baixa e instala novas versões (Android). No iOS a atualização é
/// pela App Store/TestFlight, então nada aparece.
class Updater extends ChangeNotifier {
  Updater._();

  static final instance = Updater._();

  static const _channel = MethodChannel('gm_fitness/updater');
  static const _kLastCheck = 'update_last_check';
  static const _kSnoozed = 'update_snoozed';
  static const _kAuto = 'update_auto_check';

  bool get supported => !kIsWeb && Platform.isAndroid;

  UpdateInfo? available;
  UpdateStage stage = UpdateStage.idle;
  double? progress;
  String? message;
  DateTime? lastCheck;
  bool autoCheck = true;

  /// O último download (ou a instalação) não terminou.
  bool downloadFailed = false;

  /// A janela da atualização está aberta (então o aviso flutuante some).
  bool sheetOpen = false;

  void setSheetOpen(bool v) {
    if (sheetOpen == v) return;
    sheetOpen = v;
    notifyListeners();
  }

  /// Há um download ou instalação em andamento.
  bool get busy => stage == UpdateStage.downloading || stage == UpdateStage.installing;
  bool _loaded = false;

  Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();
    if (!_loaded) {
      _loaded = true;
      final t = p.getString(_kLastCheck);
      lastCheck = t == null ? null : DateTime.tryParse(t);
      autoCheck = p.getBool(_kAuto) ?? true;
    }
    return p;
  }

  Future<void> setAutoCheck(bool v) async {
    final p = await _prefs();
    autoCheck = v;
    await p.setBool(_kAuto, v);
    notifyListeners();
  }

  /// Procura uma versão nova. Sem [force], respeita o intervalo de 6 horas e a
  /// opção de verificar sozinho. Retorna a versão nova, se houver.
  Future<UpdateInfo?> check({bool force = false}) async {
    if (!supported || stage == UpdateStage.checking || stage == UpdateStage.downloading) return available;
    final p = await _prefs();
    if (!force) {
      if (!autoCheck) return available;
      if (lastCheck != null && DateTime.now().difference(lastCheck!) < const Duration(hours: 6)) return available;
    }
    stage = UpdateStage.checking;
    message = null;
    notifyListeners();
    try {
      final info = await _fetchLatest();
      lastCheck = DateTime.now();
      await p.setString(_kLastCheck, lastCheck!.toIso8601String());
      available = info != null && compareVersions(info.version, kAppVersion) > 0 ? info : null;
      stage = UpdateStage.idle;
    } catch (e) {
      stage = force ? UpdateStage.failed : UpdateStage.idle;
      message = 'Não foi possível procurar atualizações. Confira a internet e tente de novo.';
    }
    notifyListeners();
    return available;
  }

  /// O aviso automático foi adiado para esta versão nos últimos 2 dias?
  Future<bool> isSnoozed(UpdateInfo u) async {
    final p = await _prefs();
    final s = p.getString(_kSnoozed);
    if (s == null) return false;
    final parts = s.split('|');
    final t = parts.length > 1 ? DateTime.tryParse(parts[1]) : null;
    return parts.first == u.version && t != null && DateTime.now().difference(t) < const Duration(days: 2);
  }

  Future<void> snooze(UpdateInfo u) async {
    final p = await _prefs();
    await p.setString(_kSnoozed, '${u.version}|${DateTime.now().toIso8601String()}');
  }

  Future<UpdateInfo?> _fetchLatest() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$kReleasesRepo/releases/latest'));
      req.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'GM-Fitness-App/$kAppVersion');
      final res = await req.close().timeout(const Duration(seconds: 15));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      return parseRelease(Map<String, dynamic>.from(jsonDecode(text) as Map));
    } finally {
      client.close(force: true);
    }
  }

  /// Baixa o APK (mostrando o progresso) e abre o instalador do Android.
  Future<void> downloadAndInstall() async {
    final u = available;
    if (u == null || !supported) return;
    if (stage == UpdateStage.downloading) return;
    stage = UpdateStage.downloading;
    progress = 0;
    message = null;
    downloadFailed = false;
    notifyListeners();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final dir = await _channel.invokeMethod<String>('updatesDir');
      final file = File('$dir/gm-fitness-${u.version}.apk');
      final complete = file.existsSync() && u.apkSize > 0 && file.lengthSync() == u.apkSize;
      if (!complete) {
        for (final old in Directory(dir!).listSync()) {
          if (old is File) old.deleteSync();
        }
        final req = await client.getUrl(Uri.parse(u.apkUrl));
        req.headers.set(HttpHeaders.userAgentHeader, 'GM-Fitness-App/$kAppVersion');
        final res = await req.close();
        if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
        final total = res.contentLength > 0 ? res.contentLength : u.apkSize;
        final sink = file.openWrite();
        var got = 0;
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) {
            final p = got / total;
            if (progress == null || p - progress! >= 0.01 || p >= 1) {
              progress = p;
              notifyListeners();
            }
          }
        }
        await sink.close();
      }
      progress = 1;
      await install(file.path);
    } catch (e) {
      stage = UpdateStage.failed;
      downloadFailed = true;
      message = 'O download não terminou. Confira a internet e tente de novo.';
      notifyListeners();
    } finally {
      client.close(force: true);
    }
  }

  /// Abre o instalador. Se faltar a permissão de instalar apps, abre a tela
  /// de configurações do Android para a pessoa liberar.
  Future<void> install(String path) async {
    stage = UpdateStage.installing;
    notifyListeners();
    final r = await _channel.invokeMethod<String>('install', {'path': path});
    if (r == 'needs_permission') {
      stage = UpdateStage.failed;
      downloadFailed = true;
      message = 'Libere "Permitir desta fonte" para o GM Fitness na tela que abriu, volte e toque em '
          '"Atualizar agora" de novo.';
    } else {
      stage = UpdateStage.idle;
    }
    notifyListeners();
  }
}
