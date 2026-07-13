// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectionCoverSnapshot _$CollectionCoverSnapshotFromJson(
  Map<String, dynamic> json,
) => _CollectionCoverSnapshot(
  bookId: json['bookId'] as String,
  coverUrl: json['coverUrl'] as String,
);

Map<String, dynamic> _$CollectionCoverSnapshotToJson(
  _CollectionCoverSnapshot instance,
) => <String, dynamic>{
  'bookId': instance.bookId,
  'coverUrl': instance.coverUrl,
};

_BookCollection _$BookCollectionFromJson(Map<String, dynamic> json) =>
    _BookCollection(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
      coverBookIds:
          (json['coverBookIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      coverBooks:
          (json['coverBooks'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CollectionCoverSnapshot.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <CollectionCoverSnapshot>[],
      createdAt: (json['createdAt'] as num?)?.toInt(),
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookCollectionToJson(_BookCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'title': instance.title,
      'description': instance.description,
      'bookCount': instance.bookCount,
      'coverBookIds': instance.coverBookIds,
      'coverBooks': instance.coverBooks,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
