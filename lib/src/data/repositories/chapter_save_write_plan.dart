class ChapterSaveWritePlan {
  const ChapterSaveWritePlan({
    required this.fullChapterIds,
    required this.metadataOnlyChapterIds,
  });

  /// Chapters whose bodies changed and therefore require revision checks.
  final Set<String> fullChapterIds;

  /// Unchanged chapters that only need book-level metadata synchronized.
  final Set<String> metadataOnlyChapterIds;

  int writeCount({required int deletedChapterCount}) =>
      fullChapterIds.length +
      metadataOnlyChapterIds.length +
      deletedChapterCount +
      1;
}

/// Separates body writes from metadata-only writes.
///
/// Legacy callers that omit [changedChapterIds] retain the previous behavior
/// of writing every chapter in full. Callers that track changes only read and
/// revision-check those bodies; all other chapter documents still receive the
/// status associated with the enclosing book save.
ChapterSaveWritePlan buildChapterSaveWritePlan({
  required Iterable<String> incomingChapterIds,
  required Set<String> changedChapterIds,
  bool changedChapterIdsAreAuthoritative = false,
}) {
  final incomingIds = incomingChapterIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  final fullChapterIds =
      changedChapterIds.isEmpty && !changedChapterIdsAreAuthoritative
      ? incomingIds
      : changedChapterIds
            .map((id) => id.trim())
            .where(incomingIds.contains)
            .toSet();
  return ChapterSaveWritePlan(
    fullChapterIds: fullChapterIds,
    metadataOnlyChapterIds: incomingIds.difference(fullChapterIds),
  );
}
