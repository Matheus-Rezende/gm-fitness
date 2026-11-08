import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme/gm_theme.dart';
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

  MaterialApp _app(Widget home) => MaterialApp(
        title: 'GM Fitness',
        debugShowCheckedModeBanner: false,
        theme: buildGmTheme(Brightness.light),
        darkTheme: buildGmTheme(Brightness.dark),
        home: home,
      );

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
        return AppScope(state: snap.data!, child: _app(const _Root()));
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
