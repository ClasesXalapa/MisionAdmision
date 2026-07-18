import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/responsive.dart';
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
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.9;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: Theme.of(sheetContext).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado de instalación, recordatorios y contenido.',
                  style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(sheetContext)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                const PwaStatusCard(),
                const SizedBox(height: 16),
                const NotificationReminderCard(),
                const SizedBox(height: 16),
                const ContentSyncCard(),
              ],
            ),
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
    final currentAttempt = pendingAttempt.asData?.value;
    final hasPendingAttempt = currentAttempt?.dateKey == today;
    final completedToday = progress.asData?.value.lastCompletedDateKey == today;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misión Admisión'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 10),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
      body: SafeArea(
        child: fullWidthCentered(
          maxWidth: 820,
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
                appHorizontalPadding(context),
                14,
                appHorizontalPadding(context),
                34,
              ),
              children: [
                const _WelcomeHeader(),
                const SizedBox(height: 26),
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
                const SizedBox(height: 22),
                _DailyChallengeCard(
                  hasPendingAttempt: hasPendingAttempt,
                  completedToday: completedToday,
                  answeredQuestions:
                      hasPendingAttempt ? currentAttempt!.answers.length : 0,
                  totalQuestions:
                      hasPendingAttempt ? currentAttempt!.questionIds.length : 10,
                  onPressed: () => context.go('/daily'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Sigue practicando',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                _QuickActions(
                  onResources: () => context.go('/resources'),
                  onExam: () => context.go('/exam'),
                ),
              ],
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
        const SizedBox(height: 10),
        Text(
          'Avanza un poco cada día hacia tu ingreso al EXANI-II.',
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
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8C9),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 36,
                    color: Color(0xFFB64A00),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedToday ? '¡Misión cumplida!' : 'Tu progreso',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          rank!.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (completedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F5E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF18733C),
                      size: 25,
                    ),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 29),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final columns = isHandsetLayout(context)
                    ? 2
                    : constraints.maxWidth >= 900
                        ? 4
                        : 2;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
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
                      foreground: const Color(0xFF806000),
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
                      label: 'Retos completados',
                      value: '${progress.totalDailyChallengesCompleted}',
                      background: const Color(0xFFE4F5E8),
                      foreground: const Color(0xFF18733C),
                    ),
                  ],
                );
              },
            ),
            if (rank != null) ...[
              const SizedBox(height: 18),
              Text(
                rank!.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          height: 132,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 31, color: foreground),
                    const Spacer(),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
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
        padding: EdgeInsets.all(34),
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
        padding: EdgeInsets.all(24),
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
        ? 'Continuar reto · $answeredQuestions de $totalQuestions'
        : completedToday
            ? 'Practicar otra vez'
            : 'Comenzar reto de hoy';

    return Card(
      color: colors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    completedToday ? 'Completado hoy' : '10 preguntas',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              hasPendingAttempt ? 'Continúa donde te quedaste' : 'Reto diario',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              hasPendingAttempt
                  ? 'Tu avance está guardado. Termina antes de que concluya el día.'
                  : completedToday
                      ? 'Tu racha ya está protegida. Puedes repetir el reto para seguir practicando.'
                      : 'Responde 10 preguntas y protege tu racha diaria.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.primary,
                  minimumSize: const Size.fromHeight(68),
                ),
                icon: Icon(
                  hasPendingAttempt
                      ? Icons.play_circle_fill_rounded
                      : Icons.play_arrow_rounded,
                  size: 29,
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
    final cards = [
      _QuickActionTile(
        icon: Icons.library_books_rounded,
        title: 'Biblioteca de recursos',
        description: 'Videos, guías y simulacros organizados por tema.',
        actionLabel: 'Explorar recursos',
        onPressed: onResources,
      ),
      _QuickActionTile(
        icon: Icons.quiz_rounded,
        title: 'Examen libre',
        description: 'Practica con 10 preguntas sin afectar tu racha.',
        actionLabel: 'Iniciar examen',
        onPressed: onExam,
      ),
    ];

    if (isHandsetLayout(context)) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 14),
          cards[1],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 14),
        Expanded(child: cards[1]),
      ],
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
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(icon, color: colors.primary, size: 35),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: colors.primary,
                size: 31,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
