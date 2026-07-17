import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/features/notifications/application/notification_controller.dart';
import 'package:mision_admision/platform/notifications/notification_service.dart';

class NotificationReminderCard extends ConsumerStatefulWidget {
  const NotificationReminderCard({super.key});

  @override
  ConsumerState<NotificationReminderCard> createState() =>
      _NotificationReminderCardState();
}

class _NotificationReminderCardState
    extends ConsumerState<NotificationReminderCard> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotificationController(
      service: ref.read(notificationServiceProvider),
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

  Future<void> _enable() async {
    try {
      await _controller.enable();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible activar: $error')),
      );
    }
  }

  Future<void> _refreshRegistration() async {
    await _controller.refreshRegistration();
    if (!mounted) return;
    final status = _controller.status;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status.registrationAvailable
              ? 'Notificaciones reparadas y registro confirmado.'
              : 'No fue posible confirmar el registro.',
        ),
      ),
    );
  }

  Future<void> _disable() async {
    await _controller.disable();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificaciones desactivadas en este navegador.'),
      ),
    );
  }

  Future<void> _copyTestingId() async {
    final installationId = await _controller.getTestingInstallationId();
    if (!mounted) return;
    if (installationId == null || installationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un ID de prueba disponible.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: installationId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID de prueba copiado. No lo publiques ni lo compartas.'),
      ),
    );
  }

  Future<void> _test() async {
    final shown = await _controller.showLocalTest();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? 'Notificación de prueba enviada.'
              : 'No fue posible mostrar la notificación de prueba.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LinearProgressIndicator(),
        ),
      );
    }

    final status = _controller.status;
    final presentation = _presentation(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: presentation.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(presentation.icon, color: presentation.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        presentation.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.registrationAvailable) ...[
              const SizedBox(height: 12),
              Text(
                _registrationSummary(status),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            if (status.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                status.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (status.configured && status.supported) ...[
              const SizedBox(height: 16),
              if (status.enabled)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _controller.busy ? null : _test,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Probar'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _controller.busy ? null : _refreshRegistration,
                      icon: const Icon(Icons.build_outlined),
                      label: const Text('Reparar notificaciones'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _controller.busy ? null : _copyTestingId,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar ID de prueba'),
                    ),
                    TextButton(
                      onPressed: _controller.busy ? null : _disable,
                      child: const Text('Desactivar'),
                    ),
                  ],
                )
              else if (status.canEnable)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _controller.busy ? null : _enable,
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Activar notificaciones'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _registrationSummary(NotificationStatus status) {
    final kind = switch (status.registrationKind) {
      NotificationRegistrationKind.firebaseInstallationId => 'Registro FID',
      NotificationRegistrationKind.none => 'Sin registro',
    };
    final updated = status.registrationUpdatedAt?.toLocal();
    if (updated == null) return '$kind confirmado.';
    String two(int value) => value.toString().padLeft(2, '0');
    return '$kind actualizado ${updated.year}-${two(updated.month)}-'
        '${two(updated.day)} ${two(updated.hour)}:${two(updated.minute)}.';
  }

  _ReminderPresentation _presentation(NotificationStatus status) {
    if (!status.configured) {
      return const _ReminderPresentation(
        icon: Icons.notifications_none_outlined,
        color: Colors.blueGrey,
        title: 'Notificaciones',
        message:
            'Firebase Cloud Messaging todavía no está configurado por el administrador.',
      );
    }
    if (!status.secureContext) {
      return const _ReminderPresentation(
        icon: Icons.lock_outline,
        color: Colors.orange,
        title: 'Se necesita una conexión segura',
        message:
            'Las notificaciones solo funcionan mediante HTTPS o durante desarrollo local.',
      );
    }
    if (status.requiresPwaInstallation) {
      return const _ReminderPresentation(
        icon: Icons.install_mobile_outlined,
        color: Colors.blue,
        title: 'Instala la aplicación en iPhone',
        message:
            'En Safari pulsa Compartir → Agregar a pantalla de inicio. Después abre Misión Admisión desde su icono y activa el recordatorio.',
      );
    }
    if (!status.supported) {
      return const _ReminderPresentation(
        icon: Icons.notifications_off_outlined,
        color: Colors.orange,
        title: 'Notificaciones no compatibles',
        message:
            'Este navegador no permite recibir recordatorios web en segundo plano.',
      );
    }
    if (status.permission == NotificationPermissionState.denied) {
      return const _ReminderPresentation(
        icon: Icons.notifications_off_outlined,
        color: Colors.orange,
        title: 'Notificaciones bloqueadas',
        message:
            'Habilita las notificaciones desde la configuración del navegador para volver a activarlas.',
      );
    }
    if (status.enabled) {
      return const _ReminderPresentation(
        icon: Icons.notifications_active_outlined,
        color: Colors.green,
        title: 'Notificaciones activadas',
        message:
            'Este navegador está listo para recibir los mensajes que Misión Admisión envíe desde Firebase Console.',
      );
    }
    return const _ReminderPresentation(
      icon: Icons.notifications_outlined,
      color: Colors.blue,
      title: 'Mantente al día',
      message:
          'Activa las notificaciones para recibir recordatorios y avisos enviados por Misión Admisión.',
    );
  }
}

class _ReminderPresentation {
  const _ReminderPresentation({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
}
