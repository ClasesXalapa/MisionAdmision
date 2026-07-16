import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/domain/engines/daily_challenge_engine.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/question_difficulty.dart';

void main() {
  const engine = DailyChallengeEngine();
  final bank = List.generate(20, _question);

  test('prioriza el reto programado para la fecha', () {
    final scheduled = DailyChallenge(
      id: 'scheduled',
      dateKey: '2026-07-15',
      title: 'Programado',
      questionIds: bank.take(5).map((question) => question.id).toList(),
      kind: ExamKind.dailyScheduled,
    );

    final result = engine.resolveChallenge(
      dateKey: '2026-07-15',
      scheduledChallenges: [scheduled],
      questionBank: bank,
    );

    expect(result.id, 'scheduled');
    expect(result.kind, ExamKind.dailyScheduled);
  });

  test('genera el mismo reto automático para la misma fecha', () {
    final first = engine.resolveChallenge(
      dateKey: '2026-07-16',
      scheduledChallenges: const [],
      questionBank: bank,
    );
    final second = engine.resolveChallenge(
      dateKey: '2026-07-16',
      scheduledChallenges: const [],
      questionBank: bank,
    );

    expect(first.questionIds, second.questionIds);
    expect(first.questionIds, hasLength(10));
    expect(first.kind, ExamKind.dailyAutomatic);
  });

  test('cambia la selección automática para otra fecha', () {
    final first = engine.resolveChallenge(
      dateKey: '2026-07-16',
      scheduledChallenges: const [],
      questionBank: bank,
    );
    final second = engine.resolveChallenge(
      dateKey: '2026-07-17',
      scheduledChallenges: const [],
      questionBank: bank,
    );

    expect(first.questionIds, isNot(equals(second.questionIds)));
  });

  test('rechaza IDs inexistentes en un reto programado', () {
    final scheduled = DailyChallenge(
      id: 'bad',
      dateKey: '2026-07-15',
      title: 'Inválido',
      questionIds: const ['NO-EXISTE'],
      kind: ExamKind.dailyScheduled,
    );

    expect(
      () => engine.resolveChallenge(
        dateKey: '2026-07-15',
        scheduledChallenges: [scheduled],
        questionBank: bank,
      ),
      throwsFormatException,
    );
  });
}

Question _question(int index) {
  return Question(
    id: 'Q-$index',
    statement: 'Pregunta $index',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: AnswerOption.a,
    category: 'matematicas',
    tags: const ['prueba'],
    difficulty: QuestionDifficulty.basic,
  );
}
