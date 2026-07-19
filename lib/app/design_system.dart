import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const background = Color(0xFFF5F6FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF0F2FA);
  static const ink = Color(0xFF17162B);
  static const inkMuted = Color(0xFF62627A);
  static const outline = Color(0xFFE1E3EE);

  static const primary = Color(0xFF5B4BDB);
  static const primaryDark = Color(0xFF342B8C);
  static const primarySoft = Color(0xFFE9E7FF);
  static const violet = Color(0xFF8B5CF6);
  static const teal = Color(0xFF12A594);
  static const tealSoft = Color(0xFFDCF7F2);
  static const amber = Color(0xFFFFB648);
  static const amberSoft = Color(0xFFFFF0D5);
  static const coral = Color(0xFFFF6B6B);
  static const success = Color(0xFF18855E);
  static const successSoft = Color(0xFFE1F6EE);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5145CD), Color(0xFF8367EE)],
  );

  static const challengeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF221F5E), Color(0xFF5949C8)],
  );

  static const resourceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E8E83), Color(0xFF19B69F)],
  );
}

abstract final class AppRadii {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
  static const hero = 30.0;
}

abstract final class AppShadows {
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x1017162B),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A342B8C),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    this.foreground = AppPalette.primary,
    this.background = AppPalette.primarySoft,
    this.size = 52,
    this.iconSize = 27,
    this.radius = 16,
    super.key,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
