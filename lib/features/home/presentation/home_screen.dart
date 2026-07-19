import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/design_system.dart';
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
        final responsive = sheetContext.responsive;
        return FractionallySizedBox(
          heightFactor: 0.95,
          widthFactor: 1,
          child: Material(
            key: const Key('app_settings_sheet'),
            color: colors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(responsive.heroRadius),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: responsive.compactGap),
                Container(
                  width: responsive.widthValue(0.1, minimum: 48, maximum: 76),
                  height: responsive.value(0.01, minimum: 4, maximum: 7),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.pagePadding,
                    responsive.itemGap,
                    responsive.pagePadding,
                    responsive.itemGap,
                  ),
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
                            SizedBox(height: responsive.compactGap * 0.65),
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
                      SizedBox(width: responsive.itemGap),
                      IconButton.filledTonal(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      responsive.pagePadding,
                      responsive.itemGap,
                      responsive.pagePadding,
                      responsive.sectionGap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PwaStatusCard(),
                        SizedBox(height: responsive.itemGap),
                        const NotificationReminderCard(),
                        SizedBox(height: responsive.itemGap),
                        const ContentSyncCard(),
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
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsive.iconBadgeSize * 0.82,
              height: responsive.iconBadgeSize * 0.82,
              decoration: BoxDecoration(
                gradient: AppPalette.heroGradient,
                borderRadius: BorderRadius.circular(responsive.smallRadius),
              ),
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: responsive.iconSize * 0.88,
              ),
            ),
            SizedBox(width: responsive.itemGap),
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
            padding: EdgeInsets.only(right: responsive.pagePadding * 0.7),
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              responsive.pagePadding,
              responsive.compactGap,
              responsive.pagePadding,
              responsive.sectionGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: responsive.itemGap),
                progress.when(
                  data: (value) => _ProgressSummary(
                    progress: value,
                    shieldUsedToday: value.lastShieldUsedDateKey == today &&
                        value.lastShieldUseCount > 0,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                ),
                SizedBox(height: responsive.sectionGap * 0.72),
                _DailyChallengeCard(
                  hasPendingAttempt: hasPendingAttempt,
                  completedToday: completedToday,
                  answeredQuestions:
                      hasPendingAttempt ? currentAttempt!.answers.length : 0,
                  totalQuestions: hasPendingAttempt
                      ? currentAttempt!.questionIds.length
                      : 10,
                  onPressed: () => context.go('/daily'),
                ),
                SizedBox(height: responsive.sectionGap),
                const AppSectionHeading(
                  title: 'Sigue practicando',
                  subtitle: 'Elige cómo quieres avanzar hoy.',
                ),
                SizedBox(height: responsive.itemGap),
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
    final responsive = context.responsive;

    return Container(
      key: const Key('home_progress_card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppPalette.heroGradient,
        borderRadius: BorderRadius.circular(responsive.heroRadius),
        boxShadow: AppShadows.raised,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -responsive.value(0.08, minimum: 30, maximum: 60),
            top: -responsive.value(0.1, minimum: 40, maximum: 75),
            child: Container(
              width: responsive.widthValue(0.32, minimum: 145, maximum: 230),
              height: responsive.widthValue(0.32, minimum: 145, maximum: 230),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: responsive.widthValue(0.08, minimum: 30, maximum: 58),
            bottom: -responsive.value(0.11, minimum: 45, maximum: 80),
            child: Container(
              width: responsive.widthValue(0.26, minimum: 120, maximum: 190),
              height: responsive.widthValue(0.26, minimum: 120, maximum: 190),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.value(0.025, minimum: 10, maximum: 18),
                        vertical: responsive.value(0.015, minimum: 6, maximum: 11),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(responsive.largeRadius),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value(0.024, minimum: 9, maximum: 17),
                          vertical: responsive.value(0.015, minimum: 6, maximum: 11),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(responsive.largeRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppPalette.success,
                              size: responsive.iconSize * 0.65,
                            ),
                            SizedBox(width: responsive.compactGap * 0.55),
                            const Text(
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
                SizedBox(height: responsive.sectionGap),
                Text(
                  'Tu misión de hoy',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                SizedBox(height: responsive.compactGap),
                Text(
                  completedToday
                      ? 'Misión cumplida. Tu racha está protegida.'
                      : 'Un paso más cerca de tu ingreso al EXANI-II.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
                SizedBox(height: responsive.itemGap * 1.4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: responsive.iconBadgeSize * 1.15,
                      height: responsive.iconBadgeSize * 1.15,
                      decoration: BoxDecoration(
                        color: AppPalette.amberSoft,
                        borderRadius: BorderRadius.circular(responsive.mediumRadius),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: const Color(0xFFB85B00),
                        size: responsive.iconSize * 1.25,
                      ),
                    ),
                    SizedBox(width: responsive.itemGap),
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
    final responsive = context.responsive;
    return Column(
      children: [
        _MetricCard(
          icon: Icons.emoji_events_rounded,
          label: 'Mejor racha',
          value: '${progress.bestStreak}',
          color: AppPalette.amber,
          background: AppPalette.amberSoft,
        ),
        SizedBox(height: responsive.compactGap),
        _MetricCard(
          icon: Icons.shield_rounded,
          label: 'Escudos',
          value: '${progress.shields}',
          color: AppPalette.teal,
          background: AppPalette.tealSoft,
        ),
        SizedBox(height: responsive.compactGap),
        _MetricCard(
          icon: Icons.task_alt_rounded,
          label: 'Retos',
          value: '${progress.totalDailyChallengesCompleted}',
          color: AppPalette.primary,
          background: AppPalette.primarySoft,
        ),
        if (shieldUsedToday) ...[
          SizedBox(height: responsive.itemGap),
          Container(
            width: double.infinity,
            padding: responsive.symmetricInsets(
              horizontalFraction: 0.034,
              verticalFraction: 0.026,
            ),
            decoration: BoxDecoration(
              color: AppPalette.tealSoft,
              borderRadius: BorderRadius.circular(responsive.mediumRadius),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppPalette.teal),
                SizedBox(width: responsive.compactGap),
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
    final responsive = context.responsive;
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: responsive.symmetricInsets(
          horizontalFraction: 0.034,
          verticalFraction: 0.03,
        ),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(responsive.mediumRadius),
          border: Border.all(color: AppPalette.outline),
        ),
        child: Row(
          children: [
            AppIconBadge(
              icon: icon,
              foreground: color,
              background: background,
              size: responsive.iconBadgeSize,
              iconSize: responsive.iconSize,
              radius: responsive.mediumRadius,
            ),
            SizedBox(width: responsive.itemGap),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SizedBox(width: responsive.itemGap),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
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
    final responsive = context.responsive;
    return Card(
      child: SizedBox(
        height: responsive.heightValue(0.22, minimum: 210, maximum: 330),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPadding),
        child: const Text('No fue posible leer el progreso local.'),
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
    final responsive = context.responsive;
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
        borderRadius: BorderRadius.circular(responsive.largeRadius),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -responsive.value(0.06, minimum: 24, maximum: 48),
            top: -responsive.value(0.055, minimum: 22, maximum: 42),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: responsive.widthValue(0.29, minimum: 130, maximum: 210),
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIconBadge(
                      icon: Icons.bolt_rounded,
                      foreground: AppPalette.primaryDark,
                      background: Colors.white,
                    ),
                    SizedBox(width: responsive.itemGap),
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
                SizedBox(height: responsive.itemGap),
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
                SizedBox(height: responsive.compactGap * 0.75),
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
                  SizedBox(height: responsive.itemGap),
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
                  SizedBox(height: responsive.compactGap),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: responsive.progressThickness,
                    color: const Color(0xFF8CF0D5),
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ],
                SizedBox(height: responsive.itemGap * 1.2),
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
    final responsive = context.responsive;
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
        SizedBox(height: responsive.itemGap),
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
    final responsive = context.responsive;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: actionKey,
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(responsive.cardPadding),
          child: Row(
            children: [
              AppIconBadge(
                icon: icon,
                foreground: accent,
                background: accentSoft,
                size: responsive.iconBadgeSize * 1.16,
                iconSize: responsive.iconSize * 1.14,
                radius: responsive.mediumRadius,
              ),
              SizedBox(width: responsive.itemGap),
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
                    SizedBox(height: responsive.compactGap * 0.5),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: responsive.compactGap * 0.6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.compactGap),
              Container(
                width: responsive.iconBadgeSize * 0.9,
                height: responsive.iconBadgeSize * 0.9,
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
