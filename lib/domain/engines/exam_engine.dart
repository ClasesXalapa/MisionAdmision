import 'dart:math';

import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/exam_result.dart';
import 'package:mision_admision/domain/models/question.dart';

class ExamEngine {
  const ExamEngine();

  Exam createRandomExam({
    required List<Question> questionBank,
    int questionCount = 10,
    int? seed,
  }) {
    if (questionCount <= 0) {
      throw ArgumentError.value(
        questionCount,
        'questionCount',
        'Debe ser mayor que cero.',
      );
    }

    if (questionBank.length < questionCount) {
      throw StateError(
        'El banco contiene ${questionBank.length} preguntas, '
        'pero se solicitaron $questionCount.',
      );
    }

    final shuffled = List<Question>.of(questionBank);
    shuffled.shuffle(Random(seed));
    final selected = shuffled.take(questionCount).toList(growable: false);

    return Exam(
      id: 'free_random_${DateTime.now().millisecondsSinceEpoch}',
      questions: selected,
      kind: ExamKind.freeRandom,
      title: 'Examen libre',
    );
  }

  ExamResult evaluate({
    required Exam exam,
    required Map<String, AnswerOption> answers,
  }) {
    var correct = 0;
    var unanswered = 0;
    final incorrectQuestionIds = <String>[];

    for (final question in exam.questions) {
      final selected = answers[question.id];
      if (selected == null) {
        unanswered += 1;
        incorrectQuestionIds.add(question.id);
      } else if (selected == question.correctAnswer) {
        correct += 1;
      } else {
        incorrectQuestionIds.add(question.id);
      }
    }

    return ExamResult(
      total: exam.questions.length,
      correct: correct,
      incorrect: exam.questions.length - correct,
      unanswered: unanswered,
      incorrectQuestionIds: incorrectQuestionIds,
    );
  }
}
