import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/features/backup/application/backup_controller.dart';
import 'package:mision_admision/features/progress/application/progress_providers.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState
    extends ConsumerState<DataManagementScreen> {
  late final BackupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BackupController(
      backupService: ref.read(progressBackupServiceProvider),
      fileService: ref.read(backupFileServiceProvider),
    )..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    try {
      final fileName = await _controller.exportBackup();
      if (!mounted) return;
      _showMessage('Respaldo descargado: $fileName');
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage('No fue posible exportar el progreso: $error');
    }
  }

  Future<void> _import() async {
    try {
      final selection = await _controller.selectBackup();
      if (!mounted || selection == null) return;
      final confirmed = await _confirmImport(selection);
      if (!mounted || !confirmed) return;
      final result = await _controller.restore(selection.backup);
      _invalidateProgress();
      if (!mounted) return;
      final details = result.staleAttemptDiscarded
          ? ' El reto pendiente del respaldo ya había vencido y no se restauró.'
          : result.attemptRestored
              ? ' También se restauró el reto pendiente de hoy.'
              : '';
      _showMessage('Progreso restaurado correctamente.$details');
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage('No fue posible importar el respaldo: $error');
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Borrar el progreso local?'),
            content: const Text(
              'Se reiniciarán la racha, los escudos, el reto pendiente y las marcas de recursos de este navegador. El contenido educativo y las notificaciones no se eliminarán.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Borrar progreso'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await _controller.reset();
      _invalidateProgress();
      if (!mounted) return;
      _showMessage('El progreso local se reinició correctamente.');
    } on Object catch (error) {
      if (!mounted) return;
      _showMessage('No fue posible reiniciar el progreso: $error');
    }
  }

  Future<bool> _confirmImport(BackupSelection selection) async {
    final backup = selection.backup;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selection.fileName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _BackupMetric(
                label: 'Racha actual',
                value: '${backup.progress.currentStreak}',
              ),
              _BackupMetric(
                label: 'Mejor racha',
                value: '${backup.progress.bestStreak}',
              ),
              _BackupMetric(
                label: 'Escudos',
                value: '${backup.progress.shields}',
              ),
              _BackupMetric(
                label: 'Recursos completados',
                value: '${backup.tracking.completedIds.length}',
              ),
              _BackupMetric(
                label: 'Reto pendiente',
                value: backup.dailyAttempt == null ? 'No' : 'Sí',
              ),
              const SizedBox(height: 14),
              const Text(
                'La importación reemplazará el progreso que está guardado actualmente en este navegador.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _invalidateProgress() {
    ref
      ..invalidate(learnerProgressProvider)
      ..invalidate(pendingDailyAttemptProvider);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver al inicio',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Datos y respaldo'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Conserva tu progreso',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu información vive únicamente en este navegador. Descarga un respaldo para moverla a otro dispositivo o recuperarla si borras los datos del sitio.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 24),
                _DataActionCard(
                  icon: Icons.download_outlined,
                  title: 'Exportar progreso',
                  description:
                      'Descarga un archivo JSON con tu racha, escudos, reto pendiente y recursos marcados.',
                  buttonLabel: 'Descargar respaldo',
                  onPressed: _controller.supported && !_controller.busy
                      ? _export
                      : null,
                ),
                const SizedBox(height: 16),
                _DataActionCard(
                  icon: Icons.upload_file_outlined,
                  title: 'Importar progreso',
                  description:
                      'Selecciona un respaldo creado por Misión Admisión. El archivo se valida antes de modificar tus datos.',
                  buttonLabel: 'Seleccionar respaldo',
                  onPressed: _controller.supported && !_controller.busy
                      ? _import
                      : null,
                ),
                const SizedBox(height: 16),
                _DataActionCard(
                  icon: Icons.restart_alt,
                  title: 'Reiniciar progreso',
                  description:
                      'Borra solamente tu avance local. Las preguntas, cards y configuración descargadas permanecen disponibles.',
                  buttonLabel: 'Borrar progreso local',
                  danger: true,
                  onPressed: _controller.busy ? null : _reset,
                ),
                if (!_controller.supported) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'La exportación e importación de archivos todavía no está disponible en esta plataforma.',
                      ),
                    ),
                  ),
                ],
                if (_controller.busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 16),
                const _PrivacyNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DataActionCard extends StatelessWidget {
  const _DataActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: danger
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                      ),
                      onPressed: onPressed,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(buttonLabel),
                    )
                  : FilledButton.icon(
                      onPressed: onPressed,
                      icon: Icon(icon),
                      label: Text(buttonLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupMetric extends StatelessWidget {
  const _BackupMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'El respaldo no incluye tokens de notificaciones, archivos de caché, datos de Firebase ni información personal como nombre o correo.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
