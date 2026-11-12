import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/gm_theme.dart';

/// Cor de destaque do app (botões, seleção, links).
enum Accent { blue, red, green, purple }

extension AccentInfo on Accent {
  String get label => switch (this) {
        Accent.blue => 'Azul',
        Accent.red => 'Vermelho',
        Accent.green => 'Verde',
        Accent.purple => 'Roxo',
      };

  Color get color => switch (this) {
        Accent.blue => GmColors.blue,
        Accent.red => GmColors.red,
        Accent.green => GmColors.green,
        Accent.purple => const Color(0xFF6B3FD4),
      };
}

/// Tamanhos de texto oferecidos.
const textScales = [(1.0, 'Normal'), (1.12, 'Grande'), (1.25, 'Maior')];

/// Preferências do app, guardadas no aparelho.
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs) {
    _restore();
  }

  static const _key = 'settings_v1';

  /// Chave das preferências (entra no backup da nuvem).
  static const storageKey = _key;

  /// Chamado depois de cada gravação (o backup na nuvem se agenda aqui).
  VoidCallback? onSaved;

  /// Lê de novo o que está gravado (depois de restaurar um backup).
  void reload() {
    themeMode = ThemeMode.system;
    accent = Accent.blue;
    textScale = 1.0;
    restSound = true;
    restVibration = true;
    notifEnabled = true;
    notifMinutes = 8 * 60;
    notifEvening = notifMotivation = notifInactive = notifWeigh = true;
    _restore();
    notifyListeners();
  }

  final SharedPreferences _prefs;

  ThemeMode themeMode = ThemeMode.system;
  Accent accent = Accent.blue;
  double textScale = 1.0;
  bool restSound = true;
  bool restVibration = true;

  // notificações
  bool notifEnabled = true;
  int notifMinutes = 8 * 60; // lembrete do dia de treino (minutos desde 0h)
  bool notifEvening = true; // à noite, se ainda não treinou
  bool notifMotivation = true;
  bool notifInactive = true; // quando fica dias sem abrir o app
  bool notifWeigh = true; // pesagem semanal

  /// Chamado quando muda algo das notificações (para reagendar).
  VoidCallback? onNotificationsChanged;

  void _restore() {
    final s = _prefs.getString(_key);
    if (s == null) return;
    try {
      final m = Map<String, dynamic>.from(jsonDecode(s) as Map);
      themeMode = ThemeMode.values.firstWhere((t) => t.name == m['theme'], orElse: () => ThemeMode.system);
      accent = Accent.values.firstWhere((a) => a.name == m['accent'], orElse: () => Accent.blue);
      final scale = (m['textScale'] as num?)?.toDouble() ?? 1.0;
      textScale = textScales.any((t) => t.$1 == scale) ? scale : 1.0;
      restSound = m['restSound'] != false;
      restVibration = m['restVibration'] != false;
      notifEnabled = m['notifEnabled'] != false;
      notifMinutes = ((m['notifMinutes'] as num?)?.toInt() ?? 8 * 60).clamp(0, 24 * 60 - 1);
      notifEvening = m['notifEvening'] != false;
      notifMotivation = m['notifMotivation'] != false;
      notifInactive = m['notifInactive'] != false;
      notifWeigh = m['notifWeigh'] != false;
    } catch (e) {
      debugPrint('Falha ao ler configurações: $e');
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode({
        'theme': themeMode.name,
        'accent': accent.name,
        'textScale': textScale,
        'restSound': restSound,
        'restVibration': restVibration,
        'notifEnabled': notifEnabled,
        'notifMinutes': notifMinutes,
        'notifEvening': notifEvening,
        'notifMotivation': notifMotivation,
        'notifInactive': notifInactive,
        'notifWeigh': notifWeigh,
      }),
    );
    onSaved?.call();
  }

  Future<void> setThemeMode(ThemeMode v) {
    themeMode = v;
    return _save();
  }

  Future<void> setAccent(Accent v) {
    accent = v;
    return _save();
  }

  Future<void> setTextScale(double v) {
    textScale = v;
    return _save();
  }

  Future<void> setNotifications({
    bool? enabled,
    int? minutes,
    bool? evening,
    bool? motivation,
    bool? inactive,
    bool? weigh,
  }) async {
    notifEnabled = enabled ?? notifEnabled;
    notifMinutes = minutes ?? notifMinutes;
    notifEvening = evening ?? notifEvening;
    notifMotivation = motivation ?? notifMotivation;
    notifInactive = inactive ?? notifInactive;
    notifWeigh = weigh ?? notifWeigh;
    await _save();
    onNotificationsChanged?.call();
  }

  Future<void> setRestSound(bool v) {
    restSound = v;
    return _save();
  }

  Future<void> setRestVibration(bool v) {
    restVibration = v;
    return _save();
  }
}
