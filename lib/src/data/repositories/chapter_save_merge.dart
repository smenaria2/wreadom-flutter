import '../../domain/models/chapter.dart';

class ChapterSaveConflictException implements Exception {
  ChapterSaveConflictException(this.chapterIds);

  final List<String> chapterIds;

  @override
  String toString() {
    return 'ChapterSaveConflictException: ${chapterIds.join(', ')}';
  }
}

class ChapterMergeResult {
  const ChapterMergeResult({required this.chapters});

  final List<Chapter> chapters;
}

ChapterMergeResult mergeAuthoringChaptersForSave({
  required List<Chapter> incomingChapters,
  required List<Chapter> existingChapters,
  Set<String> deletedChapterIds = const <String>{},
  Map<String, int> baseChapterRevisions = const <String, int>{},
}) {
  final deletedIds = deletedChapterIds.map((id) => id.trim()).toSet();
  final existingById = <String, Chapter>{
    for (final chapter in existingChapters)
      if (chapter.id.trim().isNotEmpty) chapter.id: chapter,
  };

  final mergedById = <String, Chapter>{};
  final sortKeys = <String, ({int index, int tie})>{};
  final conflicts = <String>[];

  for (var i = 0; i < incomingChapters.length; i++) {
    final incoming = incomingChapters[i];
    final id = incoming.id.trim();
    if (id.isEmpty || deletedIds.contains(id)) continue;
    final existing = existingById[id];
    final hasChanged = existing == null || _chapterChanged(incoming, existing);
    final baseRevision = baseChapterRevisions[id];
    final remoteRevision = existing?.revision ?? 0;
    if (hasChanged && baseRevision != null && remoteRevision != baseRevision) {
      conflicts.add(id);
      continue;
    }
    final nextRevision = hasChanged
        ? (existing == null ? incoming.revision + 1 : remoteRevision + 1)
        : remoteRevision;
    mergedById[id] = incoming.copyWith(revision: nextRevision);
    sortKeys[id] = (index: incoming.index, tie: 1);
  }

  if (conflicts.isNotEmpty) {
    throw ChapterSaveConflictException(conflicts);
  }

  for (final existing in existingChapters) {
    final id = existing.id.trim();
    if (id.isEmpty || deletedIds.contains(id) || mergedById.containsKey(id)) {
      continue;
    }
    mergedById[id] = existing;
    sortKeys[id] = (index: existing.index, tie: 0);
  }

  final merged = mergedById.values.toList()
    ..sort((a, b) {
      final aKey = sortKeys[a.id] ?? (index: a.index, tie: 1);
      final bKey = sortKeys[b.id] ?? (index: b.index, tie: 1);
      final indexCompare = aKey.index.compareTo(bKey.index);
      if (indexCompare != 0) return indexCompare;
      final tieCompare = aKey.tie.compareTo(bKey.tie);
      if (tieCompare != 0) return tieCompare;
      return a.id.compareTo(b.id);
    });

  return ChapterMergeResult(
    chapters: <Chapter>[
      for (var i = 0; i < merged.length; i++) merged[i].copyWith(index: i),
    ],
  );
}

List<Chapter> visibleChaptersForBookProjection(List<Chapter> chapters) {
  final visible = <Chapter>[
    for (final chapter in chapters)
      if (!chapter.isHidden) chapter,
  ];
  return <Chapter>[
    for (var i = 0; i < visible.length; i++)
      visible[i].copyWith(index: i, isHidden: false),
  ];
}

bool _chapterChanged(Chapter incoming, Chapter existing) {
  return incoming.title != existing.title ||
      incoming.content != existing.content ||
      incoming.status != existing.status ||
      incoming.isHidden != existing.isHidden ||
      incoming.isTitleLocked != existing.isTitleLocked ||
      incoming.originalBookId != existing.originalBookId ||
      !_versionsEqual(incoming.versions, existing.versions);
}

bool _versionsEqual(List<ChapterVersion>? a, List<ChapterVersion>? b) {
  final left = a ?? const <ChapterVersion>[];
  final right = b ?? const <ChapterVersion>[];
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
