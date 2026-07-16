import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mision_admision/domain/models/support_diagnostics.dart';
import 'package:mision_admision/domain/services/support_diagnostics_service.dart';
import 'package:mision_admision/platform/backup/backup_file_service.dart';

class DiagnosticsController extends ChangeNotifier {
  DiagnosticsController({
    required SupportDiagnosticsService diagnosticsService,
    required BackupFileService fileService,
  })  : _diagnosticsService = diagnosticsService,
        _fileService = fileService;

  final SupportDiagnosticsService _diagnosticsService;
  final BackupFileService _fileService;

  SupportDiagnostics? _report;
  SupportDiagnostics? get report => _report;

  bool _loading = true;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    if (_busy) return;
    _setBusy(true);
    try {
      _report = await _diagnosticsService.collect();
      _errorMessage = null;
    } on Object catch (error) {
      _errorMessage = error.toString();
    } finally {
      _loading = false;
      _setBusy(false);
    }
  }

  Future<bool> copyReport() async {
    final current = _report;
    if (current == null || _busy) return false;
    _setBusy(true);
    try {
      await Clipboard.setData(ClipboardData(text: current.toPlainText()));
      return true;
    } on Object catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> downloadReport() async {
    final current = _report;
    if (current == null || _busy || !_fileService.supported) return false;
    _setBusy(true);
    try {
      final date = current.generatedAt.toIso8601String().split('T').first;
      await _fileService.downloadText(
        fileName: 'mision-admision-diagnostico-$date.json',
        content: current.toPrettyJson(),
      );
      return true;
    } on Object catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
