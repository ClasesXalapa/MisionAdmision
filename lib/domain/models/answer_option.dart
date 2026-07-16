enum AnswerOption {
  a,
  b,
  c,
  d;

  String get label => name.toUpperCase();

  static AnswerOption? tryParse(String value) {
    final normalized = value.trim().toUpperCase();
    for (final option in AnswerOption.values) {
      if (option.label == normalized) {
        return option;
      }
    }
    return null;
  }
}
