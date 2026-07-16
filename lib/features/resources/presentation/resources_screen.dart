import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/models/resource_type.dart';
import 'package:mision_admision/features/resources/application/resource_controller.dart';
import 'package:mision_admision/features/resources/application/resource_state.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  late final ResourceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResourceController(
      resourceRepository: ref.read(resourceRepositoryProvider),
      trackingRepository: ref.read(resourceTrackingRepositoryProvider),
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

  Future<void> _open(ResourceCard resource) async {
    await _controller.markViewed(resource.id);
    final opened = await launchUrl(
      resource.url,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el recurso.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver al inicio',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Recursos'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: switch (state.phase) {
              ResourcePhase.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              ResourcePhase.failure => _ResourceError(
                  message: state.errorMessage ?? 'Ocurrió un error.',
                  onRetry: _controller.start,
                ),
              ResourcePhase.ready => _ResourceContent(
                  state: state,
                  onTypeSelected: _controller.selectType,
                  onTagSelected: _controller.selectTag,
                  onOpen: _open,
                  onToggleCompleted: _controller.toggleCompleted,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _ResourceContent extends StatelessWidget {
  const _ResourceContent({
    required this.state,
    required this.onTypeSelected,
    required this.onTagSelected,
    required this.onOpen,
    required this.onToggleCompleted,
  });

  final ResourceState state;
  final ValueChanged<ResourceType?> onTypeSelected;
  final ValueChanged<String?> onTagSelected;
  final ValueChanged<ResourceCard> onOpen;
  final ValueChanged<String> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final resources = state.filteredResources;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Biblioteca de estudio',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Filtra el contenido, abre el recurso original y marca lo que ya terminaste.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        _Filters(
          state: state,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        const SizedBox(height: 20),
        Text(
          '${resources.length} ${resources.length == 1 ? 'recurso' : 'recursos'}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map((resource) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ResourceTile(
                  resource: resource,
                  viewed: state.tracking.isViewed(resource.id),
                  completed: state.tracking.isCompleted(resource.id),
                  onOpen: () => onOpen(resource),
                  onToggleCompleted: () => onToggleCompleted(resource.id),
                ),
              )),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.state,
    required this.onTypeSelected,
    required this.onTagSelected,
  });

  final ResourceState state;
  final ValueChanged<ResourceType?> onTypeSelected;
  final ValueChanged<String?> onTagSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: state.selectedType == null,
                  onSelected: (_) => onTypeSelected(null),
                ),
                ...ResourceType.values.map((type) => FilterChip(
                      label: Text(type.label),
                      selected: state.selectedType == type,
                      onSelected: (_) => onTypeSelected(type),
                    )),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: state.selectedTag ?? '__all__',
              decoration: const InputDecoration(
                labelText: 'Materia o etiqueta',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '__all__',
                  child: Text('Todas las etiquetas'),
                ),
                ...state.availableTags.map((tag) => DropdownMenuItem<String>(
                      value: tag,
                      child: Text(_readableTag(tag)),
                    )),
              ],
              onChanged: (value) =>
                  onTagSelected(value == '__all__' ? null : value),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.resource,
    required this.viewed,
    required this.completed,
    required this.onOpen,
    required this.onToggleCompleted,
  });

  final ResourceCard resource;
  final bool viewed;
  final bool completed;
  final VoidCallback onOpen;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    resource.imageUrl.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      alignment: Alignment.center,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 42),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconFor(resource.type)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(resource.type.label),
                    ],
                  ),
                ),
                if (completed)
                  const Tooltip(
                    message: 'Completado',
                    child: Icon(Icons.check_circle, color: Colors.green),
                  )
                else if (viewed)
                  const Tooltip(
                    message: 'Visto',
                    child: Icon(Icons.visibility_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(resource.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: resource.tags
                  .map((tag) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(_readableTag(tag)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir recurso'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: completed ? 'Marcar como pendiente' : 'Marcar hecho',
                  onPressed: onToggleCompleted,
                  icon: Icon(completed ? Icons.undo : Icons.task_alt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceError extends StatelessWidget {
  const _ResourceError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyResources extends StatelessWidget {
  const _EmptyResources();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No hay recursos con estos filtros.')),
      ),
    );
  }
}

IconData _iconFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => Icons.play_circle_outline,
    ResourceType.pdf => Icons.picture_as_pdf_outlined,
    ResourceType.form => Icons.list_alt_outlined,
    ResourceType.simulator => Icons.quiz_outlined,
    ResourceType.post => Icons.article_outlined,
    ResourceType.announcement => Icons.campaign_outlined,
  };
}

String _readableTag(String tag) {
  if (tag.isEmpty) return tag;
  final words = tag.split('-');
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
