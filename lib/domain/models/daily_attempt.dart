import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';

class DailyAttempt {
  DailyAttempt({
    required this.challengeId,
    required this.dateKey,
    required this.title,
    required this.kind,
    required List<String> questionIds,
    required Map<String, AnswerOption> answers,
    required this.currentIndex,
    required this.startedAt,
  })  : questionIds = List.unmodifiable(questionIds),
        answers = Map.unmodifiable(answers);

  final String challengeId;
  final String dateKey;
  final String title;
  final ExamKind kind;
  final List<String> questionIds;
  final Map<String, AnswerOption> answers;
  final int currentIndex;
  final DateTime startedAt;

  DailyAttempt copyWith({
    Map<String, AnswerOption>? answers,
    int? currentIndex,
  }) {
    return DailyAttempt(
      challengeId: challengeId,
      dateKey: dateKey,
      title: title,
      kind: kind,
      questionIds: questionIds,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: startedAt,
    );
  }
}
