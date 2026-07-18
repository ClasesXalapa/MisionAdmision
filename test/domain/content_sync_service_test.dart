import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/core/assets/asset_text_loader.dart';
import 'package:mision_admision/core/constants/app_constants.dart';
import 'package:mision_admision/core/network/remote_text_client.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/parsers/content_index_parser.dart';
import 'package:mision_admision/data/repositories/local_content_cache_repository.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/content_sync_report.dart';
import 'package:mision_admision/domain/models/daily_attempt.dart';
import 'package:mision_admision/domain/models/exam_kind.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';
import 'package:mision_admision/domain/services/content_sync_service.dart';

import '../helpers/memory_json_store.dart';

void main() {
  late Map<String, String> content;

  setUp(() async {
    content = {
      'content/index.json': await File('content/index.json').readAsString(),
      'content/preguntas/banco_global.json':
          await File('content/preguntas/banco_global.json').readAsString(),
      'content/retos/retos_actuales.json':
          await File('content/retos/retos_actuales.json').readAsString(),
      'content/cards/cards_actuales.json':
          await File('content/cards/cards_actuales.json').readAsString(),
      'content/config/rangos.json':
          await File('content/config/rangos.json').readAsString(),
    };
  });

  test('descarga, valida y conserva versiones', () async {
    final fixture = _fixture(content);

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.success);
    expect(report.changed, isTrue);
    expect(
      await fixture.cache.readRaw(ContentFileKind.questions),
      content['content/preguntas/banco_global.json'],
    );
    expect(
      report.files.where(
        (item) => item.outcome == ContentFileSyncOutcome.updated,
      ),
      hasLength(4),
    );
  });

  test('omite archivos cuya versión ya está almacenada', () async {
    final fixture = _fixture(content);
    await fixture.service.synchronize();
    final requestsAfterFirstSync = fixture.remote.requestedPaths.length;

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.success);
    expect(report.changed, isFalse);
    expect(
      fixture.remote.requestedPaths.length - requestsAfterFirstSync,
      1,
      reason: 'La segunda revisión solo debe descargar index.json.',
    );
  });

  test('un archivo remoto inválido no reemplaza la copia válida', () async {
    final fixture = _fixture(content);
    await fixture.service.synchronize();
    final previous = await fixture.cache.readRaw(ContentFileKind.resources);

    final index = jsonDecode(content['content/index.json']!) as Map<String, dynamic>;
    ((index['files'] as Map<String, dynamic>)['resources']
        as Map<String, dynamic>)['version'] = 'cards_002';
    fixture.remote.values['content/index.json'] = jsonEncode(index);
    fixture.remote.values['content/cards/cards_actuales.json'] = '{invalido';

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.partial);
    expect(await fixture.cache.readRaw(ContentFileKind.resources), previous);
    expect(
      report.files.singleWhere(
        (item) => item.kind == ContentFileKind.resources,
      ).outcome,
      ContentFileSyncOutcome.failed,
    );
  });

  test('protege las preguntas utilizadas por un intento pendiente', () async {
    final questionBank = jsonDecode(content['content/preguntas/banco_global.json']!)
        as Map<String, dynamic>;
    final challengeBank = jsonDecode(content['content/retos/retos_actuales.json']!)
        as Map<String, dynamic>;
    final referenced = ((challengeBank['retos'] as List).first
        as Map<String, dynamic>)['preguntas_ids'] as List;
    final protectedId = (questionBank['preguntas'] as List)
        .map((item) => (item as Map<String, dynamic>)['id'] as String)
        .firstWhere((id) => !referenced.contains(id));
    final attempt = DailyAttempt(
      challengeId: 'auto_reto_2026_07_15',
      dateKey: '2026-07-15',
      title: 'Reto pendiente',
      kind: ExamKind.dailyAutomatic,
      questionIds: [protectedId],
      answers: const {},
      currentIndex: 0,
      startedAt: DateTime.parse('2026-07-15T10:00:00-06:00'),
    );
    final fixture = _fixture(content, attempt: attempt);
    await fixture.service.synchronize();
    final previous = await fixture.cache.readRaw(ContentFileKind.questions);

    final updatedVersion = _nextVersion(questionBank['version'] as String);
    final index = jsonDecode(content['content/index.json']!) as Map<String, dynamic>;
    ((index['files'] as Map<String, dynamic>)['questions']
        as Map<String, dynamic>)['version'] = updatedVersion;
    fixture.remote.values['content/index.json'] = jsonEncode(index);
    (questionBank['preguntas'] as List).removeWhere(
      (item) => (item as Map<String, dynamic>)['id'] == protectedId,
    );
    questionBank['version'] = updatedVersion;
    fixture.remote.values['content/preguntas/banco_global.json'] =
        jsonEncode(questionBank);

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.partial);
    expect(await fixture.cache.readRaw(ContentFileKind.questions), previous);
  });

  test('un intento vencido no bloquea una actualización válida', () async {
    final questionBank = jsonDecode(content['content/preguntas/banco_global.json']!)
        as Map<String, dynamic>;
    final challengeBank = jsonDecode(content['content/retos/retos_actuales.json']!)
        as Map<String, dynamic>;
    final referenced = ((challengeBank['retos'] as List).first
        as Map<String, dynamic>)['preguntas_ids'] as List;
    final removableId = (questionBank['preguntas'] as List)
        .map((item) => (item as Map<String, dynamic>)['id'] as String)
        .firstWhere((id) => !referenced.contains(id));
    final staleAttempt = DailyAttempt(
      challengeId: 'auto_reto_2026_07_14',
      dateKey: '2026-07-14',
      title: 'Reto vencido',
      kind: ExamKind.dailyAutomatic,
      questionIds: [removableId],
      answers: const {},
      currentIndex: 0,
      startedAt: DateTime.parse('2026-07-14T10:00:00-06:00'),
    );
    final fixture = _fixture(content, attempt: staleAttempt);
    await fixture.service.synchronize();

    final updatedVersion = _nextVersion(questionBank['version'] as String);
    final index = jsonDecode(content['content/index.json']!)
        as Map<String, dynamic>;
    ((index['files'] as Map<String, dynamic>)['questions']
        as Map<String, dynamic>)['version'] = updatedVersion;
    fixture.remote.values['content/index.json'] = jsonEncode(index);
    questionBank['version'] = updatedVersion;
    (questionBank['preguntas'] as List).removeWhere(
      (item) => (item as Map<String, dynamic>)['id'] == removableId,
    );
    fixture.remote.values['content/preguntas/banco_global.json'] =
        jsonEncode(questionBank);

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.success);
    expect(
      report.files.singleWhere(
        (item) => item.kind == ContentFileKind.questions,
      ).outcome,
      ContentFileSyncOutcome.updated,
    );
  });

  test('rechaza preguntas nuevas que rompen un reto existente', () async {
    final fixture = _fixture(content);
    await fixture.service.synchronize();
    final previous = await fixture.cache.readRaw(ContentFileKind.questions);

    final questions = jsonDecode(content['content/preguntas/banco_global.json']!)
        as Map<String, dynamic>;
    final updatedVersion = _nextVersion(questions['version'] as String);
    final index = jsonDecode(content['content/index.json']!) as Map<String, dynamic>;
    ((index['files'] as Map<String, dynamic>)['questions']
        as Map<String, dynamic>)['version'] = updatedVersion;
    fixture.remote.values['content/index.json'] = jsonEncode(index);

    questions['version'] = updatedVersion;
    final challengeBank = jsonDecode(content['content/retos/retos_actuales.json']!)
        as Map<String, dynamic>;
    final challenge = (challengeBank['retos'] as List).first as Map<String, dynamic>;
    final referencedId = (challenge['preguntas_ids'] as List).first;
    (questions['preguntas'] as List).removeWhere(
      (item) => (item as Map<String, dynamic>)['id'] == referencedId,
    );
    fixture.remote.values['content/preguntas/banco_global.json'] =
        jsonEncode(questions);

    final report = await fixture.service.synchronize();

    expect(report.metadata.lastOutcome, ContentSyncOutcome.partial);
    expect(await fixture.cache.readRaw(ContentFileKind.questions), previous);
  });
}

