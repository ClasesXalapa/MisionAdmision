import 'package:mision_admision/platform/notifications/notification_service.dart';

NotificationService createPlatformNotificationService() =>
    const UnsupportedNotificationService();

class UnsupportedNotificationService implements NotificationService {
  const UnsupportedNotificationService();

  @override
  Future<NotificationStatus> disable() async =>
      const NotificationStatus.unsupported();

  @override
  Future<NotificationStatus> enable() async =>
      const NotificationStatus.unsupported();

  @override
  Future<NotificationStatus> readStatus() async =>
      const NotificationStatus.unsupported();

  @override
  Future<NotificationStatus> refreshRegistration() async =>
      const NotificationStatus.unsupported();

  @override
  Future<bool> showLocalTest() async => false;

  @override
  Future<String?> getTestingInstallationId() async => null;
}
