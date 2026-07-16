import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/domain/engines/daily_challenge_engine.dart';
import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/engines/streak_engine.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/question_difficulty.dart';
import 'package:mision_admision/domain/repositories/challenge_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';
import 'package:mision_admision/features/daily_challenge/application/daily_challenge_controller.dart';
import 'package:mision_admision/features/daily_challenge/application/daily_challenge_state.dart';

void main() {
  test('restaura respuestas e índice del intento del mismo día', () async {
    final clock = MutableClock(DateTime(2026, 7, 15, 10));
    final attemptRepository = MemoryAttemptRepository();
    final progressRepository = MemoryProgressRepository();

    final first = _createController(
      clock: clock,
      attemptRepository: attemptRepository,
      progressRepository: progressRepository,
    );
    await first.start();
    first.selectAnswer(AnswerOption.b);
    first.next();
    await Future<void>.delayed(Duration.zero);

    final second = _createController(
      clock: clock,
      attemptRepository: attemptRepository,
      progressRepository: progressRepository,
    );
    await second.start();

    expect(second.state.phase, DailyChallengePhase.ready);
    expect(second.state.wasResumed, isTrue);
    expect(second.state.currentIndex, 1);
    expect(second.state.answers, hasLength(1));
  });

  test('completar el reto guarda la racha y elimina el intento', () async {
    final clock = MutableClock(DateTime(2026, 7, 15, 10));
    final attemptRepository = MemoryAttemptRepository();
    final progressRepository = MemoryProgressRepository();
    final controller = _createController(
      clock: clock,
      attemptRepository: attemptRepository,
      progressRepository: progressRepository,
    );

    await controller.start();
    final questionCount = controller.state.exam!.questions.length;
    for (var index = 0; index < questionCount; index += 1) {
      controller.selectAnswer(AnswerOption.a);
      if (index < questionCount - 1) {
        controller.next();
      }
    }
    await controller.finish();

    expect(controller.state.phase, DailyChallengePhase.finished);
    expect(controller.state.streakCounted, isTrue);
    expect(progressRepository.value.currentStreak, 1);
    expect(attemptRepository.value, isNull);
  });

  test('un reto que cruza medianoche expira sin aumentar la racha', () async {
    final clock = MutableClock(DateTime(2026, 7, 15, 23, 50));
    final attemptRepository = MemoryAttemptRepository();
    final progressRepository = MemoryProgressRepository();
    final controller = _createController(
      clock: clock,
      attemptRepository: attemptRepository,
      progressRepository: progressRepository,
    );

    await controller.start();
    final questionCount = controller.state.exam!.questions.length;
    for (var index = 0; index < questionCount; index += 1) {
      controller.selectAnswer(AnswerOption.a);
      if (index < questionCount - 1) {
        controller.next();
      }
    }
    clock.value = DateTime(2026, 7, 16, 0, 1);
    await controller.finish();

    expect(controller.state.phase, DailyChallengePhase.failure);
    expect(progressRepository.value.currentStreak, 0);
    expect(attemptRepository.value, isNull);
  });
}

DailyChallengeController _createController({
  required MutableClock clock,
  required MemoryAttemptRepository attemptRepository,
  required MemoryProgressRepository progressRepository,
}) {
  return DailyChallengeController(
    questionRepository: StaticQuestionRepository(
      List.generate(12, _question),
    ),
    challengeRepository: const StaticChallengeRepository([]),
    attemptRepository: attemptRepository,
    progressRepository: progressRepository,
    challengeEngine: const DailyChallengeEngine(),
    examEngine: const ExamEngine(),
    streakEngine: const StreakEngine(),
    clock: clock,
  );
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

class MutableClock implements AppClock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class StaticQuestionRepository implements QuestionRepository {
  const StaticQuestionRepository(this.questions);

  final List<Question> questions;

  @override
  Future<List<Question>> loadQuestions() async => questions;
}

class StaticChallengeRepository implements ChallengeRepository {
  const StaticChallengeRepository(this.challenges);

  final List<DailyChallenge> challenges;

  @override
  Future<List<DailyChallenge>> loadScheduledChallenges() async => challenges;
}

class MemoryAttemptRepository implements DailyAttemptRepository {
  DailyAttempt? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<DailyAttempt?> load() async => value;

  @override
  Future<void> save(DailyAttempt attempt) async {
    value = attempt;
  }
}

class MemoryProgressRepository implements ProgressRepository {
  LearnerProgress value = const LearnerProgress();

  @override
  Future<LearnerProgress> load() async => value;

  @override
  Future<void> save(LearnerProgress progress) async {
    value = progress;
  }
}
