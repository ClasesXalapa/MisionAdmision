enum ExamKind {
  freeRandom,
  dailyScheduled,
  dailyAutomatic;

  String get storageValue => switch (this) {
        ExamKind.freeRandom => 'FREE_RANDOM',
        ExamKind.dailyScheduled => 'DAILY_SCHEDULED',
        ExamKind.dailyAutomatic => 'DAILY_RANDOM_FALLBACK',
      };

  static ExamKind parse(String value) {
    return switch (value) {
      'FREE_RANDOM' => ExamKind.freeRandom,
      'DAILY_SCHEDULED' => ExamKind.dailyScheduled,
      'DAILY_RANDOM_FALLBACK' => ExamKind.dailyAutomatic,
      _ => throw FormatException('Tipo de examen desconocido: $value.'),
    };
  }
}
