import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/responsive.dart';
import 'package:mision_admision/domain/models/resource_card.dart';
import 'package:mision_admision/domain/models/resource_type.dart';
import 'package:mision_admision/features/navigation/presentation/app_bottom_navigation.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
    _searchController.dispose();
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Recursos')),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      body: SafeArea(
        child: fullWidthCentered(
          maxWidth: 960,
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
                  query: _query,
                  searchController: _searchController,
                  onSearchChanged: (value) => setState(() => _query = value),
                  onClearSearch: _clearSearch,
                  onTypeSelected: _controller.selectType,
                  onTagSelected: _controller.selectTag,
                  onOpen: _open,
                  onToggleCompleted: _controller.toggleCompleted,
                ),
          },
        ),
      ),
    );
  }
}

class _ResourceContent extends StatelessWidget {
  const _ResourceContent({
    required this.state,
    required this.query,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onTypeSelected,
    required this.onTagSelected,
    required this.onOpen,
    required this.onToggleCompleted,
  });

  final ResourceState state;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ResourceType?> onTypeSelected;
  final ValueChanged<String?> onTagSelected;
  final ValueChanged<ResourceCard> onOpen;
  final ValueChanged<String> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final resources = state.filteredResources.where((resource) {
      if (normalizedQuery.isEmpty) return true;
      final searchable = [
        resource.title,
        resource.description,
        resource.type.label,
        ...resource.tags,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList(growable: false);
    final horizontalPadding = appHorizontalPadding(context);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        14,
        horizontalPadding,
        28,
      ),
      children: [
        Text(
          'Biblioteca de estudio',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Encuentra el recurso correcto para reforzar cada tema.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        _Filters(
          state: state,
          searchController: searchController,
          hasSearch: normalizedQuery.isNotEmpty,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                '${resources.length} ${resources.length == 1 ? 'recurso' : 'recursos'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (state.selectedType != null ||
                state.selectedTag != null ||
                normalizedQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  onTypeSelected(null);
                  onTagSelected(null);
                  onClearSearch();
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ResourceTile(
                resource: resource,
                viewed: state.tracking.isViewed(resource.id),
                completed: state.tracking.isCompleted(resource.id),
                onOpen: () => onOpen(resource),
                onToggleCompleted: () => onToggleCompleted(resource.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.state,
    required this.searchController,
    required this.hasSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onTypeSelected,
    required this.onTagSelected,
  });

  final ResourceState state;
  final TextEditingController searchController;
  final bool hasSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
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
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por tema o recurso',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tipo de recurso',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: state.selectedType == null,
                    onSelected: (_) => onTypeSelected(null),
                  ),
                  for (final type in ResourceType.values) ...[
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: Icon(_iconFor(type), size: 19),
                      label: Text(type.label),
                      selected: state.selectedType == type,
                      onSelected: (_) => onTypeSelected(type),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(state.selectedTag ?? '__all__'),
              initialValue: state.selectedTag ?? '__all__',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Materia o etiqueta',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '__all__',
                  child: Text('Todas las etiquetas'),
                ),
                ...state.availableTags.map(
                  (tag) => DropdownMenuItem<String>(
                    value: tag,
                    child: Text(_readableTag(tag)),
                  ),
                ),
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resource.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 8.5,
              child: Image.network(
                resource.imageUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ResourceCover(type: resource.type),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResourceTypeIcon(type: resource.type),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.type.label.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            resource.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(completed: completed, viewed: viewed),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  resource.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                if (resource.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: resource.tags
                        .take(3)
                        .map(
                          (tag) => Chip(
                            label: Text(_readableTag(tag)),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 25),
                    label: const Text('Abrir recurso'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onToggleCompleted,
                    icon: Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                    ),
                    label: Text(
                      completed
                          ? 'Recurso completado'
                          : 'Marcar como completado',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceTypeIcon extends StatelessWidget {
  const _ResourceTypeIcon({required this.type});

  final ResourceType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Icon(_iconFor(type), size: 34, color: colors.primary),
    );
  }
}

class _ResourceCover extends StatelessWidget {
  const _ResourceCover({required this.type});

  final ResourceType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 112,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_iconFor(type), size: 34, color: colors.primary),
          ),
          const Spacer(),
          Icon(
            Icons.school_rounded,
            size: 54,
            color: colors.primary.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.completed, required this.viewed});

  final bool completed;
  final bool viewed;

  @override
  Widget build(BuildContext context) {
    if (!completed && !viewed) return const SizedBox.shrink();
    final background = completed
        ? const Color(0xFFE4F5E8)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = completed
        ? const Color(0xFF18733C)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.visibility_outlined,
            size: 17,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            completed ? 'Hecho' : 'Visto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 54),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No encontramos recursos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra búsqueda o limpia los filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => Icons.play_circle_outline_rounded,
    ResourceType.pdf => Icons.picture_as_pdf_outlined,
    ResourceType.form => Icons.list_alt_rounded,
    ResourceType.simulator => Icons.quiz_rounded,
    ResourceType.post => Icons.article_rounded,
    ResourceType.announcement => Icons.campaign_rounded,
  };
}

String _readableTag(String tag) {
  if (tag.isEmpty) return tag;
  final words = tag.split('-');
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
