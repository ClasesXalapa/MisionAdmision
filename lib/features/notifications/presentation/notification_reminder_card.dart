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
  bool _showTechnicalTools = false;

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
        key: Key('settings_notification_card'),
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 190,
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: LinearProgressIndicator()),
          ),
        ),
      );
    }

    final status = _controller.status;
    final presentation = _presentation(status);
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: const Key('settings_notification_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: presentation.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.color,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 34,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        presentation.message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 23,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.registrationAvailable) ...[
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _registrationSummary(status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
            if (status.errorMessage != null) ...[
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.errorMessage!,
                  style: TextStyle(
                    color: colors.onErrorContainer,
                    fontSize: 21,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (status.configured && status.supported) ...[
              const SizedBox(height: 28),
              if (status.enabled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 76,
                      child: OutlinedButton.icon(
                        onPressed: _controller.busy
                            ? null
                            : () => setState(
                                  () => _showTechnicalTools =
                                      !_showTechnicalTools,
                                ),
                        icon: Icon(
                          _showTechnicalTools
                              ? Icons.expand_less_rounded
                              : Icons.build_outlined,
                          size: 32,
                        ),
                        label: const Text('Herramientas técnicas'),
                        style: OutlinedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    if (_showTechnicalTools) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed: _controller.busy ? null : _test,
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 30,
                          ),
                          label: const Text('Enviar prueba local'),
                          style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed:
                              _controller.busy ? null : _refreshRegistration,
                          icon: const Icon(Icons.build_outlined, size: 30),
                          label: const Text('Reparar notificaciones'),
                          style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 70,
                        child: OutlinedButton.icon(
                          onPressed:
                              _controller.busy ? null : _copyTestingId,
                          icon: const Icon(Icons.copy_outlined, size: 30),
                          label: const Text('Copiar ID de prueba'),
                          style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      child: TextButton(
                        onPressed: _controller.busy ? null : _disable,
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: const Text('Desactivar notificaciones'),
                      ),
                    ),
                  ],
                )
              else if (status.canEnable)
                SizedBox(
                  width: double.infinity,
                  height: 76,
                  child: FilledButton.icon(
                    onPressed: _controller.busy ? null : _enable,
                    icon: const Icon(Icons.notifications_outlined, size: 34),
                    label: const Text('Activar notificaciones'),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
