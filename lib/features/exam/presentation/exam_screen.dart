import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/features/exam/application/exam_controller.dart';
import 'package:mision_admision/features/exam/application/exam_state.dart';
import 'package:mision_admision/features/exam/presentation/widgets/exam_runner_widgets.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  late final ExamController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExamController(
      repository: ref.read(questionRepositoryProvider),
      engine: ref.read(examEngineProvider),
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
        title: const Text('Examen libre'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: switch (state.phase) {
              ExamPhase.loading => const ExamLoadingView(),
              ExamPhase.failure => ExamErrorView(
                  message: state.errorMessage ?? 'Ocurrió un error inesperado.',
                  onRetry: _controller.start,
                ),
              ExamPhase.ready => ExamQuestionView(
                  exam: state.exam!,
                  currentIndex: state.currentIndex,
                  answers: state.answers,
                  onAnswer: _controller.selectAnswer,
                  onPrevious: _controller.previous,
                  onNext: _controller.next,
                  onFinish: _controller.finish,
                ),
              ExamPhase.finished => ExamResultView(
                  result: state.result!,
                  primaryLabel: 'Nuevo examen',
                  onPrimary: _controller.start,
                  secondaryLabel: 'Volver al inicio',
                  onSecondary: () => context.go('/'),
                ),
            },
          ),
        ),
      ),
    );
  }
}
