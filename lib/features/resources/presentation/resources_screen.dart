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

// Recursos se diseña deliberadamente como una experiencia móvil grande.
// No depende de breakpoints ni de la plataforma reportada por el navegador:
// varios WebView/PWA Android informan métricas de escritorio y activaban la
// composición compacta. Mantener este valor fijo garantiza controles grandes.
bool _useLargeMobileResourcesLayout(BuildContext _) => true;

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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: largeMobile ? 176 : null,
        titleSpacing: largeMobile ? 18 : null,
        title: Text(
          'Recursos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: largeMobile ? 58 : null,
                height: 1.05,
              ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      body: SafeArea(
        child: fullWidthCentered(
          maxWidth: 1040,
          child: switch (state.phase) {
            ResourcePhase.loading => _ResourceLoading(large: largeMobile),
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

    final largeMobile = _useLargeMobileResourcesLayout(context);
    final filtersActive = state.selectedType != null ||
        state.selectedTag != null ||
        normalizedQuery.isNotEmpty;

    return ListView(
      key: const Key('resources_list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        largeMobile ? 12 : 30,
        largeMobile ? 52 : 18,
        largeMobile ? 12 : 30,
        largeMobile ? 180 : 34,
      ),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largeMobile ? 600 : 760),
          child: Text(
            'Biblioteca de estudio',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: largeMobile ? 80 : null,
                  height: 1.02,
                  letterSpacing: largeMobile ? -1.3 : null,
                ),
          ),
        ),
        SizedBox(height: largeMobile ? 34 : 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largeMobile ? 540 : 760),
          child: Text(
            'Encuentra videos, guías y simulacros para reforzar cada tema.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: largeMobile ? 44 : null,
                  height: 1.38,
                ),
          ),
        ),
        SizedBox(height: largeMobile ? 68 : 22),
        _Filters(
          state: state,
          searchController: searchController,
          hasSearch: normalizedQuery.isNotEmpty,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        SizedBox(height: largeMobile ? 76 : 26),
        _ResultsHeader(
          count: resources.length,
          filtersActive: filtersActive,
          onClear: () {
            onTypeSelected(null);
            onTagSelected(null);
            onClearSearch();
          },
        ),
        SizedBox(height: largeMobile ? 50 : 16),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: EdgeInsets.only(bottom: largeMobile ? 68 : 20),
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Card(
      key: const Key('resources_filters_card'),
      child: Padding(
        padding: EdgeInsets.all(largeMobile ? 52 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Busca un recurso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: largeMobile ? 58 : null,
                    height: 1.08,
                  ),
            ),
            SizedBox(height: largeMobile ? 36 : 12),
            SizedBox(
              height: largeMobile ? 156 : null,
              child: TextField(
                key: const Key('resources_search_field'),
                controller: searchController,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: largeMobile ? 44 : null,
                      height: 1.2,
                    ),
                decoration: InputDecoration(
                  hintText: 'Tema, materia o tipo',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: largeMobile ? 38 : null,
                      ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: largeMobile ? 38 : 18,
                    vertical: largeMobile ? 38 : 20,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: largeMobile ? 104 : 48,
                    minHeight: largeMobile ? 104 : 48,
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minWidth: largeMobile ? 104 : 48,
                    minHeight: largeMobile ? 104 : 48,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: largeMobile ? 60 : 30,
                  ),
                  suffixIcon: hasSearch
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: onClearSearch,
                          icon: Icon(
                            Icons.close_rounded,
                            size: largeMobile ? 56 : 28,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: largeMobile ? 64 : 22),
            Text(
              'Tipo de recurso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: largeMobile ? 44 : null,
                    height: 1.1,
                  ),
            ),
            SizedBox(height: largeMobile ? 36 : 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = largeMobile ? 24.0 : 10.0;
                final buttonWidth = largeMobile ? constraints.maxWidth : null;

                return Wrap(
                  key: const Key('resources_type_filters'),
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _TypeFilterButton(
                      key: const Key('resource_type_filter_all'),
                      width: buttonWidth,
                      label: 'Todos',
                      icon: Icons.grid_view_rounded,
                      selected: state.selectedType == null,
                      onTap: () => onTypeSelected(null),
                    ),
                    for (final type in ResourceType.values)
                      _TypeFilterButton(
                        width: buttonWidth,
                        label: type.label,
                        icon: _iconFor(type),
                        selected: state.selectedType == type,
                        onTap: () => onTypeSelected(type),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: largeMobile ? 68 : 22),
            Text(
              'Materia o etiqueta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: largeMobile ? 44 : null,
                    height: 1.1,
                  ),
            ),
            SizedBox(height: largeMobile ? 36 : 12),
            SizedBox(
              height: largeMobile ? 156 : null,
              child: DropdownButtonFormField<String>(
                key: ValueKey(state.selectedTag ?? '__all__'),
                initialValue: state.selectedTag ?? '__all__',
                isExpanded: true,
                itemHeight: largeMobile ? 100 : null,
                menuMaxHeight: largeMobile ? 720 : null,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: largeMobile ? 60 : 30,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: largeMobile ? 38 : 18,
                    vertical: largeMobile ? 40 : 20,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: largeMobile ? 104 : 48,
                    minHeight: largeMobile ? 104 : 48,
                  ),
                  prefixIcon: Icon(
                    Icons.sell_outlined,
                    size: largeMobile ? 60 : 28,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: largeMobile ? 40 : null,
                      height: 1.2,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    super.key,
    required this.width,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final double? width;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final largeMobile = _useLargeMobileResourcesLayout(context);
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        width: width,
        child: Material(
          color: selected ? colors.primary : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeMobile ? 28 : 24),
            side: BorderSide(
              width: largeMobile ? 2 : 1,
              color: selected ? colors.primary : const Color(0xFFD8DDE8),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(largeMobile ? 28 : 24),
            child: Container(
              constraints: BoxConstraints(minHeight: largeMobile ? 150 : 54),
              padding: EdgeInsets.symmetric(
                horizontal: largeMobile ? 22 : 16,
                vertical: largeMobile ? 24 : 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: largeMobile ? 48 : 24,
                    color: foreground,
                  ),
                  SizedBox(height: largeMobile ? 14 : 8),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: largeMobile ? 34 : 16.5,
                          height: 1.1,
                        ),
                  ),
                ],
              ),
            ),
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
    final colors = Theme.of(context).colorScheme;
    final largeMobile = _useLargeMobileResourcesLayout(context);

    final countText = Text(
      '$count ${count == 1 ? 'recurso disponible' : 'recursos disponibles'}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: largeMobile ? 52 : null,
            height: 1.12,
          ),
    );

    final clearButton = Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(largeMobile ? 28 : 24),
      child: InkWell(
        onTap: onClear,
        borderRadius: BorderRadius.circular(largeMobile ? 28 : 24),
        child: Container(
          constraints: BoxConstraints(minHeight: largeMobile ? 86 : 0),
          padding: EdgeInsets.symmetric(
            horizontal: largeMobile ? 30 : 14,
            vertical: largeMobile ? 22 : 12,
          ),
          child: Center(
            child: Text(
              'Limpiar filtros',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontSize: largeMobile ? 29 : null,
                  ),
            ),
          ),
        ),
      ),
    );

    if (largeMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          countText,
          if (filtersActive) ...[
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: clearButton),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: countText),
        if (filtersActive) ...[
          const SizedBox(width: 16),
          clearButton,
        ],
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resource.imageUrl != null)
            AspectRatio(
              aspectRatio: largeMobile ? 4 / 3 : 16 / 9,
              child: Image.network(
                resource.imageUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ResourceCover(type: resource.type),
              ),
            ),
          Container(
            constraints: BoxConstraints(minHeight: largeMobile ? 920 : 0),
            padding: EdgeInsets.all(largeMobile ? 54 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResourceHeader(
                  resource: resource,
                  viewed: viewed,
                  completed: completed,
                ),
                SizedBox(height: largeMobile ? 50 : 20),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: largeMobile ? 540 : 760),
                  child: Text(
                    resource.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: largeMobile ? 40 : null,
                          height: 1.42,
                        ),
                  ),
                ),
                SizedBox(height: largeMobile ? 52 : 18),
                Wrap(
                  spacing: largeMobile ? 20 : 10,
                  runSpacing: largeMobile ? 20 : 10,
                  children: resource.tags
                      .map((tag) => _TagPill(label: _readableTag(tag)))
                      .toList(growable: false),
                ),
                SizedBox(height: largeMobile ? 64 : 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(largeMobile ? 142 : 62),
                      padding: EdgeInsets.symmetric(
                        horizontal: largeMobile ? 36 : 22,
                        vertical: largeMobile ? 34 : 17,
                      ),
                      textStyle: TextStyle(
                        fontSize: largeMobile ? 38 : 17,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          largeMobile ? 32 : 16,
                        ),
                      ),
                    ),
                    onPressed: onOpen,
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: largeMobile ? 56 : 27,
                    ),
                    label: Text(_openLabelFor(resource.type)),
                  ),
                ),
                SizedBox(height: largeMobile ? 32 : 12),
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

