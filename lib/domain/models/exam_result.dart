class ExamResult {
  ExamResult({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
    required List<String> incorrectQuestionIds,
  }) : incorrectQuestionIds = List.unmodifiable(incorrectQuestionIds);

  final int total;
  final int correct;
  final int incorrect;
  final int unanswered;
  final List<String> incorrectQuestionIds;
}
