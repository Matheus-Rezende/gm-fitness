import 'package:flutter/material.dart';

import 'catalog_screen.dart';
import 'my_workouts_screen.dart';
import 'presets_screen.dart';

/// Aba ativa da tela inicial; outras telas podem trocar de aba por aqui.
final homeTab = ValueNotifier<int>(0);

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: homeTab,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(
          index: tab,
          children: const [
            MyWorkoutsScreen(),
            CatalogScreen(),
            PresetsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => homeTab.value = i,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today_rounded), label: 'Treino'),
            NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Exercícios'),
            NavigationDestination(
                icon: Icon(Icons.accessibility_new_outlined),
                selectedIcon: Icon(Icons.accessibility_new),
                label: 'Planos'),
          ],
        ),
      ),
    );
  }
}
