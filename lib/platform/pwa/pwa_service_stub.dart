import 'package:mision_admision/platform/pwa/pwa_service.dart';

PwaService createPwaService() => const UnsupportedPwaService();

class UnsupportedPwaService implements PwaService {
  const UnsupportedPwaService();

  @override
  Future<bool> activateUpdate() async => false;

  @override
  Future<PwaStatus> readStatus() async => const PwaStatus.unsupported();

  @override
  Future<bool> requestInstall() async => false;
}
