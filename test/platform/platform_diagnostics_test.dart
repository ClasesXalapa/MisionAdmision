import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/platform/diagnostics/platform_diagnostics_service.dart';

void main() {
  test('parses browser diagnostics returned by the web bridge', () {
    final value = PlatformDiagnostics.fromJson({
      'supported': true,
      'browser_name': 'Chrome',
      'browser_version': '150.0',
      'operating_system': 'Android 16',
      'platform': 'Android',
      'user_agent': 'test-agent',
      'language': 'es-MX',
      'time_zone': 'America/Mexico_City',
      'screen_width': 390,
      'screen_height': 844,
      'viewport_width': 390,
      'viewport_height': 700,
      'device_pixel_ratio': 3,
      'online': false,
      'secure_context': true,
      'cookies_enabled': true,
      'display_mode': 'standalone',
      'service_worker_supported': true,
      'service_worker_controlled': true,
      'service_worker_state': 'activated',
      'storage_estimate_supported': true,
      'storage_usage_bytes': 1024,
      'storage_quota_bytes': 2048,
      'persistent_storage_supported': true,
      'persistent_storage_granted': false,
      'connection_type': '4g',
      'error_message': '',
    });

    expect(value.supported, isTrue);
    expect(value.browserName, 'Chrome');
    expect(value.screenWidth, 390);
    expect(value.online, isFalse);
    expect(value.storageUsageBytes, 1024);
    expect(value.persistentStorageGranted, isFalse);
    expect(value.errorMessage, isNull);
  });
}
