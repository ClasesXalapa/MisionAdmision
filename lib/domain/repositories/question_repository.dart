import 'package:mision_admision/domain/models/question.dart';

abstract interface class QuestionRepository {
  Future<List<Question>> loadQuestions();
}
