import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/book_collection.dart';
import '../../domain/models/collection_book.dart';
import '../../utils/map_utils.dart';

int? collectionTimestampMillis(dynamic value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is num) return value.toInt();
  if (value is Map && value['seconds'] is num) {
    return (value['seconds'] as num).toInt() * 1000;
  }
  return null;
}

BookCollection normalizeCollection(dynamic raw, String documentId) {
  final map = asStringMap(raw);
  final covers = <CollectionCoverSnapshot>[];
  final rawCovers = map['coverBooks'];
  if (rawCovers is List) {
    for (final item in rawCovers) {
      if (item is! Map) continue;
      final cover = asStringMap(item);
      final bookId = cover['bookId']?.toString().trim() ?? '';
      final coverUrl = cover['coverUrl']?.toString().trim() ?? '';
      if (bookId.isNotEmpty && coverUrl.isNotEmpty) {
        covers.add(CollectionCoverSnapshot(bookId: bookId, coverUrl: coverUrl));
      }
    }
  }
  return BookCollection(
    id: documentId,
    ownerId: map['ownerId']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    description: map['description']?.toString() ?? '',
    bookCount: (map['bookCount'] as num?)?.toInt() ?? 0,
    coverBookIds: map['coverBookIds'] is List
        ? (map['coverBookIds'] as List).map((e) => e.toString()).toList()
        : const [],
    coverBooks: covers,
    createdAt: collectionTimestampMillis(map['createdAt']),
    updatedAt: collectionTimestampMillis(map['updatedAt']),
  );
}

CollectionBook normalizeCollectionBook(dynamic raw, String documentId) {
  final map = asStringMap(raw);
  return CollectionBook(
    bookId: documentId,
    position: (map['position'] as num?)?.toInt() ?? 0,
    addedAt: collectionTimestampMillis(map['addedAt']),
  );
}
