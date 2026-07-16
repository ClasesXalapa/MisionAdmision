class QuestionDto {
  const QuestionDto({
    required this.id,
    required this.statement,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.tags,
    required this.difficulty,
    this.imageUrl,
  });

  factory QuestionDto.fromJson(Map<String, dynamic> json) {
    return QuestionDto(
      id: _requiredString(json, 'id'),
      statement: _requiredString(json, 'enunciado'),
      imageUrl: _nullableString(json, 'imagen_url'),
      options: _requiredStringList(json, 'opciones'),
      correctAnswer: _requiredString(json, 'respuesta_correcta'),
      category: _requiredString(json, 'categoria'),
      tags: _requiredStringList(json, 'etiquetas'),
      difficulty: _requiredString(json, 'dificultad'),
    );
  }

  final String id;
  final String statement;
  final String? imageUrl;
  final List<String> options;
  final String correctAnswer;
  final String category;
  final List<String> tags;
  final String difficulty;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('El campo "$key" debe ser texto.');
  }
  return value;
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('El campo "$key" debe ser texto o null.');
  }
  return value;
}

List<String> _requiredStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('El campo "$key" debe ser una lista.');
  }
  if (value.any((item) => item is! String)) {
    throw FormatException('Todos los elementos de "$key" deben ser texto.');
  }
  return value.cast<String>();
}
