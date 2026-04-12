// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homepage_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomepageMetadata _$HomepageMetadataFromJson(Map<String, dynamic> json) =>
    _HomepageMetadata(
      authors: (json['authors'] as List<dynamic>)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyTopics: json['dailyTopics'] as List<dynamic>,
      recommendationStats: json['recommendationStats'] as Map<String, dynamic>,
      lastUpdated: json['lastUpdated'],
      appVersion: json['appVersion'] as String?,
    );

Map<String, dynamic> _$HomepageMetadataToJson(_HomepageMetadata instance) =>
    <String, dynamic>{
      'authors': instance.authors,
      'dailyTopics': instance.dailyTopics,
      'recommendationStats': instance.recommendationStats,
      'lastUpdated': instance.lastUpdated,
      'appVersion': instance.appVersion,
    };
