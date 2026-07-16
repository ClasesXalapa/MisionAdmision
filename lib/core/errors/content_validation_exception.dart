import 'package:mision_admision/core/errors/app_exception.dart';
import 'package:mision_admision/core/validation/validation_issue.dart';

class ContentValidationException extends AppException {
  ContentValidationException(this.issues)
      : super(
          issues.isEmpty
              ? 'El contenido no es válido.'
              : 'El contenido contiene ${issues.length} error(es).',
        );

  final List<ValidationIssue> issues;
}
