import 'dart:convert';

import 'package:mision_admision/core/constants/app_constants.dart';
import 'package:mision_admision/data/dto/content_index_dto.dart';
import 'package:mision_admision/domain/models/content_file_descriptor.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/content_index.dart';

class ContentIndexParser {
  const ContentIndexParser();

  static final RegExp _versionPattern = RegExp(r'^[A-Za-z0-9._-]{1,100}$');

  ContentIndex parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('index.json debe contener un objeto JSON.');
    }

    final dto = ContentIndexDto.fromJson(Map<String, dynamic>.from(decoded));
    if (dto.schemaVersion != AppConstants.supportedContentSchemaVersion) {
      throw FormatException(
        'Versión de index.json no soportada: ${dto.schemaVersion}.',
      );
    }

    if (!_versionPattern.hasMatch(dto.contentVersion)) {
      throw const FormatException(
        'content_version contiene caracteres no permitidos.',
      );
    }

    final files = <ContentFileKind, ContentFileDescriptor>{};
    for (final entry in dto.files.entries) {
      final kind = ContentFileKind.tryParse(entry.key);
      if (kind == null) {
        throw FormatException('index.json contiene un archivo desconocido: ${entry.key}.');
      }
      _validateLocation(entry.value.url, kind);
      if (!_versionPattern.hasMatch(entry.value.version)) {
        throw FormatException(
          'La versión de ${kind.label} contiene caracteres no permitidos.',
        );
      }
      files[kind] = ContentFileDescriptor(
        kind: kind,
        url: entry.value.url,
        version: entry.value.version,
        required: entry.value.required,
      );
    }

    for (final kind in ContentFileKind.values) {
      if (!files.containsKey(kind)) {
        throw FormatException('index.json no incluye files.${kind.key}.');
      }
    }
    if (!files[ContentFileKind.questions]!.required) {
      throw const FormatException('El banco de preguntas debe ser obligatorio.');
    }
    for (final kind in ContentFileKind.values) {
      if (kind != ContentFileKind.questions && files[kind]!.required) {
        throw FormatException('${kind.label} debe declararse como opcional.');
      }
    }

    return ContentIndex(
      schemaVersion: dto.schemaVersion,
      contentVersion: dto.contentVersion,
      generatedAt: dto.generatedAt,
      minAppVersion: dto.minAppVersion,
      files: files,
    );
  }

  void _validateLocation(String value, ContentFileKind kind) {
    final uri = Uri.tryParse(value);
    if (uri == null || value.contains('..')) {
      throw FormatException('La URL de ${kind.label} no es válida.');
    }
    if (uri.hasScheme && uri.scheme != 'https') {
      throw FormatException('La URL de ${kind.label} debe usar HTTPS.');
    }
    if (uri.hasScheme && uri.host.isEmpty) {
      throw FormatException('La URL de ${kind.label} no tiene host.');
    }
  }
}
