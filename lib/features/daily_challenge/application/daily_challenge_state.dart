import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/exam_result.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/question.dart';

class DailyChallengeState {
  DailyChallengeState({
    required this.phase,
    this.exam,
    this.currentIndex = 0,
    Map<String, AnswerOption> answers = const {},
    this.result,
    this.progress = const LearnerProgress(),
    this.wasResumed = false,
    this.streakCounted = false,
    this.shieldEarned = false,
    this.errorMessage,
  }) : answers = Map.unmodifiable(answers);

  factory DailyChallengeState.loading() {
    return DailyChallengeState(phase: DailyChallengePhase.loading);
  }

  factory DailyChallengeState.ready({
    required Exam exam,
    required LearnerProgress progress,
    int currentIndex = 0,
    Map<String, AnswerOption> answers = const {},
    bool wasResumed = false,
  }) {
    return DailyChallengeState(
      phase: DailyChallengePhase.ready,
      exam: exam,
      currentIndex: currentIndex,
      answers: answers,
      progress: progress,
      wasResumed: wasResumed,
    );
  }

  factory DailyChallengeState.finished({
    required Exam exam,
    required Map<String, AnswerOption> answers,
    required ExamResult result,
    required LearnerProgress progress,
    required bool streakCounted,
    required bool shieldEarned,
  }) {
    return DailyChallengeState(
      phase: DailyChallengePhase.finished,
      exam: exam,
      answers: answers,
      result: result,
      progress: progress,
      streakCounted: streakCounted,
      shieldEarned: shieldEarned,
    );
  }

  factory DailyChallengeState.failure(String message) {
    return DailyChallengeState(
      phase: DailyChallengePhase.failure,
      errorMessage: message,
    );
  }

  final DailyChallengePhase phase;
  final Exam? exam;
  final int currentIndex;
  final Map<String, AnswerOption> answers;
  final ExamResult? result;
  final LearnerProgress progress;
  final bool wasResumed;
  final bool streakCounted;
  final bool shieldEarned;
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

enum DailyChallengePhase { loading, ready, finished, failure }
