// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChapterVersion _$ChapterVersionFromJson(Map<String, dynamic> json) =>
    _ChapterVersion(
      content: json['content'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      wordCount: (json['wordCount'] as num).toInt(),
    );

Map<String, dynamic> _$ChapterVersionToJson(_ChapterVersion instance) =>
    <String, dynamic>{
      'content': instance.content,
      'timestamp': instance.timestamp,
      'wordCount': instance.wordCount,
    };

_Chapter _$ChapterFromJson(Map<String, dynamic> json) => _Chapter(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  index: (json['index'] as num).toInt(),
  status: json['status'] as String?,
  versions: (json['versions'] as List<dynamic>?)
      ?.map((e) => ChapterVersion.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastSavedAt: (json['lastSavedAt'] as num?)?.toInt(),
  isTitleLocked: json['isTitleLocked'] as bool?,
  originalBookId: json['originalBookId'] as String?,
);

Map<String, dynamic> _$ChapterToJson(_Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'index': instance.index,
  'status': instance.status,
  'versions': instance.versions?.map((e) => e.toJson()).toList(),
  'lastSavedAt': instance.lastSavedAt,
  'isTitleLocked': instance.isTitleLocked,
  'originalBookId': instance.originalBookId,
};
