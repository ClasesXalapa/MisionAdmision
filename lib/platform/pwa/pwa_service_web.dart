import 'dart:js_interop';

import 'package:mision_admision/platform/pwa/pwa_service.dart';

PwaService createPwaService() => const WebPwaService();

class WebPwaService implements PwaService {
  const WebPwaService();

  @override
  Future<PwaStatus> readStatus() async {
    try {
      final value = await _readPwaState().toDart;
      return PwaStatus(
        online: value.online.toDart,
        installMode: _parseInstallMode(value.installMode.toDart),
        workerState: _parseWorkerState(value.workerState.toDart),
        updateAvailable: value.updateAvailable.toDart,
        errorMessage: _nullableString(value.errorMessage),
      );
    } on Object catch (error) {
      return PwaStatus(
        online: true,
        installMode: PwaInstallMode.unavailable,
        workerState: PwaWorkerState.error,
        updateAvailable: false,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<bool> requestInstall() async {
    try {
      final result = await _requestPwaInstall().toDart;
      return result.toDart;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> activateUpdate() async {
    try {
      final result = await _activatePwaUpdate().toDart;
      return result.toDart;
    } on Object {
      return false;
    }
  }

  PwaInstallMode _parseInstallMode(String value) {
    return switch (value) {
      'prompt' => PwaInstallMode.prompt,
      'manual' => PwaInstallMode.manual,
      'installed' => PwaInstallMode.installed,
      _ => PwaInstallMode.unavailable,
    };
  }

  PwaWorkerState _parseWorkerState(String value) {
    return switch (value) {
      'registering' => PwaWorkerState.registering,
      'active' => PwaWorkerState.active,
      'waiting' => PwaWorkerState.waiting,
      'error' => PwaWorkerState.error,
      _ => PwaWorkerState.unsupported,
    };
  }

  String? _nullableString(JSString? value) {
    if (value == null) return null;
    final result = value.toDart.trim();
    return result.isEmpty ? null : result;
  }
}

@JS('missionAdmissionPwa.getState')
external JSPromise<_JsPwaStatus> _readPwaState();

@JS('missionAdmissionPwa.requestInstall')
external JSPromise<JSBoolean> _requestPwaInstall();

@JS('missionAdmissionPwa.activateUpdate')
external JSPromise<JSBoolean> _activatePwaUpdate();

@JS()
extension type _JsPwaStatus._(JSObject _) implements JSObject {
  external JSBoolean get online;
  external JSString get installMode;
  external JSString get workerState;
  external JSBoolean get updateAvailable;
  external JSString? get errorMessage;
}
