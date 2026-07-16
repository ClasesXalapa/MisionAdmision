import 'package:mision_admision/domain/models/content_file_kind.dart';

class ContentFileDescriptor {
  const ContentFileDescriptor({
    required this.kind,
    required this.url,
    required this.version,
    required this.required,
  });

  final ContentFileKind kind;
  final String url;
  final String version;
  final bool required;
}
