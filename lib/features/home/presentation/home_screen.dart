import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/rank.dart';
import 'package:mision_admision/features/content_sync/presentation/content_sync_card.dart';
import 'package:mision_admision/features/notifications/presentation/notification_reminder_card.dart';
import 'package:mision_admision/features/progress/application/progress_providers.dart';
import 'package:mision_admision/features/pwa/presentation/pwa_status_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(learnerProgressProvider);
    final pendingAttempt = ref.watch(pendingDailyAttemptProvider);
    final ranks = ref.watch(rankCatalogProvider);
    final today = localDateKey(ref.read(appClockProvider).now());
    final compact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = compact ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Misión Admisión')),
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
                  compact ? 12 : 20,
                  horizontalPadding,
                  32,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Prepárate para el EXANI-II',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Practica cada día, encuentra los recursos correctos y fortalece tu constancia.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
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
                    hasPendingAttempt:
                        pendingAttempt.asData?.value?.dateKey == today,
                    completedToday:
                        progress.asData?.value.lastCompletedDateKey == today,
                    onPressed: () => context.go('/daily'),
                  ),
                  const SizedBox(height: 16),
                  _ResourcesCard(onPressed: () => context.go('/resources')),
                  const SizedBox(height: 16),
                  _FreeExamCard(onPressed: () => context.go('/exam')),
                  const SizedBox(height: 16),
                  const PwaStatusCard(),
                  const SizedBox(height: 16),
                  const NotificationReminderCard(),
                  const SizedBox(height: 16),
                  const ContentSyncCard(),
                ],
              ),
            ),
          ),
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedToday
                            ? 'Reto de hoy completado'
                            : 'Tu progreso',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(
                            Icons.workspace_premium_outlined,
                            size: 20,
                          ),
                          label: Text(rank!.name),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 28),
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
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
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
                      label: 'Racha actual',
                      value: '${progress.currentStreak}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Mejor racha',
                      value: '${progress.bestStreak}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Escudos',
                      value: '${progress.shields}',
                    ),
                    _Metric(
                      width: width,
                      label: 'Retos hechos',
                      value: '${progress.totalDailyChallengesCompleted}',
                    ),
                  ],
                );
              },
            ),
            if (rank != null) ...[
              const SizedBox(height: 16),
              Text(
                rank!.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
    required this.onPressed,
  });

  final bool hasPendingAttempt;
  final bool completedToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = hasPendingAttempt
        ? 'Continuar reto'
        : completedToday
            ? 'Repetir reto'
            : 'Hacer reto de hoy';

    return _ActionCard(
      icon: Icons.local_fire_department_outlined,
      title: 'Reto diario',
      description: hasPendingAttempt
          ? 'Tu avance está guardado. Puedes continuar antes de que termine el día.'
          : 'Completa el reto para mantener o iniciar tu racha. La calificación no afecta la racha.',
      buttonLabel: label,
      buttonIcon: hasPendingAttempt ? Icons.restore : Icons.play_arrow,
      onPressed: onPressed,
      filled: true,
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.library_books_outlined,
      title: 'Recursos',
      description:
          'Videos, guías, formularios y simulacros organizados por tipo y materia.',
      buttonLabel: 'Explorar recursos',
      buttonIcon: Icons.arrow_forward,
      onPressed: onPressed,
    );
  }
}

class _FreeExamCard extends StatelessWidget {
  const _FreeExamCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.quiz_outlined,
      title: 'Examen libre',
      description: 'Responde 10 preguntas aleatorias sin afectar tu racha.',
      buttonLabel: 'Iniciar examen',
      buttonIcon: Icons.play_arrow_rounded,
      onPressed: onPressed,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final button = filled
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon, size: 24),
            label: Text(buttonLabel),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon, size: 24),
            label: Text(buttonLabel),
          );

    return Card(
      color: filled ? colors.primaryContainer.withValues(alpha: 0.34) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: filled ? colors.primary : colors.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 32,
                color: filled ? colors.onPrimary : colors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: button),
          ],
        ),
      ),
    );
  }
}
