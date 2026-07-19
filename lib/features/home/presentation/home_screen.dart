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
        toolbarHeight: 128,
        title: const Text(
          'Misión Admisión',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => _openAppSettings(context),
            icon: const Icon(Icons.tune_rounded, size: 56),
          ),
          const SizedBox(width: 12),
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
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 150),
            children: [
              const _WelcomeHeader(),
              const SizedBox(height: 54),
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
              const SizedBox(height: 48),
              _DailyChallengeCard(
                hasPendingAttempt: hasPendingAttempt,
                completedToday: completedToday,
                answeredQuestions:
                    hasPendingAttempt ? currentAttempt!.answers.length : 0,
                totalQuestions:
                    hasPendingAttempt ? currentAttempt!.questionIds.length : 10,
                onPressed: () => context.go('/daily'),
              ),
              const SizedBox(height: 64),
              Text(
                'Sigue practicando',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 46,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 38),
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
        FractionallySizedBox(
          widthFactor: 0.84,
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text(
              'Tu misión de hoy',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 68,
                    height: 1,
                    letterSpacing: -1.4,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        FractionallySizedBox(
          widthFactor: 0.76,
          alignment: Alignment.centerLeft,
          child: Text(
            'Avanza un poco cada día hacia tu ingreso al EXANI-II.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 32,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
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
        padding: const EdgeInsets.all(44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8C9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    size: 68,
                    color: Color(0xFFB64A00),
                  ),
                ),
                const SizedBox(width: 26),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completedToday ? '¡Misión cumplida!' : 'Tu progreso',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 44,
                              height: 1.04,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          rank!.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontSize: 31,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (completedToday)
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F5E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF18733C),
                      size: 44,
                    ),
                  ),
              ],
            ),
            if (shieldUsedToday) ...[
              const SizedBox(height: 38),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, size: 52),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        progress.lastShieldUseCount == 1
                            ? 'Un escudo protegió tu racha.'
                            : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 28,
                              height: 1.32,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 42),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 340),
              padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 48),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 126,
                    height: 126,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFDFC0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFA84300),
                      size: 78,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    '${progress.currentStreak} $streakUnit',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFF8F3900),
                          fontSize: 76,
                          height: 0.98,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    completedToday ? 'Racha protegida hoy' : 'Racha actual',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF8F3900),
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SecondaryMetric(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor racha',
              value: '${progress.bestStreak}',
            ),
            const SizedBox(height: 22),
            _SecondaryMetric(
              icon: Icons.shield_rounded,
              label: 'Escudos',
              value: '${progress.shields}',
            ),
            const SizedBox(height: 22),
            _SecondaryMetric(
              icon: Icons.task_alt_rounded,
              label: 'Retos',
              value: '${progress.totalDailyChallengesCompleted}',
            ),
            const SizedBox(height: 44),
            FractionallySizedBox(
              widthFactor: 0.84,
              alignment: Alignment.centerLeft,
              child: Text(
                completedToday
                    ? 'Tu racha está protegida por hoy. Sigue practicando a tu ritmo.'
                    : 'Completa el reto de hoy para alcanzar una racha de $nextStreak $nextStreakUnit.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 29,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
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
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 34),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F9),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, color: colors.primary, size: 58),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 32,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 60,
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
        padding: EdgeInsets.all(72),
        child: Center(child: CircularProgressIndicator(strokeWidth: 7)),
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
        padding: EdgeInsets.all(52),
        child: Text(
          'No fue posible leer el progreso local.',
          style: TextStyle(fontSize: 30, height: 1.35),
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
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 68,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 26),
                  Expanded(
                    child: Text(
                      'RETO DE HOY',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontSize: 29,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  if (completedToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
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
                            size: 32,
                            color: Color(0xFF18733C),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Completado',
                            style: TextStyle(
                              color: Color(0xFF18733C),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 52),
              FractionallySizedBox(
                widthFactor: 0.84,
                alignment: Alignment.centerLeft,
                child: Text(
                  hasPendingAttempt
                      ? 'Continúa donde te quedaste'
                      : 'Tu misión diaria',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontSize: 56,
                        height: 1.03,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 28),
              FractionallySizedBox(
                widthFactor: 0.78,
                alignment: Alignment.centerLeft,
                child: Text(
                  hasPendingAttempt
                      ? 'Tu avance está guardado. Termina antes de que concluya el día.'
                      : completedToday
                          ? 'Tu racha ya está protegida. Puedes repetir el reto para seguir practicando.'
                          : 'Responde 10 preguntas y protege tu racha.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 32,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 72),
              if (hasPendingAttempt) ...[
                Row(
                  children: [
                    Text(
                      'Tu progreso',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '$safeAnswered de $safeTotal',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.primary,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 24,
                    backgroundColor: colors.primary.withValues(alpha: 0.13),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 42),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('home_daily_challenge_action'),
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    minimumSize: const Size.fromHeight(120),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: Icon(
                    hasPendingAttempt
                        ? Icons.play_circle_fill_rounded
                        : Icons.play_arrow_rounded,
                    size: 50,
                  ),
                  label: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        const SizedBox(height: 42),
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
            constraints: const BoxConstraints(minHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(icon, color: colors.primary, size: 88),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.primary,
                          size: 58,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 92),
                  FractionallySizedBox(
                    widthFactor: 0.86,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 48,
                            height: 1.04,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FractionallySizedBox(
                    widthFactor: 0.76,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 31,
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                          ),
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
