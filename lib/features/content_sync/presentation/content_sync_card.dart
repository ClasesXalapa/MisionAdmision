import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/domain/models/content_cache_metadata.dart';
import 'package:mision_admision/domain/models/content_sync_report.dart';
import 'package:mision_admision/features/content_sync/application/content_sync_providers.dart';
import 'package:mision_admision/features/progress/application/progress_providers.dart';

class ContentSyncCard extends ConsumerStatefulWidget {
  const ContentSyncCard({super.key});

  @override
  ConsumerState<ContentSyncCard> createState() => _ContentSyncCardState();
}

class _ContentSyncCardState extends ConsumerState<ContentSyncCard> {
  bool _syncing = false;
  ContentSyncReport? _lastReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSync());
  }

  Future<void> _autoSync() async {
    try {
      final metadata =
          await ref.read(contentCacheRepositoryProvider).loadMetadata();
      final lastAttempt = metadata.lastAttemptAt;
      final now = ref.read(appClockProvider).now();
      if (lastAttempt != null &&
          now.difference(lastAttempt).inMinutes.abs() < 30) {
        return;
      }
    } on Object {
      // Si el navegador no permite leer preferencias, se intenta la descarga
      // igualmente y la aplicación conserva sus assets incluidos.
    }
    await _synchronize(force: false, showFeedback: false);
  }

  Future<void> _synchronize({
    required bool force,
    required bool showFeedback,
  }) async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final report =
          await ref.read(contentSyncServiceProvider).synchronize(force: force);
      if (!mounted) return;

      setState(() {
        _syncing = false;
        _lastReport = report;
      });
      ref
        ..invalidate(contentCacheMetadataProvider)
        ..invalidate(rankCatalogProvider);

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              report.metadata.message ?? 'Revisión terminada.',
            ),
          ),
        );
      }
    } on Object {
      if (!mounted) return;
      setState(() => _syncing = false);
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No fue posible revisar el contenido. La copia local sigue disponible.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(contentCacheMetadataProvider);
    final metadata = _lastReport?.metadata ?? metadataAsync.asData?.value;
    final presentation = _presentation(metadata);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: presentation.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _syncing
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(presentation.icon, color: presentation.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _syncing ? 'Buscando contenido nuevo' : presentation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _syncing
                        ? 'Puedes seguir usando la aplicación mientras termina.'
                        : presentation.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  if (!_syncing && metadata?.lastSuccessAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Última actualización válida: ${_formatDate(metadata!.lastSuccessAt!)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Actualizar contenido',
              onPressed: _syncing
                  ? null
                  : () => _synchronize(force: true, showFeedback: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  _SyncPresentation _presentation(ContentCacheMetadata? metadata) {
    if (metadata == null || metadata.lastOutcome == ContentSyncOutcome.never) {
      return const _SyncPresentation(
        icon: Icons.cloud_download_outlined,
        color: Colors.blueGrey,
        title: 'Contenido local disponible',
        message: 'La aplicación funciona con el contenido incluido y buscará actualizaciones cuando haya conexión.',
      );
    }

    return switch (metadata.lastOutcome) {
      ContentSyncOutcome.success => _SyncPresentation(
          icon: Icons.cloud_done_outlined,
          color: Colors.green,
          title: 'Contenido al día',
          message: metadata.message ?? 'La última revisión terminó correctamente.',
        ),
      ContentSyncOutcome.partial => _SyncPresentation(
          icon: Icons.cloud_sync_outlined,
          color: Colors.orange,
          title: 'Actualización parcial',
          message: metadata.message ?? 'Se conservaron las copias válidas.',
        ),
      ContentSyncOutcome.failed => _SyncPresentation(
          icon: Icons.cloud_off_outlined,
          color: Colors.redAccent,
          title: 'Sin conexión con el contenido',
          message: metadata.message ?? 'Se mantiene la última versión disponible.',
        ),
      ContentSyncOutcome.never => throw StateError('Estado ya procesado.'),
    };
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _SyncPresentation {
  const _SyncPresentation({
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
