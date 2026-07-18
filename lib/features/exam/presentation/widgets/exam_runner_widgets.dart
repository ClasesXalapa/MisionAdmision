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

    return Stack(
      children: [
        ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            isLast && !allAnswered ? 150 : 126,
          ),
          children: [
            if (banner != null) ...[
              banner!,
              const SizedBox(height: 14),
            ],
            _ProgressHeader(
              currentIndex: currentIndex,
              total: exam.questions.length,
              answered: answers.length,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(compact ? 18 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuestionMetadata(question: question),
                    const SizedBox(height: 16),
                    Text(
                      question.statement,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.34,
                              ),
                    ),
                    if (question.imageUrl != null) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          question.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const _ImageError();
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    for (final option in AnswerOption.values) ...[
                      _AnswerTile(
                        option: option,
                        text: question.optionText(option),
                        selected: selected == option,
                        onTap: () => onAnswer(option),
                      ),
                      if (option != AnswerOption.d)
                        const SizedBox(height: 11),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _QuestionActionBar(
            isFirst: isFirst,
            isLast: isLast,
            allAnswered: allAnswered,
            onPrevious: onPrevious,
            onNext: onNext,
            onFinish: onFinish,
          ),
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.currentIndex,
    required this.total,
    required this.answered,
  });

  final int currentIndex;
  final int total;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pregunta ${currentIndex + 1} de $total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '$answered respondidas',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (currentIndex + 1) / total,
          minHeight: 10,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: colors.primaryContainer.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _QuestionActionBar extends StatelessWidget {
  const _QuestionActionBar({
    required this.isFirst,
    required this.isLast,
    required this.allAnswered,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  final bool isFirst;
  final bool isLast;
  final bool allAnswered;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 390;
                  final previousButton = narrow
                      ? OutlinedButton(
                          onPressed: isFirst ? null : onPrevious,
                          child: const Text('Anterior'),
                        )
                      : OutlinedButton.icon(
                          onPressed: isFirst ? null : onPrevious,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Anterior'),
                        );
                  final nextButton = isLast
                      ? FilledButton.icon(
                          onPressed: allAnswered ? onFinish : null,
                          icon: const Icon(Icons.flag_rounded),
                          label: const Text('Finalizar'),
                        )
                      : FilledButton.icon(
                          onPressed: onNext,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Siguiente'),
                        );

                  return Row(
                    children: [
                      Expanded(flex: 4, child: previousButton),
                      const SizedBox(width: 11),
                      Expanded(flex: 6, child: nextButton),
                    ],
                  );
                },
              ),
              if (isLast && !allAnswered) ...[
                const SizedBox(height: 8),
                Text(
                  'Responde todas las preguntas para finalizar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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
    final percent = result.total == 0
        ? 0
        : ((result.correct / result.total) * 100).round();
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final width = (constraints.maxWidth - spacing * 2) / 3;
                        return Row(
                          children: [
                            SizedBox(
                              width: width,
                              child: _ResultMetric(
                                label: 'Total',
                                value: result.total,
                                icon: Icons.format_list_numbered_rounded,
                                background: colors.surfaceContainerHighest,
                                foreground: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: spacing),
                            SizedBox(
                              width: width,
                              child: _ResultMetric(
                                label: 'Correctas',
                                value: result.correct,
                                icon: Icons.check_circle_rounded,
                                background: const Color(0xFFE4F5E8),
                                foreground: const Color(0xFF18733C),
                              ),
                            ),
                            const SizedBox(width: spacing),
                            SizedBox(
                              width: width,
                              child: _ResultMetric(
                                label: 'Incorrectas',
                                value: result.incorrect,
                                icon: Icons.cancel_rounded,
                                background: const Color(0xFFFFE8E5),
                                foreground: const Color(0xFFA72D20),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (extraContent != null) ...[
                      const SizedBox(height: 20),
                      extraContent!,
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onPrimary,
                        child: Text(primaryLabel),
                      ),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 8),
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
        Chip(label: Text(_readableLabel(question.category))),
        Chip(label: Text(_readableLabel(question.difficulty.jsonValue))),
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
    return Semantics(
      button: true,
      selected: selected,
      label: 'Opción ${option.label}: $text',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.72)
              : colors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? colors.primary : const Color(0xFFD5DBE8),
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 66),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor:
                          selected ? colors.primary : colors.surfaceContainerHighest,
                      foregroundColor:
                          selected ? colors.onPrimary : colors.onSurface,
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
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 28,
                        color: colors.primary,
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

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: foreground, size: 25),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
        ],
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

String _readableLabel(String value) {
  if (value.isEmpty) return value;
  final text = value.replaceAll('-', ' ').replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
