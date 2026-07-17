enum NotificationPermissionState {
  unsupported,
  defaultState,
  denied,
  granted,
}

enum NotificationRegistrationKind {
  none,
  firebaseInstallationId,
}

enum FirebaseAnalyticsState {
  notConfigured,
  loading,
  active,
  unsupported,
  unavailable,
}

class NotificationStatus {
  const NotificationStatus({
    required this.configured,
    required this.supported,
    required this.permission,
    required this.enabled,
    required this.registrationAvailable,
    this.registrationKind = NotificationRegistrationKind.none,
    this.registrationUpdatedAt,
    this.secureContext = true,
    this.installedAsPwa = false,
    this.requiresPwaInstallation = false,
    this.analyticsConfigured = false,
    this.analyticsState = FirebaseAnalyticsState.notConfigured,
    this.analyticsErrorMessage,
    this.smartReminderSupported = false,
    this.smartReminderStateInitialized = false,
    this.smartReminderLastCompletedDateKey,
    this.smartReminderChallengeAvailable = false,
    this.smartReminderStateUpdatedAt,
    this.smartReminderLastFirebaseReceivedAt,
    this.smartReminderLastLocalAt,
    this.smartReminderCountDateKey,
    this.smartReminderCountForDate = 0,
    this.smartReminderLastDecision,
    this.smartReminderLastDecisionAt,
    this.smartReminderErrorMessage,
    this.errorCode,
    this.errorMessage,
  });

  const NotificationStatus.unsupported()
      : configured = false,
        supported = false,
        permission = NotificationPermissionState.unsupported,
        enabled = false,
        registrationAvailable = false,
        registrationKind = NotificationRegistrationKind.none,
        registrationUpdatedAt = null,
        secureContext = false,
        installedAsPwa = false,
        requiresPwaInstallation = false,
        analyticsConfigured = false,
        analyticsState = FirebaseAnalyticsState.notConfigured,
        analyticsErrorMessage = null,
        smartReminderSupported = false,
        smartReminderStateInitialized = false,
        smartReminderLastCompletedDateKey = null,
        smartReminderChallengeAvailable = false,
        smartReminderStateUpdatedAt = null,
        smartReminderLastFirebaseReceivedAt = null,
        smartReminderLastLocalAt = null,
        smartReminderCountDateKey = null,
        smartReminderCountForDate = 0,
        smartReminderLastDecision = null,
        smartReminderLastDecisionAt = null,
        smartReminderErrorMessage = null,
        errorCode = null,
        errorMessage = null;

  final bool configured;
  final bool supported;
  final NotificationPermissionState permission;
  final bool enabled;
  final bool registrationAvailable;
  final NotificationRegistrationKind registrationKind;
  final DateTime? registrationUpdatedAt;
  final bool secureContext;
  final bool installedAsPwa;
  final bool requiresPwaInstallation;
  final bool analyticsConfigured;
  final FirebaseAnalyticsState analyticsState;
  final String? analyticsErrorMessage;
  final bool smartReminderSupported;
  final bool smartReminderStateInitialized;
  final String? smartReminderLastCompletedDateKey;
  final bool smartReminderChallengeAvailable;
  final DateTime? smartReminderStateUpdatedAt;
  final DateTime? smartReminderLastFirebaseReceivedAt;
  final DateTime? smartReminderLastLocalAt;
  final String? smartReminderCountDateKey;
  final int smartReminderCountForDate;
  final String? smartReminderLastDecision;
  final DateTime? smartReminderLastDecisionAt;
  final String? smartReminderErrorMessage;
  final String? errorCode;
  final String? errorMessage;

  bool get canEnable =>
      configured &&
      supported &&
      secureContext &&
      !requiresPwaInstallation &&
      permission != NotificationPermissionState.denied;
}

abstract interface class NotificationService {
  Future<NotificationStatus> readStatus();

  Future<NotificationStatus> enable();

  Future<NotificationStatus> refreshRegistration();

  Future<NotificationStatus> disable();

  Future<bool> showLocalTest();

  /// Refleja en IndexedDB solo la fecha mínima necesaria para que el service
  /// worker determine si el reto diario sigue pendiente.
  Future<bool> syncDailyChallengeState({
    required String? lastCompletedDateKey,
    required bool challengeAvailable,
  });

  /// Identificador técnico para dirigir un mensaje de prueba desde Firebase
  /// Console. Nunca debe incluirse en reportes generales de diagnóstico.
  Future<String?> getTestingInstallationId();
}
