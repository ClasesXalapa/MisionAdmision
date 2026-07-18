import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/responsive.dart';
import 'package:mision_admision/app/router.dart';
import 'package:mision_admision/app/theme.dart';

class MissionAdmissionApp extends ConsumerWidget {
  const MissionAdmissionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Misión Admisión',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: buildLightTheme(),
      highContrastTheme: buildHighContrastLightTheme(),
      themeMode: ThemeMode.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(resolvedTextScale(context)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
