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
      appBar: AppBar(
        toolbarHeight: isHandsetLayout(context) ? 124 : null,
        title: Text(
          'Recursos',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: isHandsetLayout(context) ? 36 : null,
              ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
      body: SafeArea(
        child: fullWidthCentered(
          maxWidth: 960,
          child: switch (state.phase) {
            ResourcePhase.loading => Center(
                child: SizedBox(
                  width: isHandsetLayout(context) ? 92 : 48,
                  height: isHandsetLayout(context) ? 92 : 48,
                  child: CircularProgressIndicator(
                    strokeWidth: isHandsetLayout(context) ? 8 : 4,
                  ),
                ),
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
    final horizontalPadding = handset ? 14.0 : 30.0;
    final filtersActive = state.selectedType != null ||
        state.selectedTag != null ||
        normalizedQuery.isNotEmpty;

    return ListView(
      key: const Key('resources_list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        handset ? 28 : 18,
        horizontalPadding,
        handset ? 90 : 34,
      ),
      children: [
        Text(
          'Biblioteca de estudio',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: handset ? 58 : null,
                height: 1.04,
              ),
        ),
        SizedBox(height: handset ? 22 : 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: handset ? 590 : 760),
          child: Text(
            'Encuentra videos, guías y simulacros para reforzar cada tema.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: handset ? 30 : null,
                  height: 1.35,
                ),
          ),
        ),
        SizedBox(height: handset ? 42 : 22),
        _Filters(
          state: state,
          searchController: searchController,
          hasSearch: normalizedQuery.isNotEmpty,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onTypeSelected: onTypeSelected,
          onTagSelected: onTagSelected,
        ),
        SizedBox(height: handset ? 46 : 26),
        _ResultsHeader(
          count: resources.length,
          filtersActive: filtersActive,
          onClear: () {
            onTypeSelected(null);
            onTagSelected(null);
            onClearSearch();
          },
        ),
        SizedBox(height: handset ? 30 : 16),
        if (resources.isEmpty)
          const _EmptyResources()
        else
          ...resources.map(
            (resource) => Padding(
              padding: EdgeInsets.only(bottom: handset ? 38 : 20),
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
    final handset = isHandsetLayout(context);
    final countText = Text(
      '$count ${count == 1 ? 'recurso disponible' : 'recursos disponibles'}',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: handset ? 36 : null,
            height: 1.15,
          ),
    );
    final clearButton = Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onClear,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: handset ? 28 : 14,
            vertical: handset ? 22 : 12,
          ),
          child: Text(
            'Limpiar filtros',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontSize: handset ? 25 : null,
                ),
          ),
        ),
      ),
    );

    if (filtersActive && handset) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          countText,
          const SizedBox(height: 22),
          clearButton,
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
        padding: EdgeInsets.all(handset ? 34 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Busca un recurso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: handset ? 40 : null,
                  ),
            ),
            SizedBox(height: handset ? 24 : 12),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: handset ? 112 : 0),
              child: TextField(
                key: const Key('resources_search_field'),
                controller: searchController,
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: handset ? 29 : null,
                    ),
                decoration: InputDecoration(
                  hintText: 'Tema, materia o tipo',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: handset ? 27 : null,
                      ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: handset ? 28 : 18,
                    vertical: handset ? 28 : 20,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: handset ? 44 : 30,
                  ),
                  suffixIcon: hasSearch
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: onClearSearch,
                          icon: Icon(
                            Icons.close_rounded,
                            size: handset ? 40 : 28,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: handset ? 40 : 22),
            Text(
              'Tipo de recurso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: handset ? 31 : null,
                  ),
            ),
            SizedBox(height: handset ? 22 : 12),
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
                    SizedBox(width: handset ? 16 : 10),
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
            SizedBox(height: handset ? 42 : 22),
            Text(
              'Materia o etiqueta',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: handset ? 31 : null,
                  ),
            ),
            SizedBox(height: handset ? 22 : 12),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: handset ? 112 : 0),
              child: DropdownButtonFormField<String>(
                key: ValueKey(state.selectedTag ?? '__all__'),
                initialValue: state.selectedTag ?? '__all__',
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: handset ? 44 : 30,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: handset ? 28 : 18,
                    vertical: handset ? 26 : 20,
                  ),
                  prefixIcon: Icon(
                    Icons.sell_outlined,
                    size: handset ? 42 : 28,
                  ),
                ),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: handset ? 28 : null,
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
    final handset = isHandsetLayout(context);
    final foreground = selected ? colors.onPrimary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? colors.primary : const Color(0xFFD8DDE8),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: BoxConstraints(minHeight: handset ? 92 : 54),
            padding: EdgeInsets.symmetric(
              horizontal: handset ? 26 : 16,
              vertical: handset ? 20 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: handset ? 38 : 24, color: foreground),
                SizedBox(width: handset ? 14 : 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontSize: handset ? 24 : 16.5,
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
              aspectRatio: handset ? 4 / 3 : 16 / 9,
              child: Image.network(
                resource.imageUrl.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ResourceCover(type: resource.type),
              ),
            ),
          Container(
            constraints: BoxConstraints(minHeight: handset ? 660 : 0),
            padding: EdgeInsets.all(handset ? 36 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResourceTypeIcon(type: resource.type),
                    SizedBox(width: handset ? 24 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: handset ? 14 : 10,
                            runSpacing: handset ? 14 : 8,
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
                                      letterSpacing: 0.8,
                                      fontSize: handset ? 22 : null,
                                    ),
                              ),
                              _StatusBadge(
                                completed: completed,
                                viewed: viewed,
                              ),
                            ],
                          ),
                          SizedBox(height: handset ? 18 : 8),
                          Text(
                            resource.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: handset ? 42 : null,
                                  height: 1.12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: handset ? 34 : 18),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: handset ? 590 : 760),
                  child: Text(
                    resource.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: handset ? 30 : null,
                          height: 1.42,
                        ),
                  ),
                ),
                if (resource.tags.isNotEmpty) ...[
                  SizedBox(height: handset ? 32 : 18),
                  Wrap(
                    spacing: handset ? 14 : 9,
                    runSpacing: handset ? 14 : 9,
                    children: resource.tags
                        .take(3)
                        .map(
                          (tag) => _TagPill(label: _readableTag(tag)),
                        )
                        .toList(),
                  ),
                ],
                SizedBox(height: handset ? 48 : 24),
                ConstrainedBox(
                  key: Key('resource_open_${resource.id}'),
                  constraints: BoxConstraints(minHeight: handset ? 106 : 66),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        textStyle: TextStyle(
                          fontSize: handset ? 28 : 17,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            handset ? 24 : 16,
                          ),
                        ),
                      ),
                      onPressed: onOpen,
                      icon: Icon(
                        Icons.open_in_new_rounded,
                        size: handset ? 40 : 27,
                      ),
                      label: Text(_openLabelFor(resource.type)),
                    ),
                  ),
                ),
                SizedBox(height: handset ? 20 : 12),
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
    final handset = isHandsetLayout(context);
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
          borderRadius: BorderRadius.circular(handset ? 24 : 17),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(handset ? 24 : 17),
          child: Container(
            constraints: BoxConstraints(minHeight: handset ? 98 : 64),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: handset ? 28 : 18,
              vertical: handset ? 22 : 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: handset ? 40 : 27,
                  color: foreground,
                ),
                SizedBox(width: handset ? 16 : 10),
                Flexible(
                  child: Text(
                    completed ? 'Completado' : 'Marcar como completado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: handset ? 25 : 17.5,
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
      padding: EdgeInsets.symmetric(
        horizontal: isHandsetLayout(context) ? 20 : 13,
        vertical: isHandsetLayout(context) ? 14 : 9,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DDE8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: isHandsetLayout(context) ? 21 : 15,
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
      width: isHandsetLayout(context) ? 118 : 76,
      height: isHandsetLayout(context) ? 118 : 76,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(
          isHandsetLayout(context) ? 30 : 22,
        ),
      ),
      child: Icon(
        _iconFor(type),
        size: isHandsetLayout(context) ? 64 : 42,
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
    return Container(
      padding: EdgeInsets.all(isHandsetLayout(context) ? 36 : 22),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.72),
      ),
      child: Row(
        children: [
          Container(
            width: isHandsetLayout(context) ? 118 : 76,
            height: isHandsetLayout(context) ? 118 : 76,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(
                isHandsetLayout(context) ? 30 : 22,
              ),
            ),
            child: Icon(
              _iconFor(type),
              size: isHandsetLayout(context) ? 64 : 42,
              color: colors.primary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.school_rounded,
            size: isHandsetLayout(context) ? 100 : 66,
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
      padding: EdgeInsets.symmetric(
        horizontal: isHandsetLayout(context) ? 16 : 10,
        vertical: isHandsetLayout(context) ? 12 : 7,
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
            size: isHandsetLayout(context) ? 28 : 18,
            color: foreground,
          ),
          SizedBox(width: isHandsetLayout(context) ? 10 : 6),
          Text(
            completed ? 'Completado' : 'Visto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: isHandsetLayout(context) ? 20 : null,
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
            Icon(Icons.error_outline, size: isHandsetLayout(context) ? 110 : 64),
            SizedBox(height: isHandsetLayout(context) ? 30 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isHandsetLayout(context) ? 28 : null,
              ),
            ),
            SizedBox(height: isHandsetLayout(context) ? 34 : 20),
            SizedBox(
              height: isHandsetLayout(context) ? 100 : null,
              child: FilledButton(
                onPressed: onRetry,
                child: Text(
                  'Reintentar',
                  style: TextStyle(
                    fontSize: isHandsetLayout(context) ? 27 : null,
                  ),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isHandsetLayout(context) ? 34 : 24,
          vertical: isHandsetLayout(context) ? 80 : 40,
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isHandsetLayout(context) ? 110 : 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No encontramos recursos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: isHandsetLayout(context) ? 38 : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra búsqueda o limpia los filtros.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isHandsetLayout(context) ? 28 : null,
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
