import 'package:mision_admision/domain/models/content_file_descriptor.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

class ContentIndex {
  ContentIndex({
    required this.schemaVersion,
    required this.contentVersion,
    required this.generatedAt,
    required this.minAppVersion,
    required Map<ContentFileKind, ContentFileDescriptor> files,
  }) : files = Map.unmodifiable(files);

  final int schemaVersion;
  final String contentVersion;
  final DateTime generatedAt;
  final int minAppVersion;
  final Map<ContentFileKind, ContentFileDescriptor> files;
}
