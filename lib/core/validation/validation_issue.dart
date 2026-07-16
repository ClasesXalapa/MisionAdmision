class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.message,
    required this.path,
  });

  final String code;
  final String message;
  final String path;

  @override
  String toString() => '$path: $message';
}
