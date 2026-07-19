import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/responsive.dart';
import 'package:mision_admision/features/pwa/application/pwa_controller.dart';
import 'package:mision_admision/platform/pwa/pwa_service.dart';

class PwaStatusCard extends ConsumerStatefulWidget {
  const PwaStatusCard({super.key});

  @override
  ConsumerState<PwaStatusCard> createState() => _PwaStatusCardState();
}

class _PwaStatusCardState extends ConsumerState<PwaStatusCard> {
  late final PwaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PwaController(service: ref.read(pwaServiceProvider))
      ..addListener(_refresh);
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

  Future<void> _install() async {
    final accepted = await _controller.install();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          accepted
              ? 'Instalación aceptada. Misión Admisión aparecerá como aplicación.'
              : 'La instalación no se completó. Puedes intentarlo de nuevo.',
        ),
      ),
    );
  }

  Future<void> _activateUpdate() async {
    final activated = await _controller.activateUpdate();
    if (!mounted || activated) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No fue posible activar la actualización todavía.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    if (_controller.loading) {
      return Card(
        key: const Key('settings_pwa_card'),
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: responsive.heightValue(0.12, minimum: 120, maximum: 190),
          child: Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: const Center(child: LinearProgressIndicator()),
          ),
        ),
      );
    }

    final status = _controller.status;
    final presentation = _presentation(status);
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: const Key('settings_pwa_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: responsive.iconBadgeSize * 1.08,
                  height: responsive.iconBadgeSize * 1.08,
                  decoration: BoxDecoration(
                    color: presentation.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(responsive.mediumRadius),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.color,
                    size: responsive.iconSize * 1.08,
                  ),
                ),
                SizedBox(width: responsive.itemGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: responsive.compactGap * 0.75),
                      Text(
                        presentation.message,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.needsManualInstall) ...[
              SizedBox(height: responsive.sectionGap * 0.72),
              const _ManualInstallInstructions(),
            ],
            if (status.canPromptInstall || status.updateAvailable) ...[
              SizedBox(height: responsive.itemGap),
              SizedBox(
                width: double.infinity,
                height: responsive.controlHeight,
                child: status.updateAvailable
                    ? FilledButton.icon(
                        onPressed: _controller.busy ? null : _activateUpdate,
                        icon: Icon(
                          Icons.system_update_alt,
                          size: responsive.iconSize,
                        ),
                        label: const Text('Aplicar actualización'),
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: _controller.busy ? null : _install,
                        icon: Icon(
                          Icons.install_mobile_outlined,
                          size: responsive.iconSize,
                        ),
                        label: const Text('Instalar Misión Admisión'),
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
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

  _PwaPresentation _presentation(PwaStatus status) {
    if (!status.online) {
      return _PwaPresentation(
        icon: Icons.cloud_off_outlined,
        color: Colors.orange,
        title: 'Estás usando Misión Admisión sin conexión',
        message: status.offlineReady
            ? 'El contenido guardado y las funciones principales siguen disponibles.'
            : 'Algunas funciones podrían necesitar una primera carga con internet.',
      );
    }

    if (status.updateAvailable || status.workerState == PwaWorkerState.waiting) {
      return const _PwaPresentation(
        icon: Icons.system_update_alt,
        color: Colors.indigo,
        title: 'Nueva versión preparada',
        message: 'Puedes aplicarla ahora. El progreso local no se eliminará.',
      );
    }

    if (status.workerState == PwaWorkerState.error) {
      return _PwaPresentation(
        icon: Icons.warning_amber_rounded,
        color: Colors.redAccent,
        title: 'Modo offline no disponible',
        message: status.errorMessage ??
            'La aplicación continúa funcionando mientras haya conexión.',
      );
    }

    if (status.isInstalled) {
      return const _PwaPresentation(
        icon: Icons.verified_outlined,
        color: Colors.green,
        title: 'Aplicación instalada',
        message:
            'Puedes abrirla desde tu pantalla de inicio y usar el contenido guardado sin conexión.',
      );
    }

    if (status.canPromptInstall) {
      return const _PwaPresentation(
        icon: Icons.install_mobile_outlined,
        color: Colors.blue,
        title: 'Instala Misión Admisión',
        message:
            'Agrégala como aplicación para abrirla más rápido y mejorar la experiencia offline.',
      );
    }

    if (status.needsManualInstall) {
      return const _PwaPresentation(
        icon: Icons.add_to_home_screen_outlined,
        color: Colors.blue,
        title: 'Agrégala a tu pantalla de inicio',
        message:
            'En iPhone o iPad la instalación se realiza desde el menú Compartir de Safari.',
      );
    }

    if (status.offlineReady) {
      return const _PwaPresentation(
        icon: Icons.offline_bolt_outlined,
        color: Colors.green,
        title: 'Modo offline preparado',
        message:
            'Después de esta primera carga podrás volver a abrir la aplicación aunque pierdas la conexión.',
      );
    }

    if (status.workerState == PwaWorkerState.registering) {
      return const _PwaPresentation(
        icon: Icons.downloading_outlined,
        color: Colors.blueGrey,
        title: 'Preparando uso sin conexión',
        message:
            'La aplicación está guardando los archivos esenciales en este dispositivo.',
      );
    }

    return const _PwaPresentation(
      icon: Icons.language_outlined,
      color: Colors.blueGrey,
      title: 'Disponible desde el navegador',
      message:
          'Puedes usar Misión Admisión normalmente. La instalación depende de las funciones de tu navegador.',
    );
  }
}

class _ManualInstallInstructions extends StatelessWidget {
  const _ManualInstallInstructions();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(responsive.largeRadius),
      ),
      child: Text(
        '1. Abre esta página en Safari.\n'
        '2. Pulsa Compartir.\n'
        '3. Elige “Agregar a pantalla de inicio”.\n'
        '4. Abre Misión Admisión desde su nuevo icono.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PwaPresentation {
  const _PwaPresentation({
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
