// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homepage_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomepageMetadata _$HomepageMetadataFromJson(Map<String, dynamic> json) =>
    _HomepageMetadata(
      authors:
          (json['authors'] as List<dynamic>?)
              ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recommendationStats:
          (json['recommendationStats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              BookRecommendationStats.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
      dailyTopics:
          (json['dailyTopics'] as List<dynamic>?)
              ?.map((e) => DailyTopic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HomepageMetadataToJson(_HomepageMetadata instance) =>
    <String, dynamic>{
      'authors': instance.authors,
      'recommendationStats': instance.recommendationStats,
      'dailyTopics': instance.dailyTopics,
    };

_BookRecommendationStats _$BookRecommendationStatsFromJson(
  Map<String, dynamic> json,
) => _BookRecommendationStats(
  downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
  recommendationCount: (json['recommendationCount'] as num?)?.toInt() ?? 0,
  upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BookRecommendationStatsToJson(
  _BookRecommendationStats instance,
) => <String, dynamic>{
  'downvotes': instance.downvotes,
  'recommendationCount': instance.recommendationCount,
  'upvotes': instance.upvotes,
  'viewCount': instance.viewCount,
};

_DailyTopic _$DailyTopicFromJson(Map<String, dynamic> json) => _DailyTopic(
  id: json['id'] as String? ?? '',
  topicName: json['topicName'] as String? ?? '',
  description: json['description'] as String? ?? '',
  fullDescription: json['fullDescription'] as String? ?? '',
  coverImageUrl: json['coverImageUrl'] as String? ?? '',
  isEnabled: json['isEnabled'] as bool? ?? true,
);

Map<String, dynamic> _$DailyTopicToJson(_DailyTopic instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicName': instance.topicName,
      'description': instance.description,
      'fullDescription': instance.fullDescription,
      'coverImageUrl': instance.coverImageUrl,
      'isEnabled': instance.isEnabled,
    };
