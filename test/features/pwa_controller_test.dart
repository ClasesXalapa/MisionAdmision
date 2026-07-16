import 'package:flutter_test/flutter_test.dart';
import 'package:mision_admision/features/pwa/application/pwa_controller.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

void main() {
  test('loads the current PWA status', () async {
    final service = _FakePwaService(
      status: const PwaStatus(
        online: false,
        installMode: PwaInstallMode.installed,
        workerState: PwaWorkerState.active,
        updateAvailable: false,
      ),
    );
    final controller = PwaController(
      service: service,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);

    await controller.start();

    expect(controller.loading, isFalse);
    expect(controller.status.online, isFalse);
    expect(controller.status.offlineReady, isTrue);
    expect(service.readCount, 1);
  });

  test('requests installation only when the prompt is available', () async {
    final service = _FakePwaService(
      status: const PwaStatus(
        online: true,
        installMode: PwaInstallMode.prompt,
        workerState: PwaWorkerState.active,
        updateAvailable: false,
      ),
      installResult: true,
    );
    final controller = PwaController(
      service: service,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);
    await controller.start();

    final installed = await controller.install();

    expect(installed, isTrue);
    expect(service.installCount, 1);
  });

  test('activates a waiting service worker update', () async {
    final service = _FakePwaService(
      status: const PwaStatus(
        online: true,
        installMode: PwaInstallMode.installed,
        workerState: PwaWorkerState.waiting,
        updateAvailable: true,
      ),
      updateResult: true,
    );
    final controller = PwaController(
      service: service,
      pollInterval: const Duration(days: 1),
    );
    addTearDown(controller.dispose);
    await controller.start();

    final activated = await controller.activateUpdate();

    expect(activated, isTrue);
    expect(service.updateCount, 1);
  });
}

class _FakePwaService implements PwaService {
  _FakePwaService({
    required this.status,
    this.installResult = false,
    this.updateResult = false,
  });

  PwaStatus status;
  final bool installResult;
  final bool updateResult;
  int readCount = 0;
  int installCount = 0;
  int updateCount = 0;

  @override
  Future<bool> activateUpdate() async {
    updateCount += 1;
    return updateResult;
  }

  @override
  Future<PwaStatus> readStatus() async {
    readCount += 1;
    return status;
  }

  @override
  Future<bool> requestInstall() async {
    installCount += 1;
    return installResult;
  }
}
