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

  test('enables and disables reminders', () async {
    final service = _FakeNotificationService();
    final controller = NotificationController(service: service);
    addTearDown(controller.dispose);
    await controller.start();

    await controller.enable();
    expect(controller.status.enabled, isTrue);
    expect(service.enableCount, 1);

    await controller.disable();
    expect(controller.status.enabled, isFalse);
    expect(service.disableCount, 1);
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
  );

  int readCount = 0;
  int enableCount = 0;
  int disableCount = 0;
  int testCount = 0;

  @override
  Future<NotificationStatus> readStatus() async {
    readCount += 1;
    return status;
  }

  @override
  Future<NotificationStatus> enable() async {
    enableCount += 1;
    status = const NotificationStatus(
      configured: true,
      supported: true,
      permission: NotificationPermissionState.granted,
      enabled: true,
      registrationAvailable: true,
    );
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
    );
    return status;
  }

  @override
  Future<bool> showLocalTest() async {
    testCount += 1;
    return true;
  }
}
