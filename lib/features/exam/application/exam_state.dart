import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/exam_result.dart';
import 'package:mision_admision/domain/models/question.dart';

enum ExamPhase { loading, ready, finished, failure }

class ExamState {
  ExamState({
    required this.phase,
    this.exam,
    this.currentIndex = 0,
    Map<String, AnswerOption> answers = const {},
    this.result,
    this.errorMessage,
  }) : answers = Map.unmodifiable(answers);

  factory ExamState.loading() => ExamState(phase: ExamPhase.loading);

  factory ExamState.ready({
    required Exam exam,
    int currentIndex = 0,
    Map<String, AnswerOption> answers = const {},
  }) {
    return ExamState(
      phase: ExamPhase.ready,
      exam: exam,
      currentIndex: currentIndex,
      answers: answers,
    );
  }

  factory ExamState.finished({
    required Exam exam,
    required Map<String, AnswerOption> answers,
    required ExamResult result,
  }) {
    return ExamState(
      phase: ExamPhase.finished,
      exam: exam,
      answers: answers,
      result: result,
    );
  }

  factory ExamState.failure(String message) {
    return ExamState(phase: ExamPhase.failure, errorMessage: message);
  }

  final ExamPhase phase;
  final Exam? exam;
  final int currentIndex;
  final Map<String, AnswerOption> answers;
  final ExamResult? result;
  final String? errorMessage;

  Question? get currentQuestion {
    final currentExam = exam;
    if (currentExam == null || currentExam.questions.isEmpty) {
      return null;
    }
    return currentExam.questions[currentIndex];
  }

  bool get allAnswered {
    final currentExam = exam;
    return currentExam != null && answers.length == currentExam.questions.length;
  }
}
