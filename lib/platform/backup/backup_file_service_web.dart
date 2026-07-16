import 'dart:js_interop';

import 'package:mision_admision/platform/backup/backup_file_service.dart';

BackupFileService createBackupFileService() => const WebBackupFileService();

class WebBackupFileService implements BackupFileService {
  const WebBackupFileService();

  @override
  bool get supported => true;

  @override
  Future<void> downloadText({
    required String fileName,
    required String content,
  }) async {
    final saved = await _downloadBackupText(fileName.toJS, content.toJS).toDart;
    if (!saved.toDart) {
      throw StateError('El navegador no pudo descargar el respaldo.');
    }
  }

  @override
  Future<PickedBackupFile?> pickJsonFile({required int maximumBytes}) async {
    final value = await _pickBackupJson(maximumBytes.toJS).toDart;
    final error = _optionalText(value.errorMessage);
    if (error != null) throw FormatException(error);
    if (value.cancelled.toDart) return null;
    final name = value.fileName.toDart.trim();
    final content = value.content.toDart;
    if (name.isEmpty || content.trim().isEmpty) {
      throw const FormatException('El archivo seleccionado está vacío.');
    }
    return PickedBackupFile(name: name, content: content);
  }

  String? _optionalText(JSString? value) {
    if (value == null) return null;
    final text = value.toDart.trim();
    return text.isEmpty ? null : text;
  }
}

@JS('missionAdmissionBackupFiles.downloadText')
external JSPromise<JSBoolean> _downloadBackupText(
  JSString fileName,
  JSString content,
);

@JS('missionAdmissionBackupFiles.pickJsonFile')
external JSPromise<_JsPickedBackup> _pickBackupJson(JSNumber maximumBytes);

@JS()
extension type _JsPickedBackup._(JSObject _) implements JSObject {
  external JSBoolean get cancelled;
  external JSString get fileName;
  external JSString get content;
  external JSString? get errorMessage;
}
