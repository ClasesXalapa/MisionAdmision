enum QuestionDifficulty {
  basic('basico'),
  intermediate('intermedio'),
  advanced('avanzado');

  const QuestionDifficulty(this.jsonValue);

  final String jsonValue;

  static QuestionDifficulty? tryParse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final difficulty in QuestionDifficulty.values) {
      if (difficulty.jsonValue == normalized) {
        return difficulty;
      }
    }
    return null;
  }
}
