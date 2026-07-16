enum PwaInstallMode {
  unavailable,
  prompt,
  manual,
  installed,
}

enum PwaWorkerState {
  unsupported,
  registering,
  active,
  waiting,
  error,
}

class PwaStatus {
  const PwaStatus({
    required this.online,
    required this.installMode,
    required this.workerState,
    required this.updateAvailable,
    this.errorMessage,
  });

  const PwaStatus.unsupported()
      : online = true,
        installMode = PwaInstallMode.unavailable,
        workerState = PwaWorkerState.unsupported,
        updateAvailable = false,
        errorMessage = null;

  final bool online;
  final PwaInstallMode installMode;
  final PwaWorkerState workerState;
  final bool updateAvailable;
  final String? errorMessage;

  bool get isInstalled => installMode == PwaInstallMode.installed;

  bool get canPromptInstall => installMode == PwaInstallMode.prompt;

  bool get needsManualInstall => installMode == PwaInstallMode.manual;

  bool get offlineReady =>
      workerState == PwaWorkerState.active ||
      workerState == PwaWorkerState.waiting;
}

abstract interface class PwaService {
  Future<PwaStatus> readStatus();

  Future<bool> requestInstall();

  Future<bool> activateUpdate();
}
