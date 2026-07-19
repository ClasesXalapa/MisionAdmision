import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/design_system.dart';

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
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories_rounded,
      route: '/resources',
    ),
    _NavigationItemData(
      label: 'Examen',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check_rounded,
      route: '/exam',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      key: const Key('app_bottom_navigation'),
      color: colors.surface,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppPalette.outline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F17162B),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 88,
            child: Row(
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = index == selectedIndex;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: InkWell(
                      onTap: selected ? null : () => context.go(item.route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 9,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppPalette.primarySoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selected ? item.selectedIcon : item.icon,
                                size: selected ? 30 : 27,
                                color: selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: selected
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                      fontWeight: selected
                                          ? FontWeight.w800
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
