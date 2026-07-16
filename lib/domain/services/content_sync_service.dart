import 'dart:convert';

import 'package:mision_admision/core/network/remote_text_client.dart';
import 'package:mision_admision/core/time/app_clock.dart';
import 'package:mision_admision/core/time/local_date.dart';
import 'package:mision_admision/data/parsers/content_document_parser.dart';
import 'package:mision_admision/data/parsers/content_index_parser.dart';
import 'package:mision_admision/data/sources/local_first_content_loader.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_descriptor.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/content_sync_report.dart';
import 'package:mision_admision/domain/models/daily_challenge.dart';
import 'package:mision_admision/domain/models/question.dart';
import 'package:mision_admision/domain/repositories/content_cache_repository.dart';
import 'package:mision_admision/domain/repositories/daily_attempt_repository.dart';

class ContentSyncService {
  ContentSyncService({
    required RemoteTextClient remoteClient,
    required ContentCacheRepository cache,
    required DailyAttemptRepository attemptRepository,
    required LocalFirstContentLoader localLoader,
    required ContentIndexParser indexParser,
    required ContentDocumentParser documentParser,
    required AppClock clock,
    required Uri baseUri,
    required int appBuildNumber,
  })  : _remoteClient = remoteClient,
        _cache = cache,
        _attemptRepository = attemptRepository,
        _localLoader = localLoader,
        _indexParser = indexParser,
        _documentParser = documentParser,
        _clock = clock,
        _baseUri = _directoryUri(baseUri),
        _appBuildNumber = appBuildNumber;

  final RemoteTextClient _remoteClient;
  final ContentCacheRepository _cache;
  final DailyAttemptRepository _attemptRepository;
  final LocalFirstContentLoader _localLoader;
  final ContentIndexParser _indexParser;
  final ContentDocumentParser _documentParser;
  final AppClock _clock;
  final Uri _baseUri;
  final int _appBuildNumber;

