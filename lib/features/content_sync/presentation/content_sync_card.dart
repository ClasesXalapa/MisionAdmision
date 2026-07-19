import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/responsive.dart';
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
    final colors = Theme.of(context).colorScheme;
    final responsive = context.responsive;

    return Card(
      key: const Key('settings_content_card'),
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
                  child: _syncing
                      ? Padding(
                          padding: EdgeInsets.all(responsive.compactGap * 1.4),
                          child: CircularProgressIndicator(
                            strokeWidth: responsive.progressThickness * 0.5,
                          ),
                        )
                      : Icon(
                          presentation.icon,
                          color: presentation.color,
                          size: responsive.iconSize * 1.08,
                        ),
                ),
                SizedBox(width: responsive.itemGap),
                Expanded(
                  child: Text(
                    _syncing ? 'Buscando contenido nuevo' : presentation.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.itemGap),
            Text(
              _syncing
                  ? 'Puedes seguir usando la aplicación mientras termina la revisión.'
                  : presentation.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            if (!_syncing && metadata?.lastSuccessAt != null) ...[
              SizedBox(height: responsive.itemGap),
              Container(
                width: double.infinity,
                padding: responsive.symmetricInsets(
                  horizontalFraction: 0.03,
                  verticalFraction: 0.022,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(responsive.smallRadius),
                ),
                child: Text(
                  'Última actualización válida: ${_formatDate(metadata!.lastSuccessAt!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            SizedBox(height: responsive.itemGap),
            SizedBox(
              width: double.infinity,
              height: responsive.controlHeight,
              child: OutlinedButton.icon(
                onPressed: _syncing
                    ? null
                    : () => _synchronize(force: true, showFeedback: true),
                icon: Icon(
                  _syncing ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                  size: responsive.iconSize,
                ),
                label: Text(
                  _syncing ? 'Revisando contenido…' : 'Buscar actualizaciones',
                ),
                style: OutlinedButton.styleFrom(
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
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
