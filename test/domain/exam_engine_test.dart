import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/domain/engines/exam_engine.dart';
import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/question_difficulty.dart';

void main() {
  const engine = ExamEngine();

  test('crea un examen con la cantidad solicitada y sin duplicados', () {
    final bank = List.generate(15, _question);

    final exam = engine.createRandomExam(
      questionBank: bank,
      questionCount: 10,
      seed: 123,
    );

    expect(exam.questions, hasLength(10));
    expect(exam.questions.map((question) => question.id).toSet(), hasLength(10));
  });

  test('rechaza una cantidad mayor al banco disponible', () {
    final bank = List.generate(5, _question);

    expect(
      () => engine.createRandomExam(questionBank: bank, questionCount: 10),
      throwsA(isA<StateError>()),
    );
  });

  test('calcula correctas e incorrectas', () {
    final bank = List.generate(10, _question);
    final exam = engine.createRandomExam(
      questionBank: bank,
      questionCount: 10,
      seed: 10,
    );
    final answers = <String, AnswerOption>{
      for (final question in exam.questions) question.id: AnswerOption.a,
    };
    answers[exam.questions.first.id] = AnswerOption.b;

    final result = engine.evaluate(exam: exam, answers: answers);

    expect(result.total, 10);
    expect(result.correct, 9);
    expect(result.incorrect, 1);
    expect(result.unanswered, 0);
  });
}

Question _question(int index) {
  return Question(
    id: 'Q-$index',
    statement: 'Pregunta $index',
    options: const ['Correcta', 'B', 'C', 'D'],
    correctAnswer: AnswerOption.a,
    category: 'matematicas',
    tags: const ['prueba'],
    difficulty: QuestionDifficulty.basic,
  );
}
