import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    super.key,
  });

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/daily');
            break;
          case 2:
            context.go('/resources');
            break;
          case 3:
            context.go('/exam');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_fire_department_outlined),
          selectedIcon: Icon(Icons.local_fire_department_rounded),
          label: 'Reto',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books_rounded),
          label: 'Recursos',
        ),
        NavigationDestination(
          icon: Icon(Icons.quiz_outlined),
          selectedIcon: Icon(Icons.quiz_rounded),
          label: 'Examen',
        ),
      ],
    );
  }
}
