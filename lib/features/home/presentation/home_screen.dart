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
        toolbarHeight: 76,
        title: const Text(
          'Misión Admisión',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.tune_rounded, size: 38),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
      body: SafeArea(
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
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 48),
            children: [
                const _WelcomeHeader(),
                const SizedBox(height: 28),
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
                const SizedBox(height: 24),
                _DailyChallengeCard(
                  hasPendingAttempt: hasPendingAttempt,
                  completedToday: completedToday,
                  answeredQuestions:
                      hasPendingAttempt ? currentAttempt!.answers.length : 0,
                  totalQuestions:
                      hasPendingAttempt ? currentAttempt!.questionIds.length : 10,
                  onPressed: () => context.go('/daily'),
                ),
                const SizedBox(height: 32),
                Text(
                  'Sigue practicando',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 31,
                        height: 1.12,
                      ),
                ),
                const SizedBox(height: 18),
              _QuickActions(
                onResources: () => context.go('/resources'),
                onExam: () => context.go('/exam'),
              ),
            ],
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
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 44,
                  height: 1.06,
                  letterSpacing: -0.7,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Avanza un poco cada día hacia tu ingreso al EXANI-II.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 22,
                height: 1.42,
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
    final nextStreak = progress.currentStreak + 1;
    final streakUnit = progress.currentStreak == 1 ? 'día' : 'días';
    final nextStreakUnit = nextStreak == 1 ? 'día' : 'días';

    return Card(
      key: const Key('home_progress_card'),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8C9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 40,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 29,
                              height: 1.1,
                            ),
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          rank!.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontSize: 20,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (completedToday)
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F5E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF18733C),
                      size: 31,
                    ),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 31),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFDFC0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFA84300),
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress.currentStreak} $streakUnit',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: const Color(0xFF8F3900),
                                fontSize: 48,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          completedToday ? 'Racha protegida hoy' : 'Racha actual',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF8F3900),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SecondaryMetric(
                    icon: Icons.emoji_events_rounded,
                    label: 'Mejor racha',
                    value: '${progress.bestStreak}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryMetric(
                    icon: Icons.shield_rounded,
                    label: 'Escudos',
                    value: '${progress.shields}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SecondaryMetric(
                    icon: Icons.task_alt_rounded,
                    label: 'Retos',
                    value: '${progress.totalDailyChallengesCompleted}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              completedToday
                  ? 'Tu racha está protegida por hoy. Sigue practicando a tu ritmo.'
                  : 'Completa el reto de hoy para alcanzar una racha de $nextStreak $nextStreakUnit.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 19,
                    height: 1.42,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.primary, size: 33),
              const SizedBox(height: 9),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontSize: 33,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 17,
                      height: 1.15,
                    ),
              ),
            ],
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
    final safeTotal = totalQuestions <= 0 ? 10 : totalQuestions;
    final safeAnswered = answeredQuestions.clamp(0, safeTotal).toInt();
    final progressValue = safeAnswered / safeTotal;
    final label = hasPendingAttempt
        ? 'Continuar reto · $safeAnswered de $safeTotal'
        : completedToday
            ? 'Practicar de nuevo'
            : 'Comenzar reto';

    return Card(
      key: const Key('home_daily_challenge_card'),
      color: const Color(0xFFEEF2FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'RETO DE HOY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontSize: 18,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (completedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F4E5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Color(0xFF18733C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Completado',
                          style: TextStyle(
                            color: Color(0xFF18733C),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              hasPendingAttempt ? 'Continúa donde te quedaste' : 'Tu misión diaria',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontSize: 35,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              hasPendingAttempt
                  ? 'Tu avance está guardado. Termina antes de que concluya el día.'
                  : completedToday
                      ? 'Tu racha ya está protegida. Puedes repetir el reto para seguir practicando.'
                      : 'Responde 10 preguntas y protege tu racha.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 21,
                    height: 1.42,
                  ),
            ),
            if (hasPendingAttempt) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Tu progreso',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 19,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '$safeAnswered de $safeTotal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontSize: 19,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 13,
                  backgroundColor: colors.primary.withValues(alpha: 0.13),
                  color: colors.primary,
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('home_daily_challenge_action'),
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(78),
                ),
                icon: Icon(
                  hasPendingAttempt
                      ? Icons.play_circle_fill_rounded
                      : Icons.play_arrow_rounded,
                  size: 32,
                ),
                label: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
    return Column(
      children: [
        _QuickActionTile(
          actionKey: const Key('home_resources_action'),
          icon: Icons.library_books_rounded,
          title: 'Biblioteca de recursos',
          description: 'Videos, guías y simulacros organizados por tema.',
          onPressed: onResources,
        ),
        const SizedBox(height: 16),
        _QuickActionTile(
          actionKey: const Key('home_exam_action'),
          icon: Icons.quiz_rounded,
          title: 'Examen libre',
          description: 'Practica con 10 preguntas aleatorias.',
          onPressed: onExam,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final Key actionKey;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: actionKey,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 148),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, color: colors.primary, size: 42),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 26,
                                height: 1.12,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 19,
                                height: 1.34,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colors.primary,
                    size: 40,
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
