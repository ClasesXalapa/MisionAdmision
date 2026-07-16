import 'dart:convert';
import 'dart:js_interop';

import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';

PlatformDiagnosticsService createPlatformDiagnosticsService() =>
    const WebPlatformDiagnosticsService();

class WebPlatformDiagnosticsService implements PlatformDiagnosticsService {
  const WebPlatformDiagnosticsService();

  @override
  Future<PlatformDiagnostics> read() async {
    try {
      final source = (await _readDiagnosticsJson().toDart).toDart;
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('El diagnóstico del navegador es inválido.');
      }
      return PlatformDiagnostics.fromJson(decoded);
    } on Object catch (error) {
      return PlatformDiagnostics.unsupported(errorMessage: error.toString());
    }
  }
}

@JS('missionAdmissionDiagnostics.getReportJson')
external JSPromise<JSString> _readDiagnosticsJson();
