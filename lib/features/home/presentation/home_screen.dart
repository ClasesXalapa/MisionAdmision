import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/design_system.dart';
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
    final screenSize = MediaQuery.sizeOf(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: AppPalette.ink.withValues(alpha: 0.62),
      constraints: BoxConstraints(maxWidth: screenSize.width),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return FractionallySizedBox(
          heightFactor: 0.92,
          widthFactor: 1,
          child: Material(
            key: const Key('app_settings_sheet'),
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración',
                              style: Theme.of(sheetContext).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Instalación, recordatorios y contenido guardado.',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PwaStatusCard(),
                        SizedBox(height: 14),
                        NotificationReminderCard(),
                        SizedBox(height: 14),
                        ContentSyncCard(),
                      ],
                    ),
                  ),
                ),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppPalette.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            const Flexible(
              child: Text(
                'Misión Admisión',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Configuración',
              onPressed: () => _openAppSettings(context),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: [
              progress.when(
                data: (value) {
                  final rank = ranks.asData == null
                      ? null
                      : ref.read(rankEngineProvider).resolve(
                            ranks: ranks.asData!.value,
                            bestStreak: value.bestStreak,
                          );
                  return _MissionHero(
                    progress: value,
                    rank: rank,
                    completedToday: completedToday,
                  );
                },
                loading: () => const _ProgressLoading(),
                error: (error, stackTrace) => const _ProgressError(),
              ),
              const SizedBox(height: 16),
              progress.when(
                data: (value) => _ProgressSummary(
                  progress: value,
                  shieldUsedToday: value.lastShieldUsedDateKey == today &&
                      value.lastShieldUseCount > 0,
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
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
              const SizedBox(height: 26),
              const AppSectionHeading(
                title: 'Sigue practicando',
                subtitle: 'Elige cómo quieres avanzar hoy.',
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
    );
  }
}

class _MissionHero extends StatelessWidget {
  const _MissionHero({
    required this.progress,
    required this.rank,
    required this.completedToday,
  });

  final LearnerProgress progress;
  final Rank? rank;
  final bool completedToday;

  @override
  Widget build(BuildContext context) {
    final streakUnit = progress.currentStreak == 1 ? 'día' : 'días';

    return Container(
      key: const Key('home_progress_card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppPalette.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: AppShadows.raised,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -54,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 44,
            bottom: -62,
            child: Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                        rank?.name ?? 'Primer paso',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                    const Spacer(),
                    if (completedToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppPalette.success,
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Completado',
                              style: TextStyle(
                                color: AppPalette.success,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Tu misión de hoy',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  completedToday
                      ? 'Misión cumplida. Tu racha está protegida.'
                      : 'Un paso más cerca de tu ingreso al EXANI-II.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppPalette.amberSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFB85B00),
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progress.currentStreak} $streakUnit',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        Text(
                          'Racha actual',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.progress,
    required this.shieldUsedToday,
  });

  final LearnerProgress progress;
  final bool shieldUsedToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.emoji_events_rounded,
                label: 'Mejor racha',
                value: '${progress.bestStreak}',
                color: AppPalette.amber,
                background: AppPalette.amberSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.shield_rounded,
                label: 'Escudos',
                value: '${progress.shields}',
                color: AppPalette.teal,
                background: AppPalette.tealSoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.task_alt_rounded,
                label: 'Retos',
                value: '${progress.totalDailyChallengesCompleted}',
                color: AppPalette.primary,
                background: AppPalette.primarySoft,
              ),
            ),
          ],
        ),
        if (shieldUsedToday) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppPalette.tealSoft,
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppPalette.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress.lastShieldUseCount == 1
                        ? 'Un escudo protegió tu racha.'
                        : '${progress.lastShieldUseCount} escudos protegieron tu racha.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF075B54),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: AppPalette.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBadge(
              icon: icon,
              foreground: color,
              background: background,
              size: 38,
              iconSize: 21,
              radius: 12,
            ),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
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
      child: SizedBox(
        height: 230,
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
    final safeTotal = totalQuestions <= 0 ? 10 : totalQuestions;
    final safeAnswered = answeredQuestions.clamp(0, safeTotal).toInt();
    final progressValue = safeAnswered / safeTotal;
    final label = hasPendingAttempt
        ? 'Continuar reto'
        : completedToday
            ? 'Practicar de nuevo'
            : 'Comenzar reto';

    return Container(
      key: const Key('home_daily_challenge_card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppPalette.challengeGradient,
        borderRadius: BorderRadius.circular(AppRadii.large),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -28,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIconBadge(
                      icon: Icons.bolt_rounded,
                      foreground: AppPalette.primaryDark,
                      background: Colors.white,
                      size: 46,
                      iconSize: 26,
                      radius: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'RETO DE HOY',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                    if (completedToday)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF8CF0D5),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  hasPendingAttempt
                      ? 'Continúa donde te quedaste'
                      : completedToday
                          ? 'Sigue entrenando'
                          : 'Completa 10 preguntas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 7),
                Text(
                  hasPendingAttempt
                      ? 'Tu avance está guardado en este dispositivo.'
                      : completedToday
                          ? 'La misión ya contó para tu racha de hoy.'
                          : 'Protege tu racha y mejora un poco cada día.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                ),
                if (hasPendingAttempt) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Progreso',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '$safeAnswered de $safeTotal',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    color: const Color(0xFF8CF0D5),
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('home_daily_challenge_action'),
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.primaryDark,
                    ),
                    icon: Icon(
                      hasPendingAttempt
                          ? Icons.play_circle_fill_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(label),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          icon: Icons.video_library_rounded,
          eyebrow: 'APRENDE',
          title: 'Biblioteca de recursos',
          description: 'Videos, guías y simulacros por tema.',
          accent: AppPalette.teal,
          accentSoft: AppPalette.tealSoft,
          onPressed: onResources,
        ),
        const SizedBox(height: 12),
        _QuickActionTile(
          actionKey: const Key('home_exam_action'),
          icon: Icons.quiz_rounded,
          eyebrow: 'PONTE A PRUEBA',
          title: 'Examen libre',
          description: '10 preguntas aleatorias para practicar.',
          accent: AppPalette.primary,
          accentSoft: AppPalette.primarySoft,
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
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.accentSoft,
    required this.onPressed,
  });

  final Key actionKey;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color accent;
  final Color accentSoft;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: actionKey,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              AppIconBadge(
                icon: icon,
                foreground: accent,
                background: accentSoft,
                size: 64,
                iconSize: 33,
                radius: 19,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent,
                            letterSpacing: 0.7,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_rounded, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
