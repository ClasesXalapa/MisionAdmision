import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_file_kind.dart';
import 'package:mision_admision/domain/models/support_diagnostics.dart';
import 'package:mision_admision/features/support/application/diagnostics_controller.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

class HelpDiagnosticsScreen extends ConsumerStatefulWidget {
  const HelpDiagnosticsScreen({super.key});

  @override
  ConsumerState<HelpDiagnosticsScreen> createState() =>
      _HelpDiagnosticsScreenState();
}

class _HelpDiagnosticsScreenState
    extends ConsumerState<HelpDiagnosticsScreen> {
  late final DiagnosticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiagnosticsController(
      diagnosticsService: ref.read(supportDiagnosticsServiceProvider),
      fileService: ref.read(backupFileServiceProvider),
    )..addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
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

  Future<void> _copyReport() async {
    final copied = await _controller.copyReport();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          copied
              ? 'Diagnóstico copiado. Puedes pegarlo en tu reporte.'
              : 'No fue posible copiar el diagnóstico.',
        ),
      ),
    );
  }

  Future<void> _downloadReport() async {
    final downloaded = await _controller.downloadReport();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Diagnóstico descargado en formato JSON.'
              : 'No fue posible descargar el diagnóstico.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _controller.report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y diagnóstico'),
        actions: [
          IconButton(
            tooltip: 'Actualizar diagnóstico',
            onPressed: _controller.busy
                ? null
                : () {
                    _controller.refresh();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _controller.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const _HelpIntroCard(),
                      const SizedBox(height: 16),
                      if (_controller.errorMessage != null)
                        _ErrorCard(message: _controller.errorMessage!),
                      if (_controller.errorMessage != null)
                        const SizedBox(height: 16),
                      if (report != null) ...[
                        _StatusOverview(report: report),
                        const SizedBox(height: 16),
                        _ApplicationDeviceCard(report: report),
                        const SizedBox(height: 16),
                        _PwaStorageCard(report: report),
                        const SizedBox(height: 16),
                        _ContentNotificationsCard(report: report),
                        const SizedBox(height: 16),
                        _LocalDataCard(report: report),
                        const SizedBox(height: 16),
                        _ReportActions(
                          busy: _controller.busy,
                          onCopy: _copyReport,
                          onDownload: _downloadReport,
                          onRefresh: () {
                            _controller.refresh();
                          },
                        ),
                        const SizedBox(height: 16),
                        _TechnicalReportCard(report: report),
                      ],
                      const SizedBox(height: 16),
                      const _ReportIssueCard(),
                      const SizedBox(height: 16),
                      const _PrivacyCard(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _HelpIntroCard extends StatelessWidget {
  const _HelpIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Centro de ayuda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí puedes revisar el estado técnico de Misión Admisión y crear un reporte útil cuando encuentres un problema.',
            ),
            const SizedBox(height: 16),
            const _HelpPoint(
              icon: Icons.quiz_outlined,
              text: 'Los exámenes libres no modifican tu racha.',
            ),
            const _HelpPoint(
              icon: Icons.local_fire_department_outlined,
              text: 'El reto diario debe completarse antes de terminar el día.',
            ),
            const _HelpPoint(
              icon: Icons.save_outlined,
              text: 'Tu progreso vive únicamente en este navegador y dispositivo.',
            ),
            const _HelpPoint(
              icon: Icons.cloud_off_outlined,
              text: 'Los recursos externos requieren internet, aunque la PWA esté preparada para uso offline.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpPoint extends StatelessWidget {
  const _HelpPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(
                  label: report.platform.online ? 'En línea' : 'Sin conexión',
                  icon: report.platform.online
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  positive: report.platform.online,
                ),
                _StatusChip(
                  label: report.pwa.offlineReady
                      ? 'Offline preparado'
                      : 'Offline pendiente',
                  icon: Icons.offline_bolt_outlined,
                  positive: report.pwa.offlineReady,
                ),
                _StatusChip(
                  label: report.pwa.isInstalled
                      ? 'PWA instalada'
                      : 'Uso en navegador',
                  icon: report.pwa.isInstalled
                      ? Icons.install_mobile_outlined
                      : Icons.language_outlined,
                  positive: report.pwa.isInstalled,
                ),
                _StatusChip(
                  label: report.notifications.enabled
                      ? 'Recordatorio activo'
                      : 'Recordatorio inactivo',
                  icon: report.notifications.enabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  positive: report.notifications.enabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.positive,
  });

  final String label;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green : Colors.blueGrey;
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}

class _ApplicationDeviceCard extends StatelessWidget {
  const _ApplicationDeviceCard({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    final platform = report.platform;
    final browser = platform.browserVersion.isEmpty
        ? platform.browserName
        : '${platform.browserName} ${platform.browserVersion}';
    return _DetailsCard(
      title: 'Aplicación y dispositivo',
      icon: Icons.devices_outlined,
      rows: [
        ('Versión', '${report.appVersion}+${report.appBuildNumber}'),
        ('Navegador', browser),
        ('Sistema', platform.operatingSystem),
        ('Plataforma', platform.platform),
        ('Idioma', platform.language),
        ('Zona horaria', platform.timeZone),
        ('Pantalla', '${platform.screenWidth} × ${platform.screenHeight}'),
        ('Área visible', '${platform.viewportWidth} × ${platform.viewportHeight}'),
        ('Escala de píxeles', platform.devicePixelRatio.toStringAsFixed(2)),
        ('Conexión aproximada', platform.connectionType ?? 'No disponible'),
        ('HTTPS seguro', platform.secureContext ? 'Sí' : 'No'),
      ],
    );
  }
}

class _PwaStorageCard extends StatelessWidget {
  const _PwaStorageCard({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    final platform = report.platform;
    return _DetailsCard(
      title: 'PWA y almacenamiento',
      icon: Icons.offline_bolt_outlined,
      rows: [
        ('Modo de apertura', _installModeLabel(report.pwa.installMode)),
        ('Service worker', _workerLabel(report.pwa.workerState)),
        ('Controlando la página', platform.serviceWorkerControlled ? 'Sí' : 'No'),
        ('Modo offline', report.pwa.offlineReady ? 'Preparado' : 'No preparado'),
        ('Actualización disponible', report.pwa.updateAvailable ? 'Sí' : 'No'),
        ('Espacio utilizado', _formatBytes(platform.storageUsageBytes)),
        ('Cuota disponible', _formatBytes(platform.storageQuotaBytes)),
        (
          'Almacenamiento persistente',
          _optionalBool(platform.persistentStorageGranted),
        ),
        ('Cookies habilitadas', platform.cookiesEnabled ? 'Sí' : 'No'),
      ],
    );
  }
}

class _ContentNotificationsCard extends StatelessWidget {
  const _ContentNotificationsCard({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: 'Contenido y notificaciones',
      icon: Icons.sync_outlined,
      rows: [
        ('Versión de contenido', report.content.contentVersion ?? 'Contenido inicial'),
        (
          'Preguntas',
          report.content.versionFor(ContentFileKind.questions) ?? 'Incluidas',
        ),
        (
          'Retos',
          report.content.versionFor(ContentFileKind.challenges) ?? 'Incluidos',
        ),
        (
          'Recursos',
          report.content.versionFor(ContentFileKind.resources) ?? 'Incluidos',
        ),
        (
          'Rangos',
          report.content.versionFor(ContentFileKind.ranks) ?? 'Incluidos',
        ),
        ('Última sincronización', _formatDate(report.content.lastSuccessAt)),
        ('Resultado', _syncOutcomeLabel(report.content.lastOutcome)),
        ('Firebase configurado', report.notifications.configured ? 'Sí' : 'No'),
        ('Navegador compatible', report.notifications.supported ? 'Sí' : 'No'),
        ('Permiso', _permissionLabel(report.notifications.permission)),
        ('Recordatorio activado', report.notifications.enabled ? 'Sí' : 'No'),
        (
          'Tipo de registro',
          _registrationKindLabel(report.notifications.registrationKind),
        ),
        (
          'Registro actualizado',
          _formatDate(report.notifications.registrationUpdatedAt),
        ),
        (
          'Instalación PWA requerida',
          report.notifications.requiresPwaInstallation ? 'Sí' : 'No',
        ),
      ],
    );
  }
}

class _LocalDataCard extends StatelessWidget {
  const _LocalDataCard({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      title: 'Resumen local',
      icon: Icons.lock_outline,
      rows: [
        ('Racha actual', '${report.progress.currentStreak}'),
        ('Mejor racha', '${report.progress.bestStreak}'),
        ('Escudos', '${report.progress.shields}'),
        (
          'Retos completados',
          '${report.progress.totalDailyChallengesCompleted}',
        ),
        (
          'Reto pendiente',
          report.pendingAttempt == null
              ? 'No'
              : 'Sí, ${report.pendingAttempt!.dateKey}',
        ),
        (
          'Respuestas guardadas en el intento',
          '${report.pendingAttempt?.answers.length ?? 0}',
        ),
      ],
      footer:
          'Este resumen ayuda a detectar pérdida de progreso. El reporte no incluye cuáles respuestas seleccionaste.',
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final row in rows) _DetailRow(label: row.$1, value: row.$2),
            if (footer != null) ...[
              const SizedBox(height: 12),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: SelectableText(value.isEmpty ? 'No disponible' : value)),
        ],
      ),
    );
  }
}

class _ReportActions extends StatelessWidget {
  const _ReportActions({
    required this.busy,
    required this.onCopy,
    required this.onDownload,
    required this.onRefresh,
  });

  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onDownload;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compartir diagnóstico',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Actualiza el reporte justo después de reproducir un error y adjúntalo junto con una captura de pantalla.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: busy ? null : onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar reporte'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Descargar JSON'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalReportCard extends StatelessWidget {
  const _TechnicalReportCard({required this.report});

  final SupportDiagnostics report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.code_outlined),
        title: const Text('Ver reporte técnico'),
        subtitle: const Text('Texto listo para copiar en un reporte de error.'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                report.toPlainText(),
                style: const TextStyle(fontFamily: 'monospace', height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportIssueCard extends StatelessWidget {
  const _ReportIssueCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cómo reportar un problema',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Incluye estos datos para que el problema pueda reproducirse:',
            ),
            const SizedBox(height: 12),
            const SelectableText(
              'Pantalla:\n'
              'Qué hiciste:\n'
              'Qué esperabas:\n'
              'Qué ocurrió:\n'
              '¿Se repite al recargar?:\n'
              'Captura o video:\n'
              'Diagnóstico técnico:',
              style: TextStyle(fontFamily: 'monospace', height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'El diagnóstico no contiene tu nombre, correo, respuestas seleccionadas ni el identificador privado usado por las notificaciones. Revisa el texto antes de compartirlo.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int? bytes) {
  if (bytes == null) return 'No disponible';
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
  return '${(megabytes / 1024).toStringAsFixed(1)} GB';
}

String _formatDate(DateTime? value) {
  if (value == null) return 'Nunca';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _optionalBool(bool? value) {
  if (value == null) return 'No disponible';
  return value ? 'Sí' : 'No';
}

String _installModeLabel(PwaInstallMode value) => switch (value) {
      PwaInstallMode.installed => 'Aplicación instalada',
      PwaInstallMode.prompt => 'Instalación disponible',
      PwaInstallMode.manual => 'Instalación manual',
      PwaInstallMode.unavailable => 'Navegador',
    };

String _workerLabel(PwaWorkerState value) => switch (value) {
      PwaWorkerState.active => 'Activo',
      PwaWorkerState.waiting => 'Actualización en espera',
      PwaWorkerState.registering => 'Registrando',
      PwaWorkerState.error => 'Error',
      PwaWorkerState.unsupported => 'No compatible',
    };

String _permissionLabel(NotificationPermissionState value) => switch (value) {
      NotificationPermissionState.granted => 'Concedido',
      NotificationPermissionState.denied => 'Bloqueado',
      NotificationPermissionState.defaultState => 'No solicitado',
      NotificationPermissionState.unsupported => 'No compatible',
    };


String _registrationKindLabel(NotificationRegistrationKind value) =>
    switch (value) {
      NotificationRegistrationKind.firebaseInstallationId =>
        'Firebase Installation ID',
      NotificationRegistrationKind.none => 'Sin registro',
    };

String _syncOutcomeLabel(ContentSyncOutcome value) => switch (value) {
      ContentSyncOutcome.never => 'Sin sincronizar',
      ContentSyncOutcome.success => 'Correcto',
      ContentSyncOutcome.partial => 'Parcial',
      ContentSyncOutcome.failed => 'Fallido',
    };
