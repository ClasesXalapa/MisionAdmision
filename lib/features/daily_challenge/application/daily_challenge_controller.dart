import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/domain/engines/daily_challenge_engine.dart';
import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/engines/streak_engine.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/exam.dart';
import 'package:mision_admision/domain/models/learner_progress.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/repositories/challenge_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/repositories/progress_repository.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';
import 'package:mision_admision/features/daily_challenge/application/daily_challenge_state.dart';

class DailyChallengeController extends ChangeNotifier {
  DailyChallengeController({
    required QuestionRepository questionRepository,
    required ChallengeRepository challengeRepository,
    required DailyAttemptRepository attemptRepository,
    required ProgressRepository progressRepository,
    required DailyChallengeEngine challengeEngine,
    required ExamEngine examEngine,
    required StreakEngine streakEngine,
    required AppClock clock,
  })  : _questionRepository = questionRepository,
        _challengeRepository = challengeRepository,
        _attemptRepository = attemptRepository,
        _progressRepository = progressRepository,
        _challengeEngine = challengeEngine,
        _examEngine = examEngine,
        _streakEngine = streakEngine,
        _clock = clock;

  final QuestionRepository _questionRepository;
  final ChallengeRepository _challengeRepository;
  final DailyAttemptRepository _attemptRepository;
  final ProgressRepository _progressRepository;
  final DailyChallengeEngine _challengeEngine;
  final ExamEngine _examEngine;
  final StreakEngine _streakEngine;
  final AppClock _clock;

  DailyChallengeState _state = DailyChallengeState.loading();
  Future<void> _writeQueue = Future<void>.value();
  bool _finishing = false;
  DateTime? _startedAt;

  DailyChallengeState get state => _state;

  Future<void> start() async {
    _setState(DailyChallengeState.loading());
    _finishing = false;

    try {
      final now = _clock.now();
      final todayDateKey = localDateKey(now);
      final results = await Future.wait<Object?>([
        _questionRepository.loadQuestions(),
        _challengeRepository.loadScheduledChallenges(),
        _progressRepository.load(),
        _attemptRepository.load(),
      ]);

      final questions = results[0] as List<Question>;
      final scheduled = results[1] as List<DailyChallenge>;
      final loadedProgress = results[2] as LearnerProgress;
      var pendingAttempt = results[3] as DailyAttempt?;
      final reconciliation = _streakEngine.reconcile(
        progress: loadedProgress,
        todayDateKey: todayDateKey,
      );
      final progress = reconciliation.progress;
      await _progressRepository.save(progress);

      if (pendingAttempt != null && pendingAttempt.dateKey != todayDateKey) {
        await _attemptRepository.clear();
        pendingAttempt = null;
      }

      if (pendingAttempt != null) {
        _startedAt = pendingAttempt.startedAt;
        final restored = _tryRestore(
          attempt: pendingAttempt,
          questions: questions,
          scheduled: scheduled,
        );
        if (restored != null) {
          _setState(
            DailyChallengeState.ready(
              exam: restored,
              progress: progress,
              currentIndex: pendingAttempt.currentIndex,
              answers: _validAnswers(pendingAttempt.answers, restored),
              wasResumed: true,
            ),
          );
          return;
        }
        await _attemptRepository.clear();
      }

      final challenge = _challengeEngine.resolveChallenge(
        dateKey: todayDateKey,
        scheduledChallenges: scheduled,
        questionBank: questions,
      );
      final exam = _challengeEngine.buildExam(
        challenge: challenge,
        questionBank: questions,
      );
      _startedAt = now;
      final attempt = DailyAttempt(
        challengeId: challenge.id,
        dateKey: todayDateKey,
        title: challenge.title,
        kind: challenge.kind,
        questionIds: challenge.questionIds,
        answers: const {},
        currentIndex: 0,
        startedAt: now,
      );
      await _attemptRepository.save(attempt);

      _setState(
        DailyChallengeState.ready(exam: exam, progress: progress),
      );
    } on Object catch (error) {
      _setState(
        DailyChallengeState.failure(
          'No fue posible preparar el reto diario. ${error.toString()}',
        ),
      );
    }
  }

