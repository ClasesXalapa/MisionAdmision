class PickedBackupFile {
  const PickedBackupFile({required this.name, required this.content});

  final String name;
  final String content;
}

abstract interface class BackupFileService {
  bool get supported;

  Future<void> downloadText({
    required String fileName,
    required String content,
  });

  Future<PickedBackupFile?> pickJsonFile({required int maximumBytes});
}
