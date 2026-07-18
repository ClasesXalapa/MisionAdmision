import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    super.key,
  });

  final int selectedIndex;

  static const _items = <_NavigationItemData>[
    _NavigationItemData(
      label: 'Inicio',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: '/',
    ),
    _NavigationItemData(
      label: 'Reto',
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department_rounded,
      route: '/daily',
    ),
    _NavigationItemData(
      label: 'Recursos',
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
      route: '/resources',
    ),
    _NavigationItemData(
      label: 'Examen',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz_rounded,
      route: '/exam',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      key: const Key('app_bottom_navigation'),
      color: colors.surface,
      elevation: 18,
      shadowColor: const Color(0x33172135),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 108,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == selectedIndex;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: selected ? null : () => context.go(item.route),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selected ? item.selectedIcon : item.icon,
                              size: selected ? 46 : 42,
                              color: selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontSize: 18,
                                height: 1,
                                fontWeight: selected
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavigationItemData {
  const _NavigationItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
