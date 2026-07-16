import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';

PlatformDiagnosticsService createPlatformDiagnosticsService() =>
    const UnsupportedPlatformDiagnosticsService();

class UnsupportedPlatformDiagnosticsService
    implements PlatformDiagnosticsService {
  const UnsupportedPlatformDiagnosticsService();

  @override
  Future<PlatformDiagnostics> read() async {
    return const PlatformDiagnostics.unsupported();
  }
}
