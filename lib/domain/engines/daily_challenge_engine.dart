import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/question.dart';

class DailyChallengeEngine {
  const DailyChallengeEngine({this.questionCount = 10});

  final int questionCount;

  DailyChallenge resolveChallenge({
    required String dateKey,
    required List<DailyChallenge> scheduledChallenges,
    required List<Question> questionBank,
  }) {
    for (final challenge in scheduledChallenges) {
      if (challenge.dateKey == dateKey) {
        _validateQuestionIds(challenge.questionIds, questionBank);
        return challenge;
      }
    }

    final exam = const ExamEngine().createRandomExam(
      questionBank: questionBank,
      questionCount: questionCount,
      seed: _stableSeed(dateKey),
    );

    return DailyChallenge(
      id: 'auto_reto_${dateKey.replaceAll('-', '_')}',
      dateKey: dateKey,
      title: 'Reto automático del día',
      questionIds: exam.questions.map((question) => question.id).toList(),
      kind: ExamKind.dailyAutomatic,
    );
  }

  Exam buildExam({
    required DailyChallenge challenge,
    required List<Question> questionBank,
  }) {
    final byId = {for (final question in questionBank) question.id: question};
    final questions = <Question>[];

    for (final id in challenge.questionIds) {
      final question = byId[id];
      if (question == null) {
        throw StateError(
          'El reto ${challenge.id} referencia la pregunta inexistente $id.',
        );
      }
      questions.add(question);
    }

    return Exam(
      id: challenge.id,
      questions: questions,
      kind: challenge.kind,
      title: challenge.title,
      dateKey: challenge.dateKey,
      resolutionResource: challenge.resolutionResource,
    );
  }

  DailyChallenge restoreChallenge({
    required String challengeId,
    required String dateKey,
    required String title,
    required ExamKind kind,
    required List<String> questionIds,
    required List<DailyChallenge> scheduledChallenges,
  }) {
    for (final challenge in scheduledChallenges) {
      if (challenge.id == challengeId) {
        return DailyChallenge(
          id: challengeId,
          dateKey: dateKey,
          title: title,
          questionIds: questionIds,
          kind: kind,
          resolutionResource: challenge.resolutionResource,
        );
      }
    }

    return DailyChallenge(
      id: challengeId,
      dateKey: dateKey,
      title: title,
      questionIds: questionIds,
      kind: kind,
    );
  }

  void _validateQuestionIds(
    List<String> questionIds,
    List<Question> questionBank,
  ) {
    if (questionIds.isEmpty) {
      throw const FormatException('El reto programado no contiene preguntas.');
    }
    if (questionIds.toSet().length != questionIds.length) {
      throw const FormatException('El reto programado repite preguntas.');
    }

    final availableIds = questionBank.map((question) => question.id).toSet();
    final missing = questionIds.where((id) => !availableIds.contains(id));
    if (missing.isNotEmpty) {
      throw FormatException(
        'El reto programado contiene IDs inexistentes: ${missing.join(', ')}.',
      );
    }
  }

  int _stableSeed(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
