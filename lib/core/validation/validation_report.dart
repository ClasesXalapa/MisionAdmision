import 'package:mision_admision/core/validation/validation_issue.dart';

class ValidationReport<T> {
  const ValidationReport._({
    required this.value,
    required this.issues,
  });

  factory ValidationReport.valid(T value) {
    return ValidationReport._(value: value, issues: const []);
  }

  factory ValidationReport.invalid(List<ValidationIssue> issues) {
    return ValidationReport._(value: null, issues: List.unmodifiable(issues));
  }

  final T? value;
  final List<ValidationIssue> issues;

  bool get isValid => issues.isEmpty && value != null;
}
