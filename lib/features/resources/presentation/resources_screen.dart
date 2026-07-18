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
    final handset = isHandsetLayout(context);
    final horizontalPadding = handset ? 12.0 : 30.0;
    final filtersActive = state.selectedType != null ||
        state.selectedTag != null ||
        normalizedQuery.isNotEmpty;

    return ListView(
      key: const Key('resources_list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        handset ? 12 : 18,
        horizontalPadding,
        34,
      ),
      children: [
        Text(
          'Biblioteca de estudio',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: handset ? 35 : null,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Encuentra videos, guías y simulacros para reforzar cada tema.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: handset ? 19 : null,
              ),
        ),
        const SizedBox(height: 22),
        _Filters(
          state: state,
          searchController: searchController,
          hasSearch: normalizedQuery.isNotEmpty,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        const SizedBox(height: 26),
        _ResultsHeader(
          count: resources.length,
          filtersActive: filtersActive,
          onClear: () {
            onTypeSelected(null);
            onTagSelected(null);
            onClearSearch();
          },
        ),
        const SizedBox(height: 16),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ResourceTile(
                key: Key('resource_card_${resource.id}'),
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

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.filtersActive,
    required this.onClear,
  });

  final int count;
  final bool filtersActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countText = Text(
      '$count ${count == 1 ? 'recurso disponible' : 'recursos disponibles'}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: isHandsetLayout(context) ? 24 : null,
          ),
    );
    final clearButton = Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onClear,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            'Limpiar',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (filtersActive && constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              countText,
              const SizedBox(height: 10),
              clearButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: countText),
            if (filtersActive) ...[
              const SizedBox(width: 10),
              clearButton,
            ],
          ],
        );
      },
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
    final handset = isHandsetLayout(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(handset ? 18 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Busca un recurso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: handset ? 24 : null,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('resources_search_field'),
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Tema, materia o tipo de recurso',
                prefixIcon: const Icon(Icons.search_rounded, size: 30),
                suffixIcon: hasSearch
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Tipo de recurso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: handset ? 21 : null,
                  ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              key: const Key('resources_type_filters'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeFilterButton(
                    label: 'Todos',
                    icon: Icons.grid_view_rounded,
                    selected: state.selectedType == null,
                    onTap: () => onTypeSelected(null),
                  ),
                  for (final type in ResourceType.values) ...[
                    const SizedBox(width: 10),
                    _TypeFilterButton(
                      label: type.label,
                      icon: _iconFor(type),
                      selected: state.selectedType == type,
                      onTap: () => onTypeSelected(type),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Materia o etiqueta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: handset ? 21 : null,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(state.selectedTag ?? '__all__'),
              initialValue: state.selectedTag ?? '__all__',
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.sell_outlined, size: 28),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              items: [
                const DropdownMenuItem<String>(
                  value: '__all__',
                  child: Text('Todas las materias'),
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

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : const Color(0xFFD8DDE8),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontSize: 16.5,
                      ),
                ),
              ],
            ),
          ),
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
    super.key,
  });

  final ResourceCard resource;
  final bool viewed;
  final bool completed;
  final VoidCallback onOpen;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final handset = isHandsetLayout(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resource.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                resource.imageUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ResourceCover(type: resource.type),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(handset ? 20 : 24),
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
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                resource.type.label.toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                      fontSize: handset ? 15.5 : null,
                                    ),
                              ),
                              _StatusBadge(
                                completed: completed,
                                viewed: viewed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            resource.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: handset ? 27 : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  resource.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: handset ? 19 : null,
                      ),
                ),
                if (resource.tags.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: resource.tags
                        .take(3)
                        .map(
                          (tag) => _TagPill(label: _readableTag(tag)),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  key: Key('resource_open_${resource.id}'),
                  width: double.infinity,
                  height: handset ? 72 : 66,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 27),
                    label: Text(_openLabelFor(resource.type)),
                  ),
                ),
                const SizedBox(height: 12),
                _CompletionAction(
                  completed: completed,
                  onTap: onToggleCompleted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionAction extends StatelessWidget {
  const _CompletionAction({
    required this.completed,
    required this.onTap,
  });

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = completed
        ? const Color(0xFFE4F5E8)
        : colors.surfaceContainerLowest;
    final foreground =
        completed ? const Color(0xFF18733C) : colors.onSurfaceVariant;
    final border = completed
        ? const Color(0xFF9FD6AE)
        : const Color(0xFFD8DDE8);

    return Semantics(
      button: true,
      selected: completed,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 27,
                  color: foreground,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    completed ? 'Completado' : 'Marcar como completado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: 17.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DDE8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 15,
            ),
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(_iconFor(type), size: 42, color: colors.primary),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(_iconFor(type), size: 42, color: colors.primary),
          ),
          const Spacer(),
          Icon(
            Icons.school_rounded,
            size: 66,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.visibility_outlined,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            completed ? 'Completado' : 'Visto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos recursos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra búsqueda o limpia los filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

String _openLabelFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => 'Ver video',
    ResourceType.pdf => 'Abrir PDF',
    ResourceType.form => 'Abrir formulario',
    ResourceType.simulator => 'Abrir simulacro',
    ResourceType.post => 'Leer publicación',
    ResourceType.announcement => 'Ver anuncio',
  };
}

String _readableTag(String tag) {
  if (tag.isEmpty) return tag;
  final words = tag.split('-');
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