class _ResourceHeader extends StatelessWidget {
  const _ResourceHeader({
    required this.resource,
    required this.viewed,
    required this.completed,
  });

  final ResourceCard resource;
  final bool viewed;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final largeMobile = _useLargeMobileResourcesLayout(context);
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResourceTypeIcon(type: resource.type),
        SizedBox(width: largeMobile ? 36 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: largeMobile ? 14 : 10,
                runSpacing: largeMobile ? 14 : 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    resource.type.label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontSize: largeMobile ? 30 : 15,
                          letterSpacing: 0.5,
                        ),
                  ),
                  _StatusBadge(completed: completed, viewed: viewed),
                ],
              ),
              SizedBox(height: largeMobile ? 22 : 8),
              Text(
                resource.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: largeMobile ? 54 : 25,
                      height: 1.12,
                    ),
              ),
            ],
          ),
        ),
      ],
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
    final largeMobile = _useLargeMobileResourcesLayout(context);
    final background = completed
        ? const Color(0xFFE4F5E8)
        : colors.surfaceContainerLowest;
    final foreground =
        completed ? const Color(0xFF18733C) : colors.onSurfaceVariant;
    final border =
        completed ? const Color(0xFF9FD6AE) : const Color(0xFFD8DDE8);

    return Semantics(
      button: true,
      selected: completed,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(largeMobile ? 28 : 17),
          side: BorderSide(color: border, width: largeMobile ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(largeMobile ? 28 : 17),
          child: Container(
            constraints: BoxConstraints(minHeight: largeMobile ? 114 : 64),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: largeMobile ? 30 : 18,
              vertical: largeMobile ? 26 : 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: largeMobile ? 56 : 27,
                  color: foreground,
                ),
                SizedBox(width: largeMobile ? 18 : 10),
                Flexible(
                  child: Text(
                    completed ? 'Completado' : 'Marcar como completado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: largeMobile ? 31 : 17.5,
                          height: 1.2,
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: largeMobile ? 24 : 13,
        vertical: largeMobile ? 17 : 9,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(largeMobile ? 18 : 14),
        border: Border.all(
          color: const Color(0xFFD8DDE8),
          width: largeMobile ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: largeMobile ? 26 : 15,
              height: 1.15,
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Container(
      width: largeMobile ? 136 : 76,
      height: largeMobile ? 136 : 76,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(largeMobile ? 34 : 22),
      ),
      child: Icon(
        _iconFor(type),
        size: largeMobile ? 76 : 42,
        color: colors.primary,
      ),
    );
  }
}

class _ResourceCover extends StatelessWidget {
  const _ResourceCover({required this.type});

  final ResourceType type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Container(
      padding: EdgeInsets.all(largeMobile ? 52 : 22),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          Container(
            width: largeMobile ? 136 : 76,
            height: largeMobile ? 136 : 76,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(largeMobile ? 34 : 22),
            ),
            child: Icon(
              _iconFor(type),
              size: largeMobile ? 76 : 42,
              color: colors.primary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.school_rounded,
            size: largeMobile ? 116 : 66,
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

    final largeMobile = _useLargeMobileResourcesLayout(context);
    final background = completed
        ? const Color(0xFFE4F5E8)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final foreground = completed
        ? const Color(0xFF18733C)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: largeMobile ? 18 : 10,
        vertical: largeMobile ? 13 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.visibility_outlined,
            size: largeMobile ? 32 : 18,
            color: foreground,
          ),
          SizedBox(width: largeMobile ? 10 : 6),
          Text(
            completed ? 'Completado' : 'Visto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: largeMobile ? 23 : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _ResourceLoading extends StatelessWidget {
  const _ResourceLoading({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: large ? 108 : 48,
        height: large ? 108 : 48,
        child: CircularProgressIndicator(strokeWidth: large ? 9 : 4),
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(largeMobile ? 42 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: largeMobile ? 130 : 64,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: largeMobile ? 34 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: largeMobile ? 38 : null,
                    height: 1.4,
                  ),
            ),
            SizedBox(height: largeMobile ? 50 : 20),
            SizedBox(
              width: double.infinity,
              height: largeMobile ? 112 : null,
              child: FilledButton(
                onPressed: onRetry,
                child: Text(
                  'Reintentar',
                  style: TextStyle(fontSize: largeMobile ? 32 : null),
                ),
              ),
            ),
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
    final largeMobile = _useLargeMobileResourcesLayout(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: largeMobile ? 40 : 24,
          vertical: largeMobile ? 96 : 40,
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: largeMobile ? 130 : 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: largeMobile ? 34 : 16),
            Text(
              'No encontramos recursos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: largeMobile ? 52 : null,
                  ),
            ),
            SizedBox(height: largeMobile ? 22 : 8),
            Text(
              'Prueba con otra búsqueda o limpia los filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: largeMobile ? 38 : null,
                    height: 1.4,
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
