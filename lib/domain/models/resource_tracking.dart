class ResourceTracking {
  ResourceTracking({
    Set<String> viewedIds = const {},
    Set<String> completedIds = const {},
  })  : viewedIds = Set.unmodifiable(viewedIds),
        completedIds = Set.unmodifiable(completedIds);

  final Set<String> viewedIds;
  final Set<String> completedIds;

  bool isViewed(String id) => viewedIds.contains(id);

  bool isCompleted(String id) => completedIds.contains(id);

  ResourceTracking markViewed(String id) {
    return ResourceTracking(
      viewedIds: {...viewedIds, id},
      completedIds: completedIds,
    );
  }

  ResourceTracking toggleCompleted(String id) {
    final next = {...completedIds};
    if (!next.add(id)) {
      next.remove(id);
    }
    return ResourceTracking(
      viewedIds: {...viewedIds, id},
      completedIds: next,
    );
  }
}