String _nextVersion(String current) {
  final match = RegExp(r'^(.*?)(\d+)$').firstMatch(current);
  if (match == null) return '${current}_next';

  final prefix = match.group(1)!;
  final digits = match.group(2)!;
  final next = int.parse(digits) + 1;
  return '$prefix${next.toString().padLeft(digits.length, '0')}';
}

_SyncFixture _fixture(
  Map<String, String> values, {
  DailyAttempt? attempt,
}) {
  final store = MemoryJsonStore();
  final cache = LocalContentCacheRepository(store: store);
  final remote = MemoryRemoteTextClient(Map.of(values));
  final assets = MemoryAssetTextLoader(values);
  final loader = LocalFirstContentLoader(cache: cache, assets: assets);
  final service = ContentSyncService(
    remoteClient: remote,
    cache: cache,
    attemptRepository: MemoryAttemptRepository(attempt),
    localLoader: loader,
    indexParser: const ContentIndexParser(),
    documentParser: const ContentDocumentParser(),
    clock: FixedClock(DateTime.parse('2026-07-15T12:00:00-06:00')),
    baseUri: Uri.parse('https://example.com/app/'),
    appBuildNumber: AppConstants.appBuildNumber,
  );
  return _SyncFixture(service: service, cache: cache, remote: remote);
}

class _SyncFixture {
  const _SyncFixture({
    required this.service,
    required this.cache,
    required this.remote,
  });

  final ContentSyncService service;
  final LocalContentCacheRepository cache;
  final MemoryRemoteTextClient remote;
}

class FixedClock implements AppClock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class MemoryRemoteTextClient implements RemoteTextClient {
  MemoryRemoteTextClient(this.values);

  final Map<String, String> values;
  final List<String> requestedPaths = [];

  @override
  Future<String> get(Uri uri) async {
    final path = uri.path.replaceFirst('/app/', '');
    requestedPaths.add(path);
    final value = values[path];
    if (value == null) throw StateError('No existe $path');
    return value;
  }
}

class MemoryAssetTextLoader implements AssetTextLoader {
  const MemoryAssetTextLoader(this.values);

  final Map<String, String> values;

  @override
  Future<String> load(String path) async => values[path]!;
}

class MemoryAttemptRepository implements DailyAttemptRepository {
  MemoryAttemptRepository(this.value);

  DailyAttempt? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<DailyAttempt?> load() async => value;

  @override
  Future<void> save(DailyAttempt attempt) async {
    value = attempt;
  }
}