  Future<ContentSyncReport> synchronize({bool force = false}) async {
    final now = _clock.now();
    ContentCacheMetadata previous;
    try {
      previous = await _cache.loadMetadata();
    } on Object {
      previous = ContentCacheMetadata();
    }

    try {
      final indexUri = _cacheBusted(
        _baseUri.resolve('content/index.json'),
        now.millisecondsSinceEpoch.toString(),
      );
      final index = _indexParser.parse(await _remoteClient.get(indexUri));

      if (index.minAppVersion > _appBuildNumber) {
        return _saveFailure(
          previous: previous,
          now: now,
          message:
              'El contenido requiere una versión más reciente de Misión Admisión.',
        );
      }

      final stagedRaw = <ContentFileKind, String>{};
      final stagedParsed = <ContentFileKind, Object>{};
      final failures = <ContentFileKind, String>{};
      final unchanged = <ContentFileKind>{};

      for (final kind in ContentFileKind.values) {
        final descriptor = index.files[kind]!;
        final cachedRaw = await _cache.readRaw(kind);
        final hasCurrentVersion =
            previous.versionFor(kind) == descriptor.version &&
                cachedRaw != null &&
                cachedRaw.trim().isNotEmpty;

        if (!force && hasCurrentVersion) {
          unchanged.add(kind);
          continue;
        }

        try {
          final uri = _contentUri(descriptor);
          final raw = await _remoteClient.get(uri);
          final declaredVersion = _declaredVersion(raw);
          if (declaredVersion != descriptor.version) {
            throw FormatException(
              'La versión interna $declaredVersion no coincide con ${descriptor.version}.',
            );
          }
          stagedParsed[kind] = _parse(kind, raw);
          stagedRaw[kind] = raw;
        } on Object catch (error) {
          failures[kind] = _readableError(error);
        }
      }

      await _validateQuestionChallengePair(
        stagedParsed: stagedParsed,
        stagedRaw: stagedRaw,
        failures: failures,
      );

      final versions = Map<ContentFileKind, String>.of(previous.fileVersions);
      final updated = <ContentFileKind>{};

      for (final entry in stagedRaw.entries.toList(growable: false)) {
        final kind = entry.key;
        if (failures.containsKey(kind)) continue;
        try {
          await _cache.writeRaw(
            kind,
            index.files[kind]!.version,
            entry.value,
          );
          versions[kind] = index.files[kind]!.version;
          updated.add(kind);
        } on Object catch (error) {
          failures[kind] = 'No se pudo guardar: ${_readableError(error)}';
        }
      }

      final outcome = failures.isEmpty
          ? ContentSyncOutcome.success
          : ContentSyncOutcome.partial;
      final message = failures.isEmpty
          ? updated.isEmpty
              ? 'Ya tienes la versión más reciente.'
              : 'Contenido actualizado correctamente.'
          : 'Algunos archivos no pudieron actualizarse. Se conservaron las copias válidas.';

      final metadata = ContentCacheMetadata(
        contentVersion:
            failures.isEmpty ? index.contentVersion : previous.contentVersion,
        lastAttemptAt: now,
        lastSuccessAt: failures.isEmpty ? now : previous.lastSuccessAt,
        lastOutcome: outcome,
        message: message,
        fileVersions: versions,
      );

      try {
        await _cache.saveMetadata(metadata);
      } on Object catch (error) {
        for (final kind in updated) {
          try {
            await _cache.discardVersion(kind, index.files[kind]!.version);
          } on Object {
            // Una copia sin activar es inocua y puede ser reemplazada después.
          }
          failures[kind] =
              'No se pudo activar la actualización: ${_readableError(error)}';
        }
        final failedMetadata = ContentCacheMetadata(
          contentVersion: previous.contentVersion,
          lastAttemptAt: now,
          lastSuccessAt: previous.lastSuccessAt,
          lastOutcome: ContentSyncOutcome.failed,
          message:
              'No fue posible guardar la actualización. Se mantiene la versión anterior.',
          fileVersions: previous.fileVersions,
        );
        await _trySaveMetadata(failedMetadata);
        return ContentSyncReport(
          metadata: failedMetadata,
          files: _buildResults(
            indexFiles: index.files,
            updated: const <ContentFileKind>{},
            unchanged: unchanged,
            failures: failures,
          ),
        );
      }

      final results = _buildResults(
        indexFiles: index.files,
        updated: updated,
        unchanged: unchanged,
        failures: failures,
      );

      return ContentSyncReport(metadata: metadata, files: results);
    } on Object {
      return _saveFailure(
        previous: previous,
        now: now,
        message:
            'No fue posible buscar actualizaciones. Se mantiene el contenido disponible en el dispositivo.',
      );
    }
  }

  Future<void> _validateQuestionChallengePair({
    required Map<ContentFileKind, Object> stagedParsed,
    required Map<ContentFileKind, String> stagedRaw,
    required Map<ContentFileKind, String> failures,
  }) async {
    List<Question> questions;
    List<DailyChallenge> challenges;

    try {
      final stagedQuestions = stagedParsed[ContentFileKind.questions];
      questions = stagedQuestions is List<Question>
          ? stagedQuestions
          : await _localLoader.load(
              kind: ContentFileKind.questions,
              fallbackAssetPath: 'content/preguntas/banco_global.json',
              parse: _documentParser.parseQuestions,
            );

      final stagedChallenges = stagedParsed[ContentFileKind.challenges];
      challenges = stagedChallenges is List<DailyChallenge>
          ? stagedChallenges
          : await _localLoader.load(
              kind: ContentFileKind.challenges,
              fallbackAssetPath: 'content/retos/retos_actuales.json',
              parse: _documentParser.parseChallenges,
            );
    } on Object catch (error) {
      final message = 'No fue posible validar la relación entre retos y preguntas: '
          '${_readableError(error)}';
      if (stagedRaw.containsKey(ContentFileKind.questions)) {
        failures[ContentFileKind.questions] = message;
      }
      if (stagedRaw.containsKey(ContentFileKind.challenges)) {
        failures[ContentFileKind.challenges] = message;
      }
      return;
    }

    final questionIds = questions.map((question) => question.id).toSet();
    final missing = <String>{};
    for (final challenge in challenges) {
      missing.addAll(
        challenge.questionIds.where((id) => !questionIds.contains(id)),
      );
    }

    final pendingAttempt = await _attemptRepository.load();
    final todayKey = localDateKey(_clock.now());
    if (pendingAttempt != null && pendingAttempt.dateKey == todayKey) {
      missing.addAll(
        pendingAttempt.questionIds.where((id) => !questionIds.contains(id)),
      );
    }
    if (missing.isEmpty) return;

    final sortedMissing = missing.toList()..sort();
    final message =
        'El contenido depende de preguntas inexistentes: ${sortedMissing.join(', ')}.';
    final questionsChanged = stagedRaw.containsKey(ContentFileKind.questions);
    final challengesChanged = stagedRaw.containsKey(ContentFileKind.challenges);

    if (questionsChanged) failures[ContentFileKind.questions] = message;
    if (challengesChanged) failures[ContentFileKind.challenges] = message;
  }

