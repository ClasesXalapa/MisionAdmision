import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/assets/asset_text_loader.dart';
import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/repositories/local_content_cache_repository.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

import '../helpers/memory_json_store.dart';

void main() {
  test('descarta caché corrupta y utiliza el asset válido', () async {
    final raw = await File('content/preguntas/banco_global.json').readAsString();
    final cache = LocalContentCacheRepository(store: MemoryJsonStore());
    await cache.writeRaw(
      ContentFileKind.questions,
      'questions_bad',
      '{json corrupto',
    );
    await cache.saveMetadata(ContentCacheMetadata(
      fileVersions: const {
        ContentFileKind.questions: 'questions_bad',
      },
    ));
    final loader = LocalFirstContentLoader(
      cache: cache,
      assets: MemoryAssetTextLoader({'questions.json': raw}),
    );

    final questions = await loader.load(
      kind: ContentFileKind.questions,
      fallbackAssetPath: 'questions.json',
      parse: const ContentDocumentParser().parseQuestions,
    );

    expect(questions, isNotEmpty);
    expect(await cache.readRaw(ContentFileKind.questions), isNull);
  });
}

class MemoryAssetTextLoader implements AssetTextLoader {
  const MemoryAssetTextLoader(this.values);

  final Map<String, String> values;

  @override
  Future<String> load(String path) async => values[path]!;
}
