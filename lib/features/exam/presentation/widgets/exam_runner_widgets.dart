import 'package:flutter/material.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/exam_result.dart';
import 'package:mision_admision/domain/models/question.dart';

class ExamLoadingView extends StatelessWidget {
  const ExamLoadingView({
    this.message = 'Preparando tu examen...',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class ExamErrorView extends StatelessWidget {
  const ExamErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 54,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos abrir esta actividad',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar de nuevo'),
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

class ExamQuestionView extends StatelessWidget {
  const ExamQuestionView({
    required this.exam,
    required this.currentIndex,
    required this.answers,
    required this.onAnswer,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    this.banner,
    super.key,
  });

  final Exam exam;
  final int currentIndex;
  final Map<String, AnswerOption> answers;
  final ValueChanged<AnswerOption> onAnswer;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final question = exam.questions[currentIndex];
    final selected = answers[question.id];
    final isFirst = currentIndex == 0;
    final isLast = currentIndex == exam.questions.length - 1;
    final allAnswered = answers.length == exam.questions.length;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final horizontalPadding = compact ? 16.0 : 24.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        30,
      ),
      children: [
        if (banner != null) ...[
          banner!,
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / exam.questions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${currentIndex + 1}/${exam.questions.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? 20 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuestionMetadata(question: question),
                const SizedBox(height: 18),
                Text(
                  question.statement,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                ),
                if (question.imageUrl != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      question.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const _ImageError();
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                for (final option in AnswerOption.values) ...[
                  _AnswerTile(
                    option: option,
                    text: question.optionText(option),
                    selected: selected == option,
                    onTap: () => onAnswer(option),
                  ),
                  if (option != AnswerOption.d) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 360;
            final previous = OutlinedButton.icon(
              onPressed: isFirst ? null : onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anterior'),
            );
            final next = isLast
                ? FilledButton.icon(
                    onPressed: allAnswered ? onFinish : null,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Finalizar'),
                  )
                : FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  );

            if (stacked) {
              return Column(
                children: [
                  SizedBox(width: double.infinity, child: next),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: previous),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: previous),
                const SizedBox(width: 12),
                Expanded(child: next),
              ],
            );
          },
        ),
        if (isLast && !allAnswered) ...[
          const SizedBox(height: 14),
          Text(
            'Responde todas las preguntas para finalizar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class ExamResultView extends StatelessWidget {
  const ExamResultView({
    required this.result,
    required this.primaryLabel,
    required this.onPrimary,
    this.title = 'Resultado',
    this.message,
    this.secondaryLabel,
    this.onSecondary,
    this.extraContent,
    super.key,
  });

  final ExamResult result;
  final String title;
  final String? message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _ResultRow(label: 'Preguntas totales', value: result.total),
                    _ResultRow(label: 'Correctas', value: result.correct),
                    _ResultRow(label: 'Incorrectas', value: result.incorrect),
                    if (extraContent != null) ...[
                      const SizedBox(height: 20),
                      extraContent!,
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onPrimary,
                        child: Text(primaryLabel),
                      ),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionMetadata extends StatelessWidget {
  const _QuestionMetadata({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text(question.category)),
        Chip(label: Text(question.difficulty.jsonValue)),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.option,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final AnswerOption option;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: selected ? colors.primary : colors.surface,
                foregroundColor: selected ? colors.onPrimary : colors.onSurface,
                child: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.check_circle,
                    size: 27,
                    color: colors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: const Text('No fue posible cargar la imagen.'),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
