import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';
import 'drive_backup.dart';

/// ID do cliente OAuth do tipo "aplicativo da Web" no Google Cloud (não é
/// segredo). Pode ser trocado na compilação com
/// --dart-define=GOOGLE_WEB_CLIENT_ID=...
const kGoogleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: _defaultWebClientId);
const _defaultWebClientId = '283591466032-snqnmpcc4k1it7u1iu6a01bhr17rq4pv.apps.googleusercontent.com';

/// O que fazer quando a nuvem e o aparelho têm dados diferentes.
enum SyncChoice { useCloud, useDevice }

/// Login com a conta Google e backup automático do progresso no Google Drive.
class CloudSync extends ChangeNotifier with WidgetsBindingObserver {
  CloudSync._();

  static final instance = CloudSync._();

  static const _kAccount = 'cloud_account_v1';
  static const _kLastBackup = 'cloud_last_backup_v1';

  AppState? _state;
  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Conta conectada (null se a pessoa não entrou).
  GoogleSignInAccount? user;

  /// E-mail da última conta usada (mostrado enquanto o login silencioso não volta).
  String? rememberedEmail;

  bool busy = false;
  String? message;
  DateTime? lastBackup;

  /// Pergunta pendente: a nuvem e o aparelho têm dados diferentes.
  Map<String, dynamic>? pendingCloud;

  /// Depois de decidir qual versão vale, os backups automáticos ficam ligados.
  bool _ready = false;
  Timer? _debounce;
  bool _dirty = false;

  /// Disponível neste aparelho (Android com o cliente configurado).
  bool get supported => !kIsWeb && Platform.isAndroid && kGoogleWebClientId.isNotEmpty;

  bool get signedIn => user != null;