  void selectAnswer(AnswerOption option) {
    final exam = _state.exam;
    final question = _state.currentQuestion;
    if (_state.phase != DailyChallengePhase.ready ||
        exam == null ||
        question == null) {
      return;
    }

    final answers = Map<String, AnswerOption>.of(_state.answers)
      ..[question.id] = option;
    _setState(
      DailyChallengeState.ready(
        exam: exam,
        progress: _state.progress,
        currentIndex: _state.currentIndex,
        answers: answers,
        wasResumed: _state.wasResumed,
      ),
    );
    _queuePersistence();
  }

  void previous() => _moveTo(_state.currentIndex - 1);

  void next() => _moveTo(_state.currentIndex + 1);

  Future<void> finish() async {
    final exam = _state.exam;
    if (_finishing ||
        _state.phase != DailyChallengePhase.ready ||
        exam == null ||
        !_state.allAnswered) {
      return;
    }

    _finishing = true;
    try {
      await _writeQueue;
      final todayDateKey = localDateKey(_clock.now());
      if (exam.dateKey != todayDateKey) {
        await _attemptRepository.clear();
        _setState(
          DailyChallengeState.failure(
            'El reto pendiente expiró al terminar el día. Abre el reto de hoy para continuar.',
          ),
        );
        return;
      }

      final result = _examEngine.evaluate(exam: exam, answers: _state.answers);
      final completion = _streakEngine.completeDailyChallenge(
        progress: _state.progress,
        todayDateKey: todayDateKey,
      );
      await _progressRepository.save(completion.progress);
      await _attemptRepository.clear();

      _setState(
        DailyChallengeState.finished(
          exam: exam,
          answers: _state.answers,
          result: result,
          progress: completion.progress,
          streakCounted: completion.countedToday,
          shieldEarned: completion.shieldEarned,
        ),
      );
    } on Object catch (error) {
      _setState(
        DailyChallengeState.failure(
          'No fue posible guardar el resultado. ${error.toString()}',
        ),
      );
    } finally {
      _finishing = false;
    }
  }

  Exam? _tryRestore({
    required DailyAttempt attempt,
    required List<Question> questions,
    required List<DailyChallenge> scheduled,
  }) {
    try {
      final challenge = _challengeEngine.restoreChallenge(
        challengeId: attempt.challengeId,
        dateKey: attempt.dateKey,
        title: attempt.title,
        kind: attempt.kind,
        questionIds: attempt.questionIds,
        scheduledChallenges: scheduled,
      );
      return _challengeEngine.buildExam(
        challenge: challenge,
        questionBank: questions,
      );
    } on Object {
      return null;
    }
  }

  Map<String, AnswerOption> _validAnswers(
    Map<String, AnswerOption> answers,
    Exam exam,
  ) {
    final validIds = exam.questions.map((question) => question.id).toSet();
    return Map.fromEntries(
      answers.entries.where((entry) => validIds.contains(entry.key)),
    );
  }

  void _moveTo(int requestedIndex) {
    final exam = _state.exam;
    if (_state.phase != DailyChallengePhase.ready || exam == null) {
      return;
    }

    final newIndex = requestedIndex.clamp(0, exam.questions.length - 1).toInt();
    if (newIndex == _state.currentIndex) {
      return;
    }
    _setState(
      DailyChallengeState.ready(
        exam: exam,
        progress: _state.progress,
        currentIndex: newIndex,
        answers: _state.answers,
        wasResumed: _state.wasResumed,
      ),
    );
    _queuePersistence();
  }

  void _queuePersistence() {
    final snapshot = _buildAttemptSnapshot();
    if (snapshot == null) {
      return;
    }
    _writeQueue = _writeQueue
        .then((_) => _attemptRepository.save(snapshot))
        .catchError((Object _) {});
  }

  DailyAttempt? _buildAttemptSnapshot() {
    final exam = _state.exam;
    final dateKey = exam?.dateKey;
    if (_state.phase != DailyChallengePhase.ready ||
        exam == null ||
        dateKey == null) {
      return null;
    }

    return DailyAttempt(
      challengeId: exam.id,
      dateKey: dateKey,
      title: exam.title,
      kind: exam.kind,
      questionIds: exam.questions.map((question) => question.id).toList(),
      answers: _state.answers,
      currentIndex: _state.currentIndex,
      startedAt: _startedAt ?? _clock.now(),
    );
  }

  void _setState(DailyChallengeState value) {
    _state = value;
    notifyListeners();
  }
}
