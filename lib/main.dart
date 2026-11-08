import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GmFitnessApp());
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFE0457B), brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    visualDensity: VisualDensity.standard,
  );
}

class GmFitnessApp extends StatefulWidget {
  const GmFitnessApp({super.key});

  @override
  State<GmFitnessApp> createState() => _GmFitnessAppState();
}

class _GmFitnessAppState extends State<GmFitnessApp> {
  late Future<AppState> _loading = AppState.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _loading,
      builder: (context, snap) {
        final Widget home;
        if (snap.hasError) {
          home = _LoadError(
            message: '${snap.error}',
            onRetry: () => setState(() => _loading = AppState.load()),
          );
        } else if (!snap.hasData) {
          home = const _Splash();
        } else {
          return AppScope(
            state: snap.data!,
            child: MaterialApp(
              title: 'GM Fitness',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(Brightness.light),
              darkTheme: buildTheme(Brightness.dark),
              home: const HomeShell(),
            ),
          );
        }
        return MaterialApp(
          title: 'GM Fitness',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: home,
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text('GM Fitness', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
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
