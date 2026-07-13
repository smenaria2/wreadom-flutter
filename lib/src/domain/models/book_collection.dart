import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_collection.freezed.dart';
part 'book_collection.g.dart';

@freezed
abstract class CollectionCoverSnapshot with _$CollectionCoverSnapshot {
  const factory CollectionCoverSnapshot({
    required String bookId,
    required String coverUrl,
  }) = _CollectionCoverSnapshot;

  factory CollectionCoverSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CollectionCoverSnapshotFromJson(json);
}

@freezed
abstract class BookCollection with _$BookCollection {
  const factory BookCollection({
    required String id,
    required String ownerId,
    required String title,
    @Default('') String description,
    @Default(0) int bookCount,
    @Default(<String>[]) List<String> coverBookIds,
    @Default(<CollectionCoverSnapshot>[])
    List<CollectionCoverSnapshot> coverBooks,
    int? createdAt,
    int? updatedAt,
  }) = _BookCollection;

  factory BookCollection.fromJson(Map<String, dynamic> json) =>
      _$BookCollectionFromJson(json);
}
