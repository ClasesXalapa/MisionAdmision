import 'package:mision_admision/domain/models/answer_option.dart';
import 'package:mision_admision/domain/models/question_difficulty.dart';

class Question {
  Question({
    required this.id,
    required this.statement,
    required List<String> options,
    required this.correctAnswer,
    required this.category,
    required List<String> tags,
    required this.difficulty,
    this.imageUrl,
  })  : options = List.unmodifiable(options),
        tags = List.unmodifiable(tags);

  final String id;
  final String statement;
  final String? imageUrl;
  final List<String> options;
  final AnswerOption correctAnswer;
  final String category;
  final List<String> tags;
  final QuestionDifficulty difficulty;

  String optionText(AnswerOption option) => options[option.index];
}
