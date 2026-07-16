import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver al inicio',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(state.exam?.title ?? 'Reto diario'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: switch (state.phase) {
              DailyChallengePhase.loading => const ExamLoadingView(
                  message: 'Preparando el reto de hoy...',
                ),
              DailyChallengePhase.failure => ExamErrorView(
                  message: state.errorMessage ?? 'Ocurrió un error inesperado.',
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
        ? 'Continuaste el intento guardado en este dispositivo.'
        : automatic
            ? 'Hoy no hay un reto programado: preparamos 10 preguntas estables para ti.'
            : 'Reto programado para hoy. Completarlo cuenta para tu racha.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              wasResumed ? Icons.restore : Icons.local_fire_department_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Racha actual: $currentStreak días · Mejor racha: $bestStreak días',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      shieldEarned
                          ? 'Nuevo escudo obtenido · Total: $shields de 3'
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
              icon: const Icon(Icons.open_in_new),
              label: Text(resource!.title),
            ),
          ),
        ],
      ],
    );
  }
}
