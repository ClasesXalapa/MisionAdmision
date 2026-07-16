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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misión Admisión'),
        actions: [
          IconButton(
            tooltip: 'Datos y respaldo',
            onPressed: () => context.go('/data'),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
        ],
      ),
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
                padding: const EdgeInsets.all(24),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Prepárate para el EXANI-II',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Practica cada día, encuentra los recursos correctos y fortalece tu constancia.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
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
                  _DataManagementCard(onPressed: () => context.go('/data')),
                  const SizedBox(height: 16),
                  const PwaStatusCard(),
                  const SizedBox(height: 16),
                  const NotificationReminderCard(),
                  const SizedBox(height: 16),
                  const ContentSyncCard(),
                  const SizedBox(height: 16),
                  const _LocalStorageNotice(),
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
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    completedToday ? 'Reto de hoy completado' : 'Tu progreso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (rank != null)
                  Chip(
                    avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
                    label: Text(rank!.name),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(label: 'Racha actual', value: '${progress.currentStreak}'),
                _Metric(label: 'Mejor racha', value: '${progress.bestStreak}'),
                _Metric(label: 'Escudos', value: '${progress.shields}'),
                _Metric(
                  label: 'Retos hechos',
                  value: '${progress.totalDailyChallengesCompleted}',
                ),
              ],
            ),
            if (rank != null) ...[
              const SizedBox(height: 14),
              Text(
                rank!.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 150,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
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
        padding: EdgeInsets.all(24),
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
        padding: EdgeInsets.all(20),
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


class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      icon: Icons.save_alt_outlined,
      title: 'Datos y respaldo',
      description:
          'Exporta tu avance, restaura un respaldo o reinicia los datos guardados en este navegador.',
      buttonLabel: 'Administrar progreso',
      buttonIcon: Icons.arrow_forward,
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
    final button = filled
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: button),
          ],
        ),
      ),
    );
  }
}

class _LocalStorageNotice extends StatelessWidget {
  const _LocalStorageNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.save_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'El progreso, los escudos y los recursos marcados se guardan únicamente en este navegador y dispositivo.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
