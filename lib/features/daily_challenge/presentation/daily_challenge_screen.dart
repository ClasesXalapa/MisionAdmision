import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/design_system.dart';
import 'package:mision_admision/app/responsive.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/resolution_resource.dart';
import 'package:mision_admision/features/daily_challenge/application/daily_challenge_controller.dart';
import 'package:mision_admision/features/daily_challenge/application/daily_challenge_state.dart';
import 'package:mision_admision/features/exam/presentation/widgets/exam_runner_widgets.dart';
import 'package:mision_admision/features/progress/application/progress_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  late final DailyChallengeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DailyChallengeController(
      questionRepository: ref.read(questionRepositoryProvider),
      challengeRepository: ref.read(challengeRepositoryProvider),
      attemptRepository: ref.read(dailyAttemptRepositoryProvider),
      progressRepository: ref.read(progressRepositoryProvider),
      challengeEngine: ref.read(dailyChallengeEngineProvider),
      examEngine: ref.read(examEngineProvider),
      streakEngine: ref.read(streakEngineProvider),
      clock: ref.read(appClockProvider),
    )..addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finish() async {
    await _controller.finish();
    ref
      ..invalidate(learnerProgressProvider)
      ..invalidate(pendingDailyAttemptProvider);
  }

  Future<void> _requestExit() async {
    final state = _controller.state;
    if (state.phase != DailyChallengePhase.ready) {
      if (mounted) context.go('/');
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del reto?'),
        content: const Text(
          'Tu progreso está guardado en este dispositivo y podrás continuar hoy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir respondiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir por ahora'),
          ),
        ],
      ),
    );

    if (leave == true && mounted) context.go('/');
  }

  Future<void> _openResolution(ResolutionResource resource) async {
    final opened = await launchUrl(
      resource.url,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el recurso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return PopScope<void>(
      canPop: state.phase != DailyChallengePhase.ready,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && state.phase == DailyChallengePhase.ready) {
          await _requestExit();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68,
          leadingWidth: 60,
          leading: IconButton(
            tooltip: 'Volver al inicio',
            onPressed: _requestExit,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Reto de hoy'),
        ),
        body: SafeArea(
          child: fullWidthCentered(
            maxWidth: 820,
            child: switch (state.phase) {
                DailyChallengePhase.loading => const ExamLoadingView(
                    message: 'Preparando el reto de hoy...',
                  ),
                DailyChallengePhase.failure => ExamErrorView(
                    message:
                        state.errorMessage ?? 'Ocurrió un error inesperado.',
                    onRetry: _controller.start,
                  ),
                DailyChallengePhase.ready => ExamQuestionView(
                    exam: state.exam!,
                    currentIndex: state.currentIndex,
                    answers: state.answers,
                    onAnswer: _controller.selectAnswer,
                    onPrevious: _controller.previous,
                    onNext: _controller.next,
                    onFinish: _finish,
                    banner: _ChallengeBanner(
                      kind: state.exam!.kind,
                      wasResumed: state.wasResumed,
                    ),
                  ),
                DailyChallengePhase.finished => ExamResultView(
                    result: state.result!,
                    title: 'Reto completado',
                    message: _resultMessage(state),
                    primaryLabel: 'Volver al inicio',
                    onPrimary: () => context.go('/'),
                    secondaryLabel: 'Repetir reto',
                    onSecondary: _controller.start,
                    extraContent: _DailyResultExtra(
                      currentStreak: state.progress.currentStreak,
                      bestStreak: state.progress.bestStreak,
                      shields: state.progress.shields,
                      shieldEarned: state.shieldEarned,
                      resource: state.exam!.resolutionResource,
                      onOpenResource: _openResolution,
                    ),
                  ),
            },
          ),
        ),
      ),
    );
  }

  String _resultMessage(DailyChallengeState state) {
    if (!state.streakCounted) {
      return 'Este reto ya había contado para la racha de hoy.';
    }
    if (state.shieldEarned) {
      return 'Tu racha ahora es de ${state.progress.currentStreak} días y ganaste un escudo.';
    }
    return 'Tu racha ahora es de ${state.progress.currentStreak} días.';
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner({
    required this.kind,
    required this.wasResumed,
  });

  final ExamKind kind;
  final bool wasResumed;

  @override
  Widget build(BuildContext context) {
    final automatic = kind == ExamKind.dailyAutomatic;
    final text = wasResumed
        ? 'Retomaste tu avance. Todo quedó guardado.'
        : automatic
            ? 'Preparamos 10 preguntas para tu práctica diaria.'
            : 'Completa las preguntas para proteger tu racha.';

    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.challengeGradient,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          AppIconBadge(
            icon: wasResumed
                ? Icons.restore_rounded
                : Icons.local_fire_department_rounded,
            foreground: AppPalette.primaryDark,
            background: Colors.white,
            size: 44,
            iconSize: 24,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyResultExtra extends StatelessWidget {
  const _DailyResultExtra({
    required this.currentStreak,
    required this.bestStreak,
    required this.shields,
    required this.shieldEarned,
    required this.resource,
    required this.onOpenResource,
  });

  final int currentStreak;
  final int bestStreak;
  final int shields;
  final bool shieldEarned;
  final ResolutionResource? resource;
  final ValueChanged<ResolutionResource> onOpenResource;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Racha actual: $currentStreak días · Mejor: $bestStreak días',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.shield_rounded),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      shieldEarned
                          ? 'Ganaste un escudo · Total: $shields de 3'
                          : 'Escudos disponibles: $shields de 3',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (resource != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onOpenResource(resource!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(resource!.title),
            ),
          ),
        ],
      ],
    );
  }
}
