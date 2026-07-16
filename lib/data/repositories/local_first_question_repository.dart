import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/repositories/question_repository.dart';

class LocalFirstQuestionRepository implements QuestionRepository {
  const LocalFirstQuestionRepository({
    required LocalFirstContentLoader loader,
    required ContentDocumentParser parser,
    required this.fallbackAssetPath,
  })  : _loader = loader,
        _parser = parser;

  final LocalFirstContentLoader _loader;
  final ContentDocumentParser _parser;
  final String fallbackAssetPath;

  @override
  Future<List<Question>> loadQuestions() {
    return _loader.load(
      kind: ContentFileKind.questions,
      fallbackAssetPath: fallbackAssetPath,
      parse: _parser.parseQuestions,
    );
  }
}
