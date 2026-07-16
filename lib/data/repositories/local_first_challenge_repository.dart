import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/repositories/challenge_repository.dart';

class LocalFirstChallengeRepository implements ChallengeRepository {
  const LocalFirstChallengeRepository({
    required LocalFirstContentLoader loader,
    required ContentDocumentParser parser,
    required this.fallbackAssetPath,
  })  : _loader = loader,
        _parser = parser;

  final LocalFirstContentLoader _loader;
  final ContentDocumentParser _parser;
  final String fallbackAssetPath;

  @override
  Future<List<DailyChallenge>> loadScheduledChallenges() {
    return _loader.load(
      kind: ContentFileKind.challenges,
      fallbackAssetPath: fallbackAssetPath,
      parse: _parser.parseChallenges,
    );
  }
}
