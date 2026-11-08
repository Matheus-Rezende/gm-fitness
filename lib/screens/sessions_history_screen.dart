import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../models/session.dart';
import '../state/app_state.dart';
import '../theme/gm_theme.dart';
import 'session_feedback_screen.dart';

/// Lista dos treinos concluídos, do mais recente ao mais antigo.
class SessionsHistoryScreen extends StatelessWidget {
  const SessionsHistoryScreen({super.key});

  String _date(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} às ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final sessions = state.sessions;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final last7 = sessions.where((s) => DateTime.now().difference(s.startedAt).inDays < 7).toList();
    final weekMinutes = last7.fold(0, (a, s) => a + s.duration.inMinutes);
    final weekLoad = last7.fold(0, (a, s) => a + s.sessionLoad);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de treinos')),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 48, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum treino registrado ainda. Na aba Treino, toque em "Iniciar treino" para cronometrar '
                      'o treino do dia e ver a intensidade no final.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: GmColors.ink, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      _Big(value: '${last7.length}', label: 'treinos em 7 dias'),
                      _Big(value: '$weekMinutes', label: 'minutos'),
                      _Big(value: '$weekLoad', label: 'pontos de carga'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in sessions)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      leading: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: intensityColor(intensityOf(s.rpe)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${s.rpe}',
                            style: const TextStyle(
                                fontFamily: display, fontWeight: FontWeight.w800, fontSize: 24, color: GmColors.ink)),
                      ),
                      title: Text('${weekdayLabel(s.weekday)} · ${intensityOf(s.rpe).label}'),
                      subtitle: Text('${_date(s.startedAt)}\n'
                          '${formatDuration(s.duration)} · ${s.setsDone}/${s.setsPlanned} séries'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => SessionFeedbackScreen(session: s, fromHistory: true))),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: display, fontWeight: FontWeight.w800, fontSize: 34, height: 1, color: Colors.white)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
