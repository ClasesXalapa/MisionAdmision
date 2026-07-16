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
}
