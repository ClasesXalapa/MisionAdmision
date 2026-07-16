import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/models/resolution_resource.dart';

class Exam {
  Exam({
    required this.id,
    required List<Question> questions,
    this.kind = ExamKind.freeRandom,
    this.title = 'Examen libre',
    this.dateKey,
    this.resolutionResource,
  }) : questions = List.unmodifiable(questions);

  final String id;
  final List<Question> questions;
  final ExamKind kind;
  final String title;
  final String? dateKey;
  final ResolutionResource? resolutionResource;
}
