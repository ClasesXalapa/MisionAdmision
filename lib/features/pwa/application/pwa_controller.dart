import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

class PwaController extends ChangeNotifier {
  PwaController({
    required PwaService service,
    this.pollInterval = const Duration(seconds: 5),
  }) : _service = service;

  final PwaService _service;
  final Duration pollInterval;

  PwaStatus _status = const PwaStatus.unsupported();
  PwaStatus get status => _status;

  bool _loading = true;
  bool get loading => _loading;

  bool _busy = false;
  bool get busy => _busy;

  Timer? _timer;
  bool _refreshing = false;

  Future<void> start() async {
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      _status = await _service.readStatus();
      _loading = false;
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> install() async {
    if (_busy || !_status.canPromptInstall) return false;
    _setBusy(true);
    try {
      final accepted = await _service.requestInstall();
      await refresh();
      return accepted;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> activateUpdate() async {
    if (_busy || !_status.updateAvailable) return false;
    _setBusy(true);
    try {
      final activated = await _service.activateUpdate();
      if (!activated) await refresh();
      return activated;
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
