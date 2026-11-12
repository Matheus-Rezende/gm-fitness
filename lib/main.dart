import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'state/settings.dart';
import 'theme/gm_theme.dart';
import 'update/update_ui.dart';
import 'widgets/brand.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GmFitnessApp());
}

class GmFitnessApp extends StatefulWidget {
  const GmFitnessApp({super.key});

  @override
  State<GmFitnessApp> createState() => _GmFitnessAppState();
}

class _GmFitnessAppState extends State<GmFitnessApp> {
  late Future<AppState> _loading = AppState.load();

  MaterialApp _app(Widget home, [AppSettings? settings]) {
    // a chave do navegador só vai no app principal: se fosse também na tela
    // de carregamento, o navegador dela seria reaproveitado e o app ficaria
    // preso nessa tela
    final main = settings != null;
    final accent = settings?.accent.color ?? GmColors.blue;
    final scale = settings?.textScale ?? 1.0;
    return MaterialApp(
      title: 'GM Fitness',
      debugShowCheckedModeBanner: false,
      theme: buildGmTheme(Brightness.light, accent: accent),
      darkTheme: buildGmTheme(Brightness.dark, accent: accent),
      themeMode: settings?.themeMode ?? ThemeMode.system,
      navigatorKey: main ? updateNavigatorKey : null,
      builder: (context, child) {
        final app = UpdateProgressBanner(child: child!);
        if (scale == 1.0) return app;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: app,
        );
      },
      home: home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _loading,
      builder: (context, snap) {
        if (snap.hasError) {
          return _app(_LoadError(
            message: '${snap.error}',
            onRetry: () => setState(() => _loading = AppState.load()),
          ));
        }
        if (!snap.hasData) return _app(const _Splash());
        final state = snap.data!;
        return AppScope(
          state: state,
          child: ListenableBuilder(
            listenable: state.settings,
            builder: (_, _) => _app(const _Root(), state.settings),
          ),
        );
      },
    );
  }
}

/// Mostra o onboarding na primeira abertura e o app depois.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state.onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: GmLogo(size: 88)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível abrir os dados do app.'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      ),
    );
  }
}
