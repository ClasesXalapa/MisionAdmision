enum NotificationPermissionState {
  unsupported,
  defaultState,
  denied,
  granted,
}

class NotificationStatus {
  const NotificationStatus({
    required this.configured,
    required this.supported,
    required this.permission,
    required this.enabled,
    required this.registrationAvailable,
    this.errorMessage,
  });

  const NotificationStatus.unsupported()
      : configured = false,
        supported = false,
        permission = NotificationPermissionState.unsupported,
        enabled = false,
        registrationAvailable = false,
        errorMessage = null;

  final bool configured;
  final bool supported;
  final NotificationPermissionState permission;
  final bool enabled;
  final bool registrationAvailable;
  final String? errorMessage;

  bool get canEnable =>
      configured && supported && permission != NotificationPermissionState.denied;
}

abstract interface class NotificationService {
  Future<NotificationStatus> readStatus();

  Future<NotificationStatus> enable();

  Future<NotificationStatus> disable();

  Future<bool> showLocalTest();
}
