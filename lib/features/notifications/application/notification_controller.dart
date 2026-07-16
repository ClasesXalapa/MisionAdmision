import 'package:flutter/foundation.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({required NotificationService service})
      : _service = service;

  final NotificationService _service;

  NotificationStatus _status = const NotificationStatus.unsupported();
  NotificationStatus get status => _status;

  bool _loading = true;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  Future<void> start() async {
    _status = await _service.readStatus();
    _loading = false;
    notifyListeners();
  }

  Future<void> enable() async {
    if (_busy) return;
    _setBusy(true);
    try {
      _status = await _service.enable();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> disable() async {
    if (_busy) return;
    _setBusy(true);
    try {
      _status = await _service.disable();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> showLocalTest() async {
    if (_busy) return false;
    _setBusy(true);
    try {
      return await _service.showLocalTest();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
