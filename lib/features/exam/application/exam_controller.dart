import 'package:flutter/foundation.dart';
import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';
import 'package:mision_admision/features/exam/application/exam_state.dart';

class ExamController extends ChangeNotifier {
  ExamController({
    required QuestionRepository repository,
    required ExamEngine engine,
  })  : _repository = repository,
        _engine = engine;

  final QuestionRepository _repository;
  final ExamEngine _engine;

  ExamState _state = ExamState.loading();
  ExamState get state => _state;

  Future<void> start() async {
    _setState(ExamState.loading());
    try {
      final bank = await _repository.loadQuestions();
      final exam = _engine.createRandomExam(questionBank: bank);
      _setState(ExamState.ready(exam: exam));
    } on Object catch (error) {
      _setState(
        ExamState.failure(
          'No fue posible cargar el examen. ${error.toString()}',
        ),
      );
    }
  }

  void selectAnswer(AnswerOption option) {
    final exam = _state.exam;
    final question = _state.currentQuestion;
    if (_state.phase != ExamPhase.ready || exam == null || question == null) {
      return;
    }

    final answers = Map<String, AnswerOption>.of(_state.answers)
      ..[question.id] = option;
    _setState(
      ExamState.ready(
        exam: exam,
        currentIndex: _state.currentIndex,
        answers: answers,
      ),
    );
  }

  void previous() {
    final exam = _state.exam;
    if (_state.phase != ExamPhase.ready || exam == null) {
      return;
    }

    final newIndex = (_state.currentIndex - 1)
        .clamp(0, exam.questions.length - 1)
        .toInt();
    _setState(
      ExamState.ready(
        exam: exam,
        currentIndex: newIndex,
        answers: _state.answers,
      ),
    );
  }

  void next() {
    final exam = _state.exam;
    if (_state.phase != ExamPhase.ready || exam == null) {
      return;
    }

    final newIndex = (_state.currentIndex + 1)
        .clamp(0, exam.questions.length - 1)
        .toInt();
    _setState(
      ExamState.ready(
        exam: exam,
        currentIndex: newIndex,
        answers: _state.answers,
      ),
    );
  }

  void finish() {
    final exam = _state.exam;
    if (_state.phase != ExamPhase.ready || exam == null || !_state.allAnswered) {
      return;
    }

    final result = _engine.evaluate(exam: exam, answers: _state.answers);
    _setState(
      ExamState.finished(
        exam: exam,
        answers: _state.answers,
        result: result,
      ),
    );
  }

  void _setState(ExamState value) {
    _state = value;
    notifyListeners();
  }
}
