import 'dart:js_interop';

import 'package:mision_admision/platform/notifications/notification_service.dart';

NotificationService createPlatformNotificationService() =>
    const WebNotificationService();

class WebNotificationService implements NotificationService {
  const WebNotificationService();

  @override
  Future<NotificationStatus> readStatus() async {
    try {
      return _mapStatus(await _getNotificationState().toDart);
    } catch (error) {
      return NotificationStatus(
        configured: false,
        supported: false,
        permission: NotificationPermissionState.unsupported,
        enabled: false,
        registrationAvailable: false,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<NotificationStatus> enable() async {
    return _mapStatus(await _enableNotifications().toDart);
  }

  @override
  Future<NotificationStatus> disable() async {
    return _mapStatus(await _disableNotifications().toDart);
  }

  @override
  Future<bool> showLocalTest() async =>
      (await _showLocalNotificationTest().toDart).toDart;

  NotificationStatus _mapStatus(_NotificationState value) {
    return NotificationStatus(
      configured: value.configured.toDart,
      supported: value.supported.toDart,
      permission: _permission(value.permission.toDart),
      enabled: value.enabled.toDart,
      registrationAvailable: value.registrationAvailable.toDart,
      errorMessage: _optionalText(value.errorMessage),
    );
  }

  NotificationPermissionState _permission(String value) {
    return switch (value) {
      'granted' => NotificationPermissionState.granted,
      'denied' => NotificationPermissionState.denied,
      'default' => NotificationPermissionState.defaultState,
      _ => NotificationPermissionState.unsupported,
    };
  }

  String? _optionalText(JSString? value) {
    if (value == null) return null;
    final text = value.toDart.trim();
    return text.isEmpty ? null : text;
  }
}

@JS('missionAdmissionNotifications.getState')
external JSPromise<_NotificationState> _getNotificationState();

@JS('missionAdmissionNotifications.enable')
external JSPromise<_NotificationState> _enableNotifications();

@JS('missionAdmissionNotifications.disable')
external JSPromise<_NotificationState> _disableNotifications();

@JS('missionAdmissionNotifications.showLocalTest')
external JSPromise<JSBoolean> _showLocalNotificationTest();

@JS()
extension type _NotificationState._(JSObject _) implements JSObject {
  external JSBoolean get configured;
  external JSBoolean get supported;
  external JSString get permission;
  external JSBoolean get enabled;
  external JSBoolean get registrationAvailable;
  external JSString? get errorMessage;
}
