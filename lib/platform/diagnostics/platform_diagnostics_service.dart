class PlatformDiagnostics {
  const PlatformDiagnostics({
    required this.supported,
    required this.browserName,
    required this.browserVersion,
    required this.operatingSystem,
    required this.platform,
    required this.userAgent,
    required this.language,
    required this.timeZone,
    required this.screenWidth,
    required this.screenHeight,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.devicePixelRatio,
    required this.online,
    required this.secureContext,
    required this.cookiesEnabled,
    required this.displayMode,
    required this.serviceWorkerSupported,
    required this.serviceWorkerControlled,
    required this.serviceWorkerState,
    required this.storageEstimateSupported,
    required this.storageUsageBytes,
    required this.storageQuotaBytes,
    required this.persistentStorageSupported,
    required this.persistentStorageGranted,
    required this.connectionType,
    this.errorMessage,
  });

  const PlatformDiagnostics.unsupported({this.errorMessage})
      : supported = false,
        browserName = 'No disponible',
        browserVersion = '',
        operatingSystem = 'No disponible',
        platform = 'No disponible',
        userAgent = '',
        language = 'es-MX',
        timeZone = '',
        screenWidth = 0,
        screenHeight = 0,
        viewportWidth = 0,
        viewportHeight = 0,
        devicePixelRatio = 1,
        online = true,
        secureContext = false,
        cookiesEnabled = false,
        displayMode = 'browser',
        serviceWorkerSupported = false,
        serviceWorkerControlled = false,
        serviceWorkerState = 'unsupported',
        storageEstimateSupported = false,
        storageUsageBytes = null,
        storageQuotaBytes = null,
        persistentStorageSupported = false,
        persistentStorageGranted = null,
        connectionType = null;

  final bool supported;
  final String browserName;
  final String browserVersion;
  final String operatingSystem;
  final String platform;
  final String userAgent;
  final String language;
  final String timeZone;
  final int screenWidth;
  final int screenHeight;
  final int viewportWidth;
  final int viewportHeight;
  final double devicePixelRatio;
  final bool online;
  final bool secureContext;
  final bool cookiesEnabled;
  final String displayMode;
  final bool serviceWorkerSupported;
  final bool serviceWorkerControlled;
  final String serviceWorkerState;
  final bool storageEstimateSupported;
  final int? storageUsageBytes;
  final int? storageQuotaBytes;
  final bool persistentStorageSupported;
  final bool? persistentStorageGranted;
  final String? connectionType;
  final String? errorMessage;

  factory PlatformDiagnostics.fromJson(Map<String, Object?> json) {
    return PlatformDiagnostics(
      supported: _bool(json['supported']),
      browserName: _text(json['browser_name'], fallback: 'Desconocido'),
      browserVersion: _text(json['browser_version']),
      operatingSystem: _text(
        json['operating_system'],
        fallback: 'Desconocido',
      ),
      platform: _text(json['platform'], fallback: 'Desconocido'),
      userAgent: _text(json['user_agent']),
      language: _text(json['language'], fallback: 'es-MX'),
      timeZone: _text(json['time_zone']),
      screenWidth: _integer(json['screen_width']),
      screenHeight: _integer(json['screen_height']),
      viewportWidth: _integer(json['viewport_width']),
      viewportHeight: _integer(json['viewport_height']),
      devicePixelRatio: _double(json['device_pixel_ratio'], fallback: 1),
      online: _bool(json['online'], fallback: true),
      secureContext: _bool(json['secure_context']),
      cookiesEnabled: _bool(json['cookies_enabled']),
      displayMode: _text(json['display_mode'], fallback: 'browser'),
      serviceWorkerSupported: _bool(json['service_worker_supported']),
      serviceWorkerControlled: _bool(json['service_worker_controlled']),
      serviceWorkerState: _text(
        json['service_worker_state'],
        fallback: 'unsupported',
      ),
      storageEstimateSupported: _bool(json['storage_estimate_supported']),
      storageUsageBytes: _nullableInteger(json['storage_usage_bytes']),
      storageQuotaBytes: _nullableInteger(json['storage_quota_bytes']),
      persistentStorageSupported: _bool(
        json['persistent_storage_supported'],
      ),
      persistentStorageGranted: _nullableBool(
        json['persistent_storage_granted'],
      ),
      connectionType: _nullableText(json['connection_type']),
      errorMessage: _nullableText(json['error_message']),
    );
  }

  Map<String, Object?> toJson() => {
        'supported': supported,
        'browser_name': browserName,
        'browser_version': browserVersion,
        'operating_system': operatingSystem,
        'platform': platform,
        'user_agent': userAgent,
        'language': language,
        'time_zone': timeZone,
        'screen_width': screenWidth,
        'screen_height': screenHeight,
        'viewport_width': viewportWidth,
        'viewport_height': viewportHeight,
        'device_pixel_ratio': devicePixelRatio,
        'online': online,
        'secure_context': secureContext,
        'cookies_enabled': cookiesEnabled,
        'display_mode': displayMode,
        'service_worker_supported': serviceWorkerSupported,
        'service_worker_controlled': serviceWorkerControlled,
        'service_worker_state': serviceWorkerState,
        'storage_estimate_supported': storageEstimateSupported,
        'storage_usage_bytes': storageUsageBytes,
        'storage_quota_bytes': storageQuotaBytes,
        'persistent_storage_supported': persistentStorageSupported,
        'persistent_storage_granted': persistentStorageGranted,
        'connection_type': connectionType,
        'error_message': errorMessage,
      };

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    return value is bool ? value : fallback;
  }

  static bool? _nullableBool(Object? value) => value is bool ? value : null;

  static int _integer(Object? value) => _nullableInteger(value) ?? 0;

  static int? _nullableInteger(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double _double(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

abstract interface class PlatformDiagnosticsService {
  Future<PlatformDiagnostics> read();
}
