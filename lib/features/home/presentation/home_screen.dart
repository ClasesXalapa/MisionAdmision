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
        toolbarHeight: 92,
        title: const Text(
          'Misión Admisión',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.tune_rounded, size: 46),
          ),
          const SizedBox(width: 10),
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
            padding: const EdgeInsets.fromLTRB(14, 24, 14, 72),
            children: [
                const _WelcomeHeader(),
                const SizedBox(height: 36),
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
                const SizedBox(height: 32),
                _DailyChallengeCard(
                  hasPendingAttempt: hasPendingAttempt,
                  completedToday: completedToday,
                  answeredQuestions:
                      hasPendingAttempt ? currentAttempt!.answers.length : 0,
                  totalQuestions:
                      hasPendingAttempt ? currentAttempt!.questionIds.length : 10,
                  onPressed: () => context.go('/daily'),
                ),
                const SizedBox(height: 42),
                Text(
                  'Sigue practicando',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 36,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 30),
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
                  fontSize: 50,
                  height: 1.04,
                  letterSpacing: -0.9,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Avanza un poco cada día hacia tu ingreso al EXANI-II.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 25,
                height: 1.44,
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
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8C9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 48,
                    color: Color(0xFFB64A00),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedToday ? '¡Misión cumplida!' : 'Tu progreso',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 34,
                              height: 1.08,
                            ),
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          rank!.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontSize: 24,
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
                      size: 36,
                    ),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 38),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFDFC0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFA84300),
                      size: 56,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress.currentStreak} $streakUnit',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: const Color(0xFF8F3900),
                                fontSize: 60,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          completedToday ? 'Racha protegida hoy' : 'Racha actual',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF8F3900),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SecondaryMetric(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor racha',
              value: '${progress.bestStreak}',
            ),
            const SizedBox(height: 14),
            _SecondaryMetric(
              icon: Icons.shield_rounded,
              label: 'Escudos',
              value: '${progress.shields}',
            ),
            const SizedBox(height: 14),
            _SecondaryMetric(
              icon: Icons.task_alt_rounded,
              label: 'Retos',
              value: '${progress.totalDailyChallengesCompleted}',
            ),
            const SizedBox(height: 32),
            Text(
              completedToday
                  ? 'Tu racha está protegida por hoy. Sigue practicando a tu ritmo.'
                  : 'Completa el reto de hoy para alcanzar una racha de $nextStreak $nextStreakUnit.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 22,
                    height: 1.45,
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
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: colors.primary, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 23,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w900,
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
        padding: EdgeInsets.all(52),
        child: Center(child: CircularProgressIndicator(strokeWidth: 5)),
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
        padding: EdgeInsets.all(36),
        child: Text(
          'No fue posible leer el progreso local.',
          style: TextStyle(fontSize: 22),
        ),
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
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'RETO DE HOY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontSize: 22,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (completedToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
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
                          size: 26,
                          color: Color(0xFF18733C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Completado',
                          style: TextStyle(
                            color: Color(0xFF18733C),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              hasPendingAttempt ? 'Continúa donde te quedaste' : 'Tu misión diaria',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontSize: 41,
                    height: 1.08,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              hasPendingAttempt
                  ? 'Tu avance está guardado. Termina antes de que concluya el día.'
                  : completedToday
                      ? 'Tu racha ya está protegida. Puedes repetir el reto para seguir practicando.'
                      : 'Responde 10 preguntas y protege tu racha.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 24,
                    height: 1.45,
                  ),
            ),
            if (hasPendingAttempt) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  Text(
                    'Tu progreso',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 22,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '$safeAnswered de $safeTotal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontSize: 22,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 17,
                  backgroundColor: colors.primary.withValues(alpha: 0.13),
                  color: colors.primary,
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('home_daily_challenge_action'),
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(90),
                ),
                icon: Icon(
                  hasPendingAttempt
                      ? Icons.play_circle_fill_rounded
                      : Icons.play_arrow_rounded,
                  size: 38,
                ),
                label: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
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
        const SizedBox(height: 28),
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
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: actionKey,
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 236),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(icon, color: colors.primary, size: 66),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 35,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 25,
                                height: 1.42,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.primary,
                      size: 46,
                    ),
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
