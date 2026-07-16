enum ContentFileKind {
  questions('questions'),
  challenges('challenges'),
  resources('resources'),
  ranks('ranks');

  const ContentFileKind(this.key);

  final String key;

  static ContentFileKind? tryParse(String value) {
    for (final kind in values) {
      if (kind.key == value) return kind;
    }
    return null;
  }

  String get label => switch (this) {
        ContentFileKind.questions => 'preguntas',
        ContentFileKind.challenges => 'retos',
        ContentFileKind.resources => 'recursos',
        ContentFileKind.ranks => 'rangos',
      };
}
