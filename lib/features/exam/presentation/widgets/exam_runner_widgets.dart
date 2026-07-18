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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  'No pudimos abrir esta actividad',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 30),
                    label: const Text(
                      'Intentar de nuevo',
                      style: TextStyle(fontSize: 20),
                    ),
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

    return Stack(
      children: [
        ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            isLast && !allAnswered ? 184 : 154,
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
            _QuestionCard(question: question),
            const SizedBox(height: 18),
            Text(
              'Elige una respuesta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            for (final option in AnswerOption.values) ...[
              _AnswerTile(
                option: option,
                text: question.optionText(option),
                imageUrl: question.optionImageUrl(option),
                selected: selected == option,
                onTap: () => onAnswer(option),
              ),
              if (option != AnswerOption.d) const SizedBox(height: 14),
            ],
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuestionMetadata(question: question),
            const SizedBox(height: 20),
            Text(
              question.statement,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.28,
                  ),
            ),
            if (question.imageUrl != null) ...[
              const SizedBox(height: 22),
              _QuestionImage(
                url: question.imageUrl!,
                semanticsLabel: 'Imagen de la pregunta',
                maxHeight: 380,
              ),
            ],
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${currentIndex + 1} de $total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$answered respondidas',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontSize: 16,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (currentIndex + 1) / total,
            minHeight: 13,
            borderRadius: BorderRadius.circular(13),
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.55),
          ),
        ],
      ),
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
      elevation: 16,
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 430;
                  final previousButton = narrow
                      ? OutlinedButton(
                          onPressed: isFirst ? null : onPrevious,
                          child: const Text(
                            'Atrás',
                            style: TextStyle(fontSize: 19),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: isFirst ? null : onPrevious,
                          icon: const Icon(Icons.arrow_back_rounded, size: 28),
                          label: const Text(
                            'Anterior',
                            style: TextStyle(fontSize: 19),
                          ),
                        );
                  final nextButton = isLast
                      ? FilledButton.icon(
                          onPressed: allAnswered ? onFinish : null,
                          icon: const Icon(Icons.flag_rounded, size: 29),
                          label: const Text(
                            'Finalizar',
                            style: TextStyle(fontSize: 19),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: onNext,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 29,
                          ),
                          label: const Text(
                            'Siguiente',
                            style: TextStyle(fontSize: 19),
                          ),
                        );

                  return Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: SizedBox(height: 74, child: previousButton),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: SizedBox(height: 74, child: nextButton),
                      ),
                    ],
                  );
                },
              ),
              if (isLast && !allAnswered) ...[
                const SizedBox(height: 10),
                Text(
                  'Responde todas las preguntas para finalizar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SizedBox(
            width: double.infinity,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 26),
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
                      const SizedBox(height: 22),
                      extraContent!,
                    ],
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: FilledButton(
                        onPressed: onPrimary,
                        child: Text(
                          primaryLabel,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    if (secondaryLabel != null && onSecondary != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 68,
                        child: TextButton(
                          onPressed: onSecondary,
                          child: Text(
                            secondaryLabel!,
                            style: const TextStyle(fontSize: 19),
                          ),
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
      spacing: 9,
      runSpacing: 9,
      children: [
        Chip(
          avatar: const Icon(Icons.school_outlined, size: 21),
          label: Text(_readableLabel(question.category)),
        ),
        Chip(
          avatar: const Icon(Icons.signal_cellular_alt_rounded, size: 21),
          label: Text(_readableLabel(question.difficulty.jsonValue)),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.option,
    required this.text,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final AnswerOption option;
  final String text;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasText = text.trim().isNotEmpty;
    final semanticsContent = hasText ? text : 'inciso con imagen';

    return Semantics(
      button: true,
      selected: selected,
      label: 'Opción ${option.label}: $semanticsContent',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.78)
              : colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.primary : const Color(0xFFD9DEE9),
            width: selected ? 3 : 1.4,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 108),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 29,
                          backgroundColor: selected
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          foregroundColor: selected
                              ? colors.onPrimary
                              : colors.onSurface,
                          child: Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            hasText ? text : 'Opción ${option.label}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: selected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  height: 1.34,
                                ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 34,
                            color: colors.primary,
                          ),
                        ],
                      ],
                    ),
                    if (imageUrl != null) ...[
                      const SizedBox(height: 16),
                      _QuestionImage(
                        url: imageUrl!,
                        semanticsLabel: 'Imagen de la opción ${option.label}',
                        maxHeight: 300,
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

class _QuestionImage extends StatelessWidget {
  const _QuestionImage({
    required this.url,
    required this.semanticsLabel,
    required this.maxHeight,
  });

  final String url;
  final String semanticsLabel;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: Material(
        color: const Color(0xFFF2F4F9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showImageViewer(context, url, semanticsLabel),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 180,
                    maxHeight: maxHeight,
                  ),
                  child: Image.network(
                    url,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes == null
                              ? null
                              : loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!,
                        ),
                      ),
                    );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const _ImageError(height: 220);
                    },
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 28,
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

Future<void> _showImageViewer(
  BuildContext context,
  String url,
  String label,
) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(dialogContext).height * 0.82,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Semantics(
                      image: true,
                      label: label,
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const _ImageError(
                            height: 260,
                            dark: true,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filled(
                  tooltip: 'Cerrar imagen',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: foreground, size: 30),
          const SizedBox(height: 7),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({
    this.height = 190,
    this.dark = false,
  });

  final double height;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      color: dark ? Colors.black : Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(24),
      child: Text(
        'No fue posible cargar la imagen.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: dark ? Colors.white : null,
            ),
      ),
    );
  }
}

String _readableLabel(String value) {
  if (value.isEmpty) return value;
  final text = value.replaceAll('-', ' ').replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
