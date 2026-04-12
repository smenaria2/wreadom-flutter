// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Book _$BookFromJson(Map<String, dynamic> json) => _Book(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  coverUrl: json['coverUrl'] as String?,
  authors:
      (json['authors'] as List<dynamic>?)
          ?.map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  subjects:
      (json['subjects'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  languages:
      (json['languages'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  formats:
      (json['formats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
  mediaType: json['media_type'] as String? ?? 'text',
  bookshelves:
      (json['bookshelves'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  year: json['year'],
  source: json['source'] as String?,
  isOriginal: json['isOriginal'] as bool?,
  contentType: json['contentType'] as String?,
  authorId: json['authorId'] as String?,
  chapters: (json['chapters'] as List<dynamic>?)
      ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String?,
  createdAt: (json['createdAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  identifier: json['identifier'] as String?,
  recommendationCount: (json['recommendationCount'] as num?)?.toInt(),
  weightedScore: (json['weightedScore'] as num?)?.toDouble(),
  averageRating: (json['averageRating'] as num?)?.toDouble(),
  viewCount: (json['viewCount'] as num?)?.toInt(),
  ratingsCount: (json['ratingsCount'] as num?)?.toInt(),
  topics: (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
  chapterCount: (json['chapterCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$BookToJson(_Book instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'coverUrl': instance.coverUrl,
  'authors': instance.authors,
  'subjects': instance.subjects,
  'languages': instance.languages,
  'formats': instance.formats,
  'download_count': instance.downloadCount,
  'media_type': instance.mediaType,
  'bookshelves': instance.bookshelves,
  'year': instance.year,
  'source': instance.source,
  'isOriginal': instance.isOriginal,
  'contentType': instance.contentType,
  'authorId': instance.authorId,
  'chapters': instance.chapters,
  'status': instance.status,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'identifier': instance.identifier,
  'recommendationCount': instance.recommendationCount,
  'weightedScore': instance.weightedScore,
  'averageRating': instance.averageRating,
  'viewCount': instance.viewCount,
  'ratingsCount': instance.ratingsCount,
  'topics': instance.topics,
  'chapterCount': instance.chapterCount,
};
