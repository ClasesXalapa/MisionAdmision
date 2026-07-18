import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/rank.dart';
import 'package:mision_admision/features/content_sync/presentation/content_sync_card.dart';
import 'package:mision_admision/features/navigation/presentation/app_bottom_navigation.dart';
import 'package:mision_admision/features/notifications/presentation/notification_reminder_card.dart';
import 'package:mision_admision/features/progress/application/progress_providers.dart';
import 'package:mision_admision/features/pwa/presentation/pwa_status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openAppSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.88;
        return SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Configuración de la aplicación',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: const [
                    PwaStatusCard(),
                    SizedBox(height: 14),
                    NotificationReminderCard(),
                    SizedBox(height: 14),
                    ContentSyncCard(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(learnerProgressProvider);
    final pendingAttempt = ref.watch(pendingDailyAttemptProvider);
    final ranks = ref.watch(rankCatalogProvider);
    final today = localDateKey(ref.read(appClockProvider).now());
    final compact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = compact ? 16.0 : 24.0;
    final currentAttempt = pendingAttempt.asData?.value;
    final hasPendingAttempt = currentAttempt?.dateKey == today;
    final completedToday = progress.asData?.value.lastCompletedDateKey == today;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misión Admisión'),
        actions: [
          IconButton(
            tooltip: 'Configuración de la aplicación',
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(learnerProgressProvider)
                  ..invalidate(pendingDailyAttemptProvider)
                  ..invalidate(rankCatalogProvider);
                await ref.read(learnerProgressProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 8 : 18,
                  horizontalPadding,
                  28,
                ),
                children: [
                  const _WelcomeHeader(),
                  const SizedBox(height: 22),
                  progress.when(
                    data: (value) {
                      final rank = ranks.asData == null
                          ? null
                          : ref.read(rankEngineProvider).resolve(
                                ranks: ranks.asData!.value,
                                bestStreak: value.bestStreak,
                              );
                      return _ProgressSummary(
                        progress: value,
                        completedToday: value.lastCompletedDateKey == today,
                        rank: rank,
                        shieldUsedToday: value.lastShieldUsedDateKey == today &&
                            value.lastShieldUseCount > 0,
                      );
                    },
                    loading: () => const _ProgressLoading(),
                    error: (error, stackTrace) => const _ProgressError(),
                  ),
                  const SizedBox(height: 18),
                  _DailyChallengeCard(
                    hasPendingAttempt: hasPendingAttempt,
                    completedToday: completedToday,
                    answeredQuestions:
                        hasPendingAttempt ? currentAttempt!.answers.length : 0,
                    totalQuestions:
                        hasPendingAttempt ? currentAttempt!.questionIds.length : 10,
                    onPressed: () => context.go('/daily'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Continúa tu preparación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(
                    onResources: () => context.go('/resources'),
                    onExam: () => context.go('/exam'),
                  ),
                  const SizedBox(height: 20),
                  _SettingsShortcut(
                    onPressed: () => _openAppSettings(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Tu misión de hoy',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Practica, fortalece tu constancia y avanza hacia el EXANI-II.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.progress,
    required this.completedToday,
    required this.rank,
    required this.shieldUsedToday,
  });

  final LearnerProgress progress;
  final bool completedToday;
  final Rank? rank;
  final bool shieldUsedToday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5C2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 30,
                    color: Color(0xFFB64A00),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedToday ? '¡Misión cumplida!' : 'Tu progreso',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          rank!.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (completedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F5E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Color(0xFF18733C),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Hoy',
                          style: TextStyle(
                            color: Color(0xFF135D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 25),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final columns = constraints.maxWidth >= 620 ? 4 : 2;
                final width =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _Metric(
                      width: width,
                      icon: Icons.local_fire_department_rounded,
                      label: 'Racha actual',
                      value: '${progress.currentStreak}',
                      background: const Color(0xFFFFF0DD),
                      foreground: const Color(0xFFA84300),
                    ),
                    _Metric(
                      width: width,
                      icon: Icons.emoji_events_rounded,
                      label: 'Mejor racha',
                      value: '${progress.bestStreak}',
                      background: const Color(0xFFFFF6D8),
                      foreground: const Color(0xFF8B6500),
                    ),
                    _Metric(
                      width: width,
                      icon: Icons.shield_rounded,
                      label: 'Escudos',
                      value: '${progress.shields}',
                      background: const Color(0xFFE8EEFF),
                      foreground: const Color(0xFF315AC7),
                    ),
                    _Metric(
                      width: width,
                      icon: Icons.task_alt_rounded,
                      label: 'Retos hechos',
                      value: '${progress.totalDailyChallengesCompleted}',
                      background: const Color(0xFFE4F5E8),
                      foreground: const Color(0xFF18733C),
                    ),
                  ],
                );
              },
            ),
            if (rank != null) ...[
              const SizedBox(height: 14),
              Text(
                rank!.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Icon(icon, size: 27, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressLoading extends StatelessWidget {
  const _ProgressLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Text('No fue posible leer el progreso local.'),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.hasPendingAttempt,
    required this.completedToday,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.onPressed,
  });

  final bool hasPendingAttempt;
  final bool completedToday;
  final int answeredQuestions;
  final int totalQuestions;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = hasPendingAttempt
        ? 'Continuar reto · $answeredQuestions/$totalQuestions'
        : completedToday
            ? 'Practicar otra vez'
            : 'Hacer reto de hoy';

    return Card(
      color: colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    completedToday ? 'Completado' : '10 preguntas',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              hasPendingAttempt ? 'Tu reto te está esperando' : 'Reto diario',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasPendingAttempt
                  ? 'Tu avance está guardado. Continúa antes de que termine el día.'
                  : completedToday
                      ? 'Ya protegiste tu racha de hoy. Puedes repetirlo para practicar.'
                      : 'Responde 10 preguntas y protege tu racha. La calificación no afecta tu avance diario.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.primary,
                ),
                icon: Icon(
                  hasPendingAttempt ? Icons.play_circle_fill : Icons.play_arrow,
                ),
                label: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onResources,
    required this.onExam,
  });

  final VoidCallback onResources;
  final VoidCallback onExam;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.library_books_rounded,
                title: 'Recursos',
                description: 'Videos, guías y simulacros.',
                actionLabel: 'Explorar recursos',
                onPressed: onResources,
              ),
            ),
            const SizedBox(width: spacing),
            SizedBox(
              width: width,
              child: _QuickActionTile(
                icon: Icons.quiz_rounded,
                title: 'Examen libre',
                description: '10 preguntas para practicar.',
                actionLabel: 'Iniciar examen',
                onPressed: onExam,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: colors.primary, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsShortcut extends StatelessWidget {
  const _SettingsShortcut({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDDE2EE)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aplicación lista · revisa notificaciones y contenido',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
