import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mision_admision/app/dependencies.dart';
import 'package:mision_admision/app/design_system.dart';
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
      appBar: AppBar(
        title: const Text('Recursos'),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      body: SafeArea(
        child: fullWidthCentered(
          maxWidth: 820,
          child: switch (state.phase) {
            ResourcePhase.loading => const _ResourceLoading(),
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

    final filtersActive = state.selectedType != null ||
        state.selectedTag != null ||
        normalizedQuery.isNotEmpty;

    return ListView(
      key: const Key('resources_list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const _ResourcesHero(),
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
        const SizedBox(height: 22),
        _ResultsHeader(
          count: resources.length,
          filtersActive: filtersActive,
          onClear: () {
            onTypeSelected(null);
            onTagSelected(null);
            onClearSearch();
          },
        ),
        const SizedBox(height: 13),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
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

class _ResourcesHero extends StatelessWidget {
  const _ResourcesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppPalette.resourceGradient,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              Icons.auto_stories_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                const AppIconBadge(
                  icon: Icons.explore_rounded,
                  foreground: Color(0xFF087267),
                  background: Colors.white,
                  size: 58,
                  iconSize: 31,
                  radius: 18,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biblioteca de estudio',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Encuentra el recurso ideal para reforzar cada tema.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.84),
                            ),
                      ),
                    ],
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
      key: const Key('resources_filters_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('resources_search_field'),
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busca por tema, materia o tipo',
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
            SizedBox(
              height: 48,
              child: ListView(
                key: const Key('resources_type_filters'),
                scrollDirection: Axis.horizontal,
                children: [
                  _TypeFilterButton(
                    key: const Key('resource_type_filter_all'),
                    label: 'Todos',
                    icon: Icons.grid_view_rounded,
                    selected: state.selectedType == null,
                    onTap: () => onTypeSelected(null),
                  ),
                  const SizedBox(width: 8),
                  for (final type in ResourceType.values) ...[
                    _TypeFilterButton(
                      label: type.label,
                      icon: _iconFor(type),
                      selected: state.selectedType == type,
                      onTap: () => onTypeSelected(type),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(state.selectedTag ?? '__all__'),
              initialValue: state.selectedTag ?? '__all__',
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              decoration: const InputDecoration(
                labelText: 'Materia o etiqueta',
                prefixIcon: Icon(Icons.sell_outlined),
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
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primary : colors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colors.primary : AppPalette.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          selected ? colors.onPrimary : colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
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
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'recurso' : 'recursos'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (filtersActive)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
            label: const Text('Limpiar'),
          ),
      ],
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
    final accent = _accentFor(resource.type);
    final accentSoft = _softAccentFor(resource.type);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (resource.imageUrl != null)
            SizedBox(
              height: 150,
              child: Image.network(
                resource.imageUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _ResourceCover(
                  type: resource.type,
                  accent: accent,
                  accentSoft: accentSoft,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconBadge(
                      icon: _iconFor(resource.type),
                      foreground: accent,
                      background: accentSoft,
                      size: 54,
                      iconSize: 28,
                      radius: 16,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  resource.type.label.toUpperCase(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: accent,
                                        letterSpacing: 0.7,
                                      ),
                                ),
                              ),
                              _StatusBadge(
                                completed: completed,
                                viewed: viewed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            resource.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  resource.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (resource.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: resource.tags
                        .take(4)
                        .map((tag) => _TagPill(label: _readableTag(tag)))
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(_actionLabel(resource.type)),
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
                      color: completed ? AppPalette.success : null,
                    ),
                    label: Text(
                      completed
                          ? 'Completado · marcar pendiente'
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

class _ResourceCover extends StatelessWidget {
  const _ResourceCover({
    required this.type,
    required this.accent,
    required this.accentSoft,
  });

  final ResourceType type;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accentSoft,
      alignment: Alignment.center,
      child: Icon(_iconFor(type), size: 62, color: accent),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
        ? AppPalette.successSoft
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = completed
        ? AppPalette.success
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.visibility_outlined,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            completed ? 'Listo' : 'Visto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
        ],
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
            const AppIconBadge(
              icon: Icons.search_off_rounded,
              size: 64,
              iconSize: 34,
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos recursos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              'Prueba con otra búsqueda o cambia los filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceLoading extends StatelessWidget {
  const _ResourceLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ResourceError extends StatelessWidget {
  const _ResourceError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconBadge(
                  icon: Icons.cloud_off_rounded,
                  foreground: AppPalette.coral,
                  background: Color(0xFFFFE7E7),
                  size: 66,
                  iconSize: 36,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar los recursos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Intentar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => Icons.play_circle_outline_rounded,
    ResourceType.pdf => Icons.picture_as_pdf_outlined,
    ResourceType.form => Icons.assignment_outlined,
    ResourceType.simulator => Icons.quiz_outlined,
    ResourceType.post => Icons.article_outlined,
    ResourceType.announcement => Icons.campaign_outlined,
  };
}

Color _accentFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => AppPalette.primary,
    ResourceType.pdf => const Color(0xFFE05252),
    ResourceType.form => AppPalette.teal,
    ResourceType.simulator => const Color(0xFF7A4CC7),
    ResourceType.post => const Color(0xFF3977C3),
    ResourceType.announcement => const Color(0xFFD17A18),
  };
}

Color _softAccentFor(ResourceType type) {
  return switch (type) {
    ResourceType.video => AppPalette.primarySoft,
    ResourceType.pdf => const Color(0xFFFFE8E8),
    ResourceType.form => AppPalette.tealSoft,
    ResourceType.simulator => const Color(0xFFF0E7FF),
    ResourceType.post => const Color(0xFFE7F1FF),
    ResourceType.announcement => AppPalette.amberSoft,
  };
}

String _actionLabel(ResourceType type) {
  return switch (type) {
    ResourceType.video => 'Ver video',
    ResourceType.pdf => 'Abrir PDF',
    ResourceType.form => 'Abrir formulario',
    ResourceType.simulator => 'Abrir simulacro',
    ResourceType.post => 'Leer publicación',
    ResourceType.announcement => 'Ver anuncio',
  };
}

String _readableTag(String value) {
  if (value.isEmpty) return value;
  final text = value.replaceAll('-', ' ').replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
