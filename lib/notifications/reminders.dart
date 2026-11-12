import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/preset.dart';
import '../state/app_state.dart';

/// Frases curtas de incentivo (vão no lembrete e nos dias de descanso).
const kMotivation = [
  'Constância vence intensidade: o importante é aparecer.',
  'Cada treino feito é um passo a mais do que ontem.',
  'Começar é a parte mais difícil. Depois é só seguir a lista.',
  'Seu corpo agradece cada repetição bem feita.',
  'Não precisa ser perfeito, precisa ser feito.',
  'Pequenos progressos toda semana viram grandes resultados.',
  'Lembre: técnica primeiro, carga depois.',
  'Você já fez o mais difícil, que foi começar. Continue!',
  'Um treino de 30 minutos ainda é muito melhor que nenhum.',
  'Disciplina é lembrar o que você quer de verdade.',
];

const _kRestTips = [
  'Hoje é dia de descanso. Dormir bem e beber água também fazem parte do treino.',
  'Descanso é quando o músculo se recupera e fica mais forte. Aproveite!',
  'Dia livre do treino: que tal uma caminhada leve ou um alongamento?',
];

/// Agenda as notificações locais (sem internet) a partir do treino da pessoa:
/// lembrete nos dias de treino, aviso à noite se ainda não treinou, incentivo
/// nos dias de descanso, pesagem semanal, resumo de domingo e um aviso quando
/// a pessoa fica dias sem abrir o app. Tudo é refeito a cada mudança, então as
/// mensagens sempre refletem o treino atual.
class Reminders with WidgetsBindingObserver {
  Reminders._();

  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  AppState? _state;
  bool _ready = false;
  Timer? _debounce;

  /// A pessoa negou a permissão de notificações no Android.
  final denied = ValueNotifier<bool>(false);

  bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static final bool _inTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> init(AppState state) async {
    _state = state;
    if (!supported || _inTest) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_gm'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
      state.addListener(_changed);
      state.settings.onNotificationsChanged = () => reschedule(askPermission: true);
      WidgetsBinding.instance.addObserver(this);
      if (state.onboarded) await reschedule(askPermission: true);
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => unawaited(reschedule()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ao voltar para o app, o aviso de "sumiu" é empurrado para frente
    if (state == AppLifecycleState.resumed) unawaited(reschedule());
  }

  Future<bool> _permission() async {
    if (Platform.isAndroid) {
      final a = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await a?.areNotificationsEnabled() ?? true;
      if (ok) return true;
      return await a?.requestNotificationsPermission() ?? false;
    }
    final i = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  static NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          'treino',
          'Lembretes de treino',
          channelDescription: 'Dias de treino, incentivo, pesagem e resumo da semana',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: const Color(0xFF1F4FD8),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> _at(int id, DateTime when, String title, String body) async {
    if (!when.isAfter(DateTime.now().add(const Duration(minutes: 1)))) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: _details(body),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  /// Refaz a agenda dos próximos 14 dias.
  Future<void> reschedule({bool askPermission = false}) async {
    final state = _state;
    if (!_ready || state == null) return;
    final s = state.settings;
    try {
      await _plugin.cancelAll();
      if (!s.notifEnabled || !state.onboarded) return;
      if (askPermission) denied.value = !(await _permission());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final hasPlan = state.entries.any((e) => e.weekday >= 0);
      final name = state.name.isEmpty ? '' : ', ${state.name.split(' ').first}';
      final rnd = math.Random(today.millisecondsSinceEpoch ~/ 86400000);
      var restCount = 0;
      for (var i = 0; i < 14; i++) {
        final day = today.add(Duration(days: i));
        final wd = day.weekday - 1;
        final list = state.entriesOnDay(wd);
        final done = state.trainedOn(day);
        if (list.isNotEmpty) {
          if (!done) {
            final groups = <String>{
              for (final e in list)
                if (state.exercise(e.exerciseId) != null) state.meta.group(state.exercise(e.exerciseId)!.group),
            }.take(3).join(', ');
            final n = list.length;
            var body = '$n ${n == 1 ? 'exercício' : 'exercícios'}${groups.isEmpty ? '' : ': $groups'}.';
            if (s.notifMotivation) body += ' ${kMotivation[rnd.nextInt(kMotivation.length)]}';
            await _at(100 + i, day.add(Duration(minutes: s.notifMinutes)), 'Hoje é dia de treino$name! 💪', body);
            if (s.notifEvening) {
              await _at(200 + i, day.add(const Duration(hours: 19)), 'Ainda dá tempo de treinar hoje',
                  'Seu treino de ${weekdayLabel(wd).toLowerCase()} está esperando. Mesmo um treino curto conta!');
            }
          }
        } else if (s.notifMotivation && hasPlan && restCount++ % 2 == 0) {
          await _at(300 + i, day.add(const Duration(hours: 10)), 'Dia de descanso 😌',
              _kRestTips[rnd.nextInt(_kRestTips.length)]);
        }
        if (s.notifWeigh && day.weekday == DateTime.monday) {
          await _at(500 + i, day.add(const Duration(hours: 7, minutes: 30)), 'Hora da pesagem semanal ⚖️',
              'Pese-se em jejum, depois do banheiro, e registre no app para acompanhar sua evolução.');
        }
        if (s.notifMotivation && hasPlan && day.weekday == DateTime.sunday) {
          await _at(600 + i, day.add(const Duration(hours: 19)), 'Como foi sua semana?',
              'Abra o app para ver seu progresso e se preparar para a próxima semana.');
        }
      }
      if (s.notifInactive) {
        // só toca se a pessoa não abrir o app até lá (cada abertura reagenda)
        final t = hasPlan ? 'Sentimos sua falta! 🏋️' : 'Vamos montar seu treino?';
        final b = hasPlan
            ? 'Faz alguns dias que você não aparece. Que tal retomar hoje com um treino leve?'
            : 'Escolha um plano pronto ou monte sua lista de exercícios em poucos toques.';
        await _at(400, today.add(const Duration(days: 3, hours: 18)), t, b);
        await _at(401, today.add(const Duration(days: 7, hours: 18)), t,
            'Uma semana sem treinar. Recomeçar é normal: escolha um dia e volte com calma.');
      }
    } catch (e) {
      debugPrint('Falha ao agendar notificações: $e');
    }
  }

  /// Mostra uma notificação de teste agora.
  Future<void> test() async {
    if (!_ready) return;
    denied.value = !(await _permission());
    await _plugin.show(
      id: 999,
      title: 'Notificações ligadas ✅',
      body: 'É assim que o GM Fitness vai te lembrar dos treinos.',
      notificationDetails: _details('É assim que o GM Fitness vai te lembrar dos treinos.'),
    );
  }
}
