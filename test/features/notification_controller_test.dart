import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/features/notifications/application/notification_controller.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';

void main() {
  test('loads notification status', () async {
    final service = _FakeNotificationService();
    final controller = NotificationController(service: service);
    addTearDown(controller.dispose);

    await controller.start();

    expect(controller.loading, isFalse);
    expect(controller.status.configured, isTrue);
    expect(controller.status.enabled, isFalse);
    expect(service.readCount, 1);
  });

  test('enables, refreshes and disables reminders', () async {
    final service = _FakeNotificationService();
    final controller = NotificationController(service: service);
    addTearDown(controller.dispose);
    await controller.start();

    await controller.enable();
    expect(controller.status.enabled, isTrue);
    expect(controller.status.registrationKind,
        NotificationRegistrationKind.firebaseInstallationId);
    expect(service.enableCount, 1);

    await controller.refreshRegistration();
    expect(controller.status.registrationAvailable, isTrue);
    expect(service.refreshCount, 1);

    await controller.disable();
    expect(controller.status.enabled, isFalse);
    expect(service.disableCount, 1);
  });

  test('copies the testing installation id through the service', () async {
    final service = _FakeNotificationService();
    final controller = NotificationController(service: service);
    addTearDown(controller.dispose);
    await controller.start();
    await controller.enable();

    expect(await controller.getTestingInstallationId(), 'fid-test-123');
    expect(service.testingIdCount, 1);
  });

  test('delegates local notification test', () async {
    final service = _FakeNotificationService();
    final controller = NotificationController(service: service);
    addTearDown(controller.dispose);
    await controller.start();

    expect(await controller.showLocalTest(), isTrue);
    expect(service.testCount, 1);
  });
}

class _FakeNotificationService implements NotificationService {
  NotificationStatus status = const NotificationStatus(
    configured: true,
    supported: true,
    permission: NotificationPermissionState.defaultState,
    enabled: false,
    registrationAvailable: false,
    secureContext: true,
  );

  int readCount = 0;
  int enableCount = 0;
  int refreshCount = 0;
  int disableCount = 0;
  int testCount = 0;
  int testingIdCount = 0;

  @override
  Future<NotificationStatus> readStatus() async {
    readCount += 1;
    return status;
  }

  @override
  Future<NotificationStatus> enable() async {
    enableCount += 1;
    status = NotificationStatus(
      configured: true,
      supported: true,
      permission: NotificationPermissionState.granted,
      enabled: true,
      registrationAvailable: true,
      registrationKind: NotificationRegistrationKind.firebaseInstallationId,
      registrationUpdatedAt: DateTime.utc(2026, 7, 16),
      secureContext: true,
      installedAsPwa: true,
    );
    return status;
  }

  @override
  Future<NotificationStatus> refreshRegistration() async {
    refreshCount += 1;
    return status;
  }

  @override
  Future<NotificationStatus> disable() async {
    disableCount += 1;
    status = const NotificationStatus(
      configured: true,
      supported: true,
      permission: NotificationPermissionState.granted,
      enabled: false,
      registrationAvailable: false,
      secureContext: true,
    );
    return status;
  }

  @override
  Future<bool> showLocalTest() async {
    testCount += 1;
    return true;
  }

  @override
  Future<String?> getTestingInstallationId() async {
    testingIdCount += 1;
    return status.enabled ? 'fid-test-123' : null;
  }
}
