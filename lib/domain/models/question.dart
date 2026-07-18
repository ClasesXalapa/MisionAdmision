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
    List<String?>? optionImageUrls,
  })  : options = List.unmodifiable(options),
        optionImageUrls = List.unmodifiable(
          optionImageUrls ?? List<String?>.filled(options.length, null),
        ),
        tags = List.unmodifiable(tags) {
    if (this.optionImageUrls.length != this.options.length) {
      throw ArgumentError(
        'Cada opción debe tener una posición equivalente para su imagen.',
      );
    }
  }

  final String id;
  final String statement;
  final String? imageUrl;
  final List<String> options;
  final List<String?> optionImageUrls;
  final AnswerOption correctAnswer;
  final String category;
  final List<String> tags;
  final QuestionDifficulty difficulty;

  String optionText(AnswerOption option) => options[option.index];

  String? optionImageUrl(AnswerOption option) =>
      optionImageUrls[option.index];
}
