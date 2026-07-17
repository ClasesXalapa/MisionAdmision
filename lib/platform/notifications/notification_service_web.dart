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
        secureContext: false,
        errorCode: 'bridge-unavailable',
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<NotificationStatus> enable() async {
    return _mapStatus(await _enableNotifications().toDart);
  }

  @override
  Future<NotificationStatus> refreshRegistration() async {
    return _mapStatus(await _refreshNotificationRegistration().toDart);
  }

  @override
  Future<NotificationStatus> disable() async {
    return _mapStatus(await _disableNotifications().toDart);
  }

  @override
  Future<bool> showLocalTest() async =>
      (await _showLocalNotificationTest().toDart).toDart;

  @override
  Future<bool> syncDailyChallengeState({
    required String? lastCompletedDateKey,
    required bool challengeAvailable,
  }) async {
    try {
      final result = await _syncDailyChallengeState(
        (lastCompletedDateKey ?? '').toJS,
        challengeAvailable.toJS,
      ).toDart;
      return result.toDart;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> getTestingInstallationId() async {
    final value = await _getTestingInstallationId().toDart;
    return _optionalText(value);
  }

  NotificationStatus _mapStatus(_NotificationState value) {
    return NotificationStatus(
      configured: value.configured.toDart,
      supported: value.supported.toDart,
      permission: _permission(value.permission.toDart),
      enabled: value.enabled.toDart,
      registrationAvailable: value.registrationAvailable.toDart,
      registrationKind: _registrationKind(value.registrationKind.toDart),
      registrationUpdatedAt: _optionalDate(value.registrationUpdatedAt),
      secureContext: value.secureContext.toDart,
      installedAsPwa: value.installedAsPwa.toDart,
      requiresPwaInstallation: value.requiresPwaInstallation.toDart,
      analyticsConfigured: value.analyticsConfigured.toDart,
      analyticsState: _analyticsState(value.analyticsState.toDart),
      analyticsErrorMessage: _optionalText(value.analyticsErrorMessage),
      smartReminderSupported: value.smartReminderSupported.toDart,
      smartReminderStateInitialized:
          value.smartReminderStateInitialized.toDart,
      smartReminderLastCompletedDateKey:
          _optionalText(value.smartReminderLastCompletedDateKey),
      smartReminderChallengeAvailable:
          value.smartReminderChallengeAvailable.toDart,
      smartReminderStateUpdatedAt:
          _optionalDate(value.smartReminderStateUpdatedAt),
      smartReminderLastFirebaseReceivedAt:
          _optionalDate(value.smartReminderLastFirebaseReceivedAt),
      smartReminderLastLocalAt:
          _optionalDate(value.smartReminderLastLocalAt),
      smartReminderCountDateKey:
          _optionalText(value.smartReminderCountDateKey),
      smartReminderCountForDate: _optionalInt(value.smartReminderCountForDate),
      smartReminderLastDecision:
          _optionalText(value.smartReminderLastDecision),
      smartReminderLastDecisionAt:
          _optionalDate(value.smartReminderLastDecisionAt),
      smartReminderErrorMessage:
          _optionalText(value.smartReminderErrorMessage),
      errorCode: _optionalText(value.errorCode),
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

  NotificationRegistrationKind _registrationKind(String value) {
    return switch (value) {
      'fid' => NotificationRegistrationKind.firebaseInstallationId,
      _ => NotificationRegistrationKind.none,
    };
  }

  FirebaseAnalyticsState _analyticsState(String value) {
    return switch (value) {
      'loading' => FirebaseAnalyticsState.loading,
      'active' => FirebaseAnalyticsState.active,
      'unsupported' => FirebaseAnalyticsState.unsupported,
      'unavailable' => FirebaseAnalyticsState.unavailable,
      _ => FirebaseAnalyticsState.notConfigured,
    };
  }

  DateTime? _optionalDate(JSString? value) {
    final text = _optionalText(value);
    return text == null ? null : DateTime.tryParse(text);
  }

  int _optionalInt(JSString? value) {
    final text = _optionalText(value);
    return text == null ? 0 : int.tryParse(text) ?? 0;
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

@JS('missionAdmissionNotifications.refreshRegistration')
external JSPromise<_NotificationState> _refreshNotificationRegistration();

@JS('missionAdmissionNotifications.disable')
external JSPromise<_NotificationState> _disableNotifications();

@JS('missionAdmissionNotifications.showLocalTest')
external JSPromise<JSBoolean> _showLocalNotificationTest();

@JS('missionAdmissionNotifications.getTestingInstallationId')
external JSPromise<JSString> _getTestingInstallationId();

@JS('missionAdmissionNotifications.syncDailyChallengeState')
external JSPromise<JSBoolean> _syncDailyChallengeState(
  JSString lastCompletedDateKey,
  JSBoolean challengeAvailable,
);

@JS()
extension type _NotificationState._(JSObject _) implements JSObject {
  external JSBoolean get configured;
  external JSBoolean get supported;
  external JSString get permission;
  external JSBoolean get enabled;
  external JSBoolean get registrationAvailable;
  external JSString get registrationKind;
  external JSString get registrationUpdatedAt;
  external JSBoolean get secureContext;
  external JSBoolean get installedAsPwa;
  external JSBoolean get requiresPwaInstallation;
  external JSBoolean get analyticsConfigured;
  external JSString get analyticsState;
  external JSString? get analyticsErrorMessage;
  external JSBoolean get smartReminderSupported;
  external JSBoolean get smartReminderStateInitialized;
  external JSString? get smartReminderLastCompletedDateKey;
  external JSBoolean get smartReminderChallengeAvailable;
  external JSString? get smartReminderStateUpdatedAt;
  external JSString? get smartReminderLastFirebaseReceivedAt;
  external JSString? get smartReminderLastLocalAt;
  external JSString? get smartReminderCountDateKey;
  external JSString get smartReminderCountForDate;
  external JSString? get smartReminderLastDecision;
  external JSString? get smartReminderLastDecisionAt;
  external JSString? get smartReminderErrorMessage;
  external JSString? get errorCode;
  external JSString? get errorMessage;
}