  Future<void> init(AppState state) async {
    _state = state;
    state.onSaved = _changed;
    state.settings.onSaved = _changed;
    _prefs = await SharedPreferences.getInstance();
    rememberedEmail = _prefs!.getString(_kAccount);
    lastBackup = DateTime.tryParse(_prefs!.getString(_kLastBackup) ?? '');
    if (!supported || _initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      final g = GoogleSignIn.instance;
      await g.initialize(serverClientId: kGoogleWebClientId);
      g.authenticationEvents.listen(_onAuthEvent, onError: (Object e) {
        debugPrint('Login Google: $e');
      });
      if (rememberedEmail != null) unawaited(g.attemptLightweightAuthentication());
    } catch (e) {
      debugPrint('Falha ao iniciar o login Google: $e');
    }
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(user: final account):
        user = account;
        rememberedEmail = account.email;
        await _prefs?.setString(_kAccount, account.email);
        notifyListeners();
        // login silencioso ao abrir o app: confere a nuvem sem pedir nada
        if (!_ready && !busy) unawaited(_reconcile(prompt: false));
      case GoogleSignInAuthenticationEventSignOut():
        user = null;
        _ready = false;
        notifyListeners();
    }
  }

  /// Entra com a conta Google e liga o backup.
  Future<void> signIn() async {
    if (!supported || busy) return;
    _setBusy(true, null);
    try {
      final account = await GoogleSignIn.instance.authenticate(scopeHint: const [DriveBackup.scope]);
      user = account;
      rememberedEmail = account.email;
      await _prefs?.setString(_kAccount, account.email);
      await account.authorizationClient.authorizeScopes(const [DriveBackup.scope]);
      _setBusy(false, null);
      await _reconcile(prompt: true);
    } on GoogleSignInException catch (e) {
      _setBusy(false, e.code == GoogleSignInExceptionCode.canceled ? null : 'Não foi possível entrar: ${e.description ?? e.code.name}');
    } catch (e) {
      _setBusy(false, 'Não foi possível entrar: $e');
    }
  }

  /// Sai da conta neste aparelho (o backup continua no Drive).
  Future<void> signOut() async {
    _debounce?.cancel();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    user = null;
    _ready = false;
    pendingCloud = null;
    rememberedEmail = null;
    await _prefs?.remove(_kAccount);
    notifyListeners();
  }

  Future<DriveBackup?> _drive({bool prompt = false}) async {
    final u = user;
    if (u == null) return null;
    final h = await u.authorizationClient.authorizationHeaders(const [DriveBackup.scope], promptIfNecessary: prompt);
    return h == null ? null : DriveBackup(h);
  }

  /// Compara a nuvem com o aparelho logo depois de entrar.
  Future<void> _reconcile({required bool prompt}) async {
    final state = _state;
    if (state == null) return;
    _setBusy(true, null);
    try {
      final drive = await _drive(prompt: prompt);
      if (drive == null) {
        _setBusy(false, prompt ? 'O Google não liberou o acesso ao Drive.' : null);
        return;
      }
      final cloud = await drive.download();
      if (cloud == null) {
        // nada na nuvem: o aparelho vira o backup
        _ready = true;
        if (state.hasUserData) await _upload(drive);
        _setBusy(false, null);
        return;
      }
      final cloudAt = DateTime.tryParse((cloud['savedAt'] as String?) ?? '');
      final localAt = state.lastLocalChange;
      final last = lastBackup;
      if (!state.hasUserData) {
        await _apply(cloud);
        _ready = true;
        _setBusy(false, 'Seu progresso foi restaurado do Google Drive.');
        return;
      }
      // o aparelho já estava em dia com essa nuvem: segue normal
      final inSync = last != null && cloudAt != null && !cloudAt.isAfter(last.add(const Duration(seconds: 5)));
      if (inSync) {
        _ready = true;
        _setBusy(false, null);
        if (localAt != null && localAt.isAfter(last)) unawaited(backupNow());
        return;
      }
      // os dois têm dados diferentes: a pessoa escolhe
      pendingCloud = cloud;
      _setBusy(false, null);
    } on DriveException catch (e) {
      _setBusy(false, e.unauthorized ? 'Entre de novo para liberar o acesso ao Drive.' : 'O Drive não respondeu. Tente mais tarde.');
    } on GoogleSignInException catch (e) {
      _setBusy(false, e.code == GoogleSignInExceptionCode.canceled ? null : 'Não foi possível acessar o Drive.');
    } catch (e) {
      _setBusy(false, 'Sem conexão com o Drive agora.');
    }
  }

  /// Resolve a pergunta pendente.
  Future<void> resolve(SyncChoice choice) async {
    final cloud = pendingCloud;
    pendingCloud = null;
    if (cloud == null) return;
    _ready = true;
    if (choice == SyncChoice.useCloud) {
      await _apply(cloud);
      message = 'Seu progresso foi restaurado do Google Drive.';
      notifyListeners();
    } else {
      await backupNow();
    }
  }

  Future<void> _apply(Map<String, dynamic> cloud) async {
    await _state!.importBackup(cloud);
    final at = DateTime.tryParse((cloud['savedAt'] as String?) ?? '') ?? DateTime.now().toUtc();
    lastBackup = at;
    await _prefs?.setString(_kLastBackup, at.toIso8601String());
  }

  Future<void> _upload(DriveBackup drive) async {
    final data = _state!.exportBackup();
    await drive.upload(data);
    _dirty = false;
    lastBackup = DateTime.tryParse(data['savedAt'] as String) ?? DateTime.now().toUtc();
    await _prefs?.setString(_kLastBackup, lastBackup!.toIso8601String());
  }

  /// Faz o backup agora.
  Future<bool> backupNow({bool userAsked = false}) async {
    final state = _state;
    if (state == null || user == null) return false;
    if (busy) return false;
    if (!state.hasUserData) {
      if (userAsked) _setBusy(false, 'Ainda não há progresso para salvar.');
      return false;
    }
    _setBusy(true, null);
    try {
      final drive = await _drive(prompt: userAsked);
      if (drive == null) {
        _setBusy(false, 'Entre de novo para liberar o acesso ao Drive.');
        return false;
      }
      await _upload(drive);
      _setBusy(false, userAsked ? 'Backup feito no Google Drive.' : null);
      return true;
    } catch (e) {
      _dirty = true;
      _setBusy(false, userAsked ? 'Não foi possível salvar no Drive agora.' : null);
      return false;
    }
  }

  /// Traz o backup da nuvem para este aparelho (substitui os dados daqui).
  Future<bool> restoreNow() async {
    if (user == null || busy) return false;
    _setBusy(true, null);
    try {
      final drive = await _drive(prompt: true);
      final cloud = await drive?.download();
      if (cloud == null) {
        _setBusy(false, 'Ainda não há backup no Drive desta conta.');
        return false;
      }
      await _apply(cloud);
      _ready = true;
      _setBusy(false, 'Seu progresso foi restaurado do Google Drive.');
      return true;
    } catch (e) {
      _setBusy(false, 'Não foi possível ler o backup agora.');
      return false;
    }
  }

  /// Algo mudou no aparelho: agenda o backup.
  void _changed() {
    if (!_ready || user == null) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 20), () => unawaited(backupNow()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final s = state;
    // ao sair do app, salva o que estiver pendente
    if ((s == AppLifecycleState.paused || s == AppLifecycleState.hidden) && _dirty && _ready) {
      _debounce?.cancel();
      unawaited(backupNow());
    }
  }

  void clearMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  void _setBusy(bool b, String? msg) {
    busy = b;
    message = msg;
    notifyListeners();
  }

  /// Só para depuração: o backup como texto.
  String debugExport() => const JsonEncoder.withIndent('  ').convert(_state?.exportBackup());
}