  List<ContentFileSyncResult> _buildResults({
    required Map<ContentFileKind, ContentFileDescriptor> indexFiles,
    required Set<ContentFileKind> updated,
    required Set<ContentFileKind> unchanged,
    required Map<ContentFileKind, String> failures,
  }) {
    final results = <ContentFileSyncResult>[];
    for (final kind in ContentFileKind.values) {
      final descriptor = indexFiles[kind]!;
      if (failures.containsKey(kind)) {
        results.add(ContentFileSyncResult(
          kind: kind,
          outcome: ContentFileSyncOutcome.failed,
          version: descriptor.version,
          message: failures[kind],
        ));
      } else if (updated.contains(kind)) {
        results.add(ContentFileSyncResult(
          kind: kind,
          outcome: ContentFileSyncOutcome.updated,
          version: descriptor.version,
        ));
      } else if (unchanged.contains(kind)) {
        results.add(ContentFileSyncResult(
          kind: kind,
          outcome: ContentFileSyncOutcome.unchanged,
          version: descriptor.version,
        ));
      }
    }
    return List.unmodifiable(results);
  }

  String _declaredVersion(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('El documento debe ser un objeto JSON.');
    }
    final version = decoded['version'];
    if (version is! String || version.trim().isEmpty) {
      throw const FormatException('El documento no declara una versión válida.');
    }
    return version.trim();
  }

  Object _parse(ContentFileKind kind, String raw) => switch (kind) {
        ContentFileKind.questions => _documentParser.parseQuestions(raw),
        ContentFileKind.challenges => _documentParser.parseChallenges(raw),
        ContentFileKind.resources => _documentParser.parseResources(raw),
        ContentFileKind.ranks => _documentParser.parseRanks(raw),
      };

  Uri _contentUri(ContentFileDescriptor descriptor) {
    final parsed = Uri.parse(descriptor.url);
    final resolved = parsed.hasScheme ? parsed : _baseUri.resolveUri(parsed);
    return _cacheBusted(resolved, descriptor.version);
  }

  Uri _cacheBusted(Uri uri, String value) {
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'ma_version': value,
      },
    );
  }

  Future<ContentSyncReport> _saveFailure({
    required ContentCacheMetadata previous,
    required DateTime now,
    required String message,
  }) async {
    final metadata = ContentCacheMetadata(
      contentVersion: previous.contentVersion,
      lastAttemptAt: now,
      lastSuccessAt: previous.lastSuccessAt,
      lastOutcome: ContentSyncOutcome.failed,
      message: message,
      fileVersions: previous.fileVersions,
    );
    await _trySaveMetadata(metadata);
    return ContentSyncReport(metadata: metadata);
  }

  Future<void> _trySaveMetadata(ContentCacheMetadata metadata) async {
    try {
      await _cache.saveMetadata(metadata);
    } on Object {
      // La aplicación debe seguir usando el contenido local aunque el navegador
      // rechace una escritura por cuota o modo privado.
    }
  }

  String _readableError(Object error) {
    final value = error.toString().trim();
    const prefixes = ['Exception: ', 'FormatException: ', 'Bad state: '];
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) return value.substring(prefix.length);
    }
    return value;
  }

  static Uri _directoryUri(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.resolve('.');
  }
}
