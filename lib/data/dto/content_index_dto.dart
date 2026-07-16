class ContentIndexFileDto {
  const ContentIndexFileDto({
    required this.url,
    required this.version,
    required this.required,
  });

  factory ContentIndexFileDto.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final version = json['version'];
    final requiredValue = json['required'];

    if (url is! String || url.trim().isEmpty) {
      throw const FormatException('La URL del archivo no puede estar vacía.');
    }
    if (version is! String || version.trim().isEmpty) {
      throw const FormatException('La versión del archivo no puede estar vacía.');
    }
    if (requiredValue is! bool) {
      throw const FormatException('El campo required debe ser booleano.');
    }

    return ContentIndexFileDto(
      url: url.trim(),
      version: version.trim(),
      required: requiredValue,
    );
  }

  final String url;
  final String version;
  final bool required;
}

class ContentIndexDto {
  ContentIndexDto({
    required this.schemaVersion,
    required this.contentVersion,
    required this.generatedAt,
    required this.minAppVersion,
    required Map<String, ContentIndexFileDto> files,
  }) : files = Map.unmodifiable(files);

  factory ContentIndexDto.fromJson(Map<String, dynamic> json) {
    final contentVersion = json['content_version'];
    final generatedAtRaw = json['generated_at'];
    final rawFiles = json['files'];

    if (contentVersion is! String || contentVersion.trim().isEmpty) {
      throw const FormatException('content_version debe ser texto no vacío.');
    }
    if (generatedAtRaw is! String) {
      throw const FormatException('generated_at debe ser texto.');
    }
    final generatedAt = DateTime.tryParse(generatedAtRaw);
    if (generatedAt == null) {
      throw const FormatException('generated_at debe utilizar ISO 8601.');
    }
    if (rawFiles is! Map) {
      throw const FormatException('files debe ser un objeto JSON.');
    }

    final files = <String, ContentIndexFileDto>{};
    for (final entry in rawFiles.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) {
        throw const FormatException('Cada entrada de files debe ser un objeto.');
      }
      files[key] = ContentIndexFileDto.fromJson(
        Map<String, dynamic>.from(value),
      );
    }

    final schemaVersion = json['schema_version'];
    final minAppVersion = json['min_app_version'];
    if (schemaVersion is! int) {
      throw const FormatException('schema_version debe ser entero.');
    }
    if (minAppVersion is! int || minAppVersion < 1) {
      throw const FormatException('min_app_version debe ser entero positivo.');
    }

    return ContentIndexDto(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion.trim(),
      generatedAt: generatedAt,
      minAppVersion: minAppVersion,
      files: files,
    );
  }

  final int schemaVersion;
  final String contentVersion;
  final DateTime generatedAt;
  final int minAppVersion;
  final Map<String, ContentIndexFileDto> files;
}
