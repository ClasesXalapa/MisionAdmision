import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';

class DailyAttemptDto {
  DailyAttemptDto({
    required this.challengeId,
    required this.dateKey,
    required this.title,
    required this.kind,
    required List<String> questionIds,
    required Map<String, String> answers,
    required this.currentIndex,
    required this.startedAt,
  })  : questionIds = List.unmodifiable(questionIds),
        answers = Map.unmodifiable(answers);

  factory DailyAttemptDto.fromDomain(DailyAttempt attempt) {
    return DailyAttemptDto(
      challengeId: attempt.challengeId,
      dateKey: attempt.dateKey,
      title: attempt.title,
      kind: attempt.kind.storageValue,
      questionIds: attempt.questionIds,
      answers: {
        for (final entry in attempt.answers.entries)
          entry.key: entry.value.label,
      },
      currentIndex: attempt.currentIndex,
      startedAt: attempt.startedAt.toIso8601String(),
    );
  }

  factory DailyAttemptDto.fromJson(Map<String, dynamic> json) {
    final rawQuestionIds = json['question_ids'];
    final rawAnswers = json['answers'];

    return DailyAttemptDto(
      challengeId: json['challenge_id'] as String? ?? '',
      dateKey: json['date_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      questionIds: rawQuestionIds is List
          ? rawQuestionIds.whereType<String>().toList(growable: false)
          : const [],
      answers: rawAnswers is Map<String, dynamic>
          ? rawAnswers.map(
              (key, value) => MapEntry(key, value.toString()),
            )
          : const {},
      currentIndex: json['current_index'] as int? ?? 0,
      startedAt: json['started_at'] as String? ?? '',
    );
  }

  final String challengeId;
  final String dateKey;
  final String title;
  final String kind;
  final List<String> questionIds;
  final Map<String, String> answers;
  final int currentIndex;
  final String startedAt;

  Map<String, dynamic> toJson() {
    return {
      'challenge_id': challengeId,
      'date_key': dateKey,
      'title': title,
      'kind': kind,
      'question_ids': questionIds,
      'answers': answers,
      'current_index': currentIndex,
      'started_at': startedAt,
    };
  }

  DailyAttempt toDomain() {
    if (challengeId.trim().isEmpty ||
        dateKey.trim().isEmpty ||
        title.trim().isEmpty ||
        questionIds.isEmpty) {
      throw const FormatException('El intento diario guardado está incompleto.');
    }

    parseLocalDateKey(dateKey);
    if (questionIds.toSet().length != questionIds.length) {
      throw const FormatException('El intento diario repite preguntas.');
    }

    final parsedStartedAt = DateTime.tryParse(startedAt);
    if (parsedStartedAt == null) {
      throw const FormatException('La fecha de inicio guardada es inválida.');
    }

    final parsedAnswers = <String, AnswerOption>{};
    for (final entry in answers.entries) {
      final option = AnswerOption.tryParse(entry.value);
      if (option == null) {
        throw FormatException(
          'La respuesta guardada ${entry.value} no es válida.',
        );
      }
      if (!questionIds.contains(entry.key)) {
        throw FormatException(
          'La respuesta guardada referencia una pregunta inexistente: ${entry.key}.',
        );
      }
      parsedAnswers[entry.key] = option;
    }

    final safeIndex = currentIndex.clamp(0, questionIds.length - 1).toInt();
    return DailyAttempt(
      challengeId: challengeId,
      dateKey: dateKey,
      title: title,
      kind: ExamKind.parse(kind),
      questionIds: questionIds,
      answers: parsedAnswers,
      currentIndex: safeIndex,
      startedAt: parsedStartedAt,
    );
  }
}
