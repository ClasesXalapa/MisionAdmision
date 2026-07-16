import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/data/repositories/local_content_cache_repository.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';

import '../helpers/memory_json_store.dart';

void main() {
  test('guarda archivos y metadatos de contenido', () async {
    final repository = LocalContentCacheRepository(store: MemoryJsonStore());
    final now = DateTime.parse('2026-07-15T12:00:00-06:00');

    await repository.writeRaw(
      ContentFileKind.questions,
      'questions_001',
      '{"ok":true}',
    );
    await repository.saveMetadata(ContentCacheMetadata(
      contentVersion: 'content_001',
      lastAttemptAt: now,
      lastSuccessAt: now,
      lastOutcome: ContentSyncOutcome.success,
      message: 'Actualizado',
      fileVersions: const {
        ContentFileKind.questions: 'questions_001',
      },
    ));

    final restored = await repository.loadMetadata();
    expect(await repository.readRaw(ContentFileKind.questions), '{"ok":true}');
    expect(restored.contentVersion, 'content_001');
    expect(restored.lastOutcome, ContentSyncOutcome.success);
    expect(restored.versionFor(ContentFileKind.questions), 'questions_001');
  });

  test('descartar un archivo también elimina su versión', () async {
    final repository = LocalContentCacheRepository(store: MemoryJsonStore());
    await repository.writeRaw(
      ContentFileKind.resources,
      'resources_001',
      'contenido',
    );
    await repository.saveMetadata(ContentCacheMetadata(
      fileVersions: const {
        ContentFileKind.resources: 'resources_001',
      },
    ));

    await repository.discard(ContentFileKind.resources);

    expect(await repository.readRaw(ContentFileKind.resources), isNull);
    expect(
      (await repository.loadMetadata()).versionFor(ContentFileKind.resources),
      isNull,
    );
  });
}
