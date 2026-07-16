import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/resolution_resource.dart';

class DailyChallenge {
  DailyChallenge({
    required this.id,
    required this.dateKey,
    required this.title,
    required List<String> questionIds,
    required this.kind,
    this.resolutionResource,
  }) : questionIds = List.unmodifiable(questionIds);

  final String id;
  final String dateKey;
  final String title;
  final List<String> questionIds;
  final ExamKind kind;
  final ResolutionResource? resolutionResource;
}
