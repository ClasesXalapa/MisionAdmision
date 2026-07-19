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
    final responsive = context.responsive;
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
      padding: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        responsive.compactGap,
        responsive.pagePadding,
        responsive.sectionGap,
      ),
      children: [
        const _ResourcesHero(),
        SizedBox(height: responsive.itemGap),
        _Filters(
          state: state,
          searchController: searchController,
          hasSearch: normalizedQuery.isNotEmpty,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        SizedBox(height: responsive.sectionGap * 0.72),
        _ResultsHeader(
          count: resources.length,
          filtersActive: filtersActive,
          onClear: () {
            onTypeSelected(null);
            onTagSelected(null);
            onClearSearch();
          },
        ),
        SizedBox(height: responsive.itemGap),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: EdgeInsets.only(bottom: responsive.itemGap),
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
    final responsive = context.responsive;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppPalette.resourceGradient,
        borderRadius: BorderRadius.circular(responsive.heroRadius),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -responsive.value(0.05, minimum: 20, maximum: 40),
            bottom: -responsive.value(0.06, minimum: 24, maximum: 48),
            child: Icon(
              Icons.auto_stories_rounded,
              size: responsive.widthValue(0.3, minimum: 135, maximum: 220),
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                const AppIconBadge(
                  icon: Icons.explore_rounded,
                  foreground: Color(0xFF087267),
                  background: Colors.white,
                ),
                SizedBox(width: responsive.itemGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biblioteca de estudio',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      SizedBox(height: responsive.compactGap * 0.65),
                      Text(
                        'Encuentra el recurso ideal para reforzar cada tema.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
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
    final responsive = context.responsive;
    return Card(
      key: const Key('resources_filters_card'),
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPadding),
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
            SizedBox(height: responsive.itemGap),
            Text(
              'Tipo de recurso',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: responsive.compactGap),
            SizedBox(
              height: responsive.controlHeight,
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
                  SizedBox(width: responsive.compactGap),
                  for (final type in ResourceType.values) ...[
                    _TypeFilterButton(
                      label: type.label,
                      icon: _iconFor(type),
                      selected: state.selectedType == type,
                      onTap: () => onTypeSelected(type),
                    ),
                    SizedBox(width: responsive.compactGap),
                  ],
                ],
              ),
            ),
            SizedBox(height: responsive.itemGap),
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
    final responsive = context.responsive;
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
          padding: EdgeInsets.symmetric(
            horizontal: responsive.value(0.034, minimum: 13, maximum: 24),
            vertical: responsive.value(0.023, minimum: 9, maximum: 17),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: responsive.iconSize * 0.78,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              SizedBox(width: responsive.compactGap * 0.75),
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
    final responsive = context.responsive;
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
            icon: Icon(
              Icons.filter_alt_off_rounded,
              size: responsive.iconSize * 0.75,
            ),
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
    final responsive = context.responsive;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (resource.imageUrl != null)
            SizedBox(
              height: responsive.heightValue(0.2, minimum: 170, maximum: 290),
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
            padding: EdgeInsets.all(responsive.cardPadding),
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
                      size: responsive.iconBadgeSize * 1.05,
                      iconSize: responsive.iconSize,
                      radius: responsive.mediumRadius,
                    ),
                    SizedBox(width: responsive.itemGap),
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
                          SizedBox(height: responsive.compactGap * 0.55),
                          Text(
                            resource.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.itemGap),
                Text(
                  resource.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (resource.tags.isNotEmpty) ...[
                  SizedBox(height: responsive.itemGap),
                  Wrap(
                    spacing: responsive.compactGap * 0.8,
                    runSpacing: responsive.compactGap * 0.8,
                    children: resource.tags
                        .take(4)
                        .map((tag) => _TagPill(label: _readableTag(tag)))
                        .toList(growable: false),
                  ),
                ],
                SizedBox(height: responsive.sectionGap * 0.65),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(_actionLabel(resource.type)),
                  ),
                ),
                SizedBox(height: responsive.compactGap),
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
    final responsive = context.responsive;
    return Container(
      color: accentSoft,
      alignment: Alignment.center,
      child: Icon(
        _iconFor(type),
        size: responsive.iconBadgeSize,
        color: accent,
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(0.024, minimum: 9, maximum: 17),
        vertical: responsive.value(0.015, minimum: 6, maximum: 11),
      ),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(responsive.largeRadius),
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

    final responsive = context.responsive;
    final background = completed
        ? AppPalette.successSoft
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = completed
        ? AppPalette.success
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(0.02, minimum: 8, maximum: 14),
        vertical: responsive.value(0.012, minimum: 5, maximum: 9),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(responsive.largeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.visibility_outlined,
            size: responsive.iconSize * 0.58,
            color: foreground,
          ),
          SizedBox(width: responsive.compactGap * 0.55),
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
    final responsive = context.responsive;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(responsive.cardPadding * 1.2),
        child: Column(
          children: [
            const AppIconBadge(
              icon: Icons.search_off_rounded,
            ),
            SizedBox(height: responsive.itemGap),
            Text(
              'No encontramos recursos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: responsive.compactGap * 0.75),
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
    final responsive = context.responsive;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.pagePadding),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconBadge(
                  icon: Icons.cloud_off_rounded,
                  foreground: AppPalette.coral,
                  background: Color(0xFFFFE7E7),
                ),
                SizedBox(height: responsive.itemGap),
                Text(
                  'No pudimos cargar los recursos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: responsive.compactGap),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: responsive.sectionGap * 0.65),
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
