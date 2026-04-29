import 'package:freezed_annotation/freezed_annotation.dart';
import '../user_model.dart';

part 'homepage_metadata.freezed.dart';
part 'homepage_metadata.g.dart';

@freezed
abstract class HomepageMetadata with _$HomepageMetadata {
  const factory HomepageMetadata({
    @Default([]) List<UserModel> authors,
    @Default({}) Map<String, BookRecommendationStats> recommendationStats,
    @Default([]) List<DailyTopic> dailyTopics,
  }) = _HomepageMetadata;

  factory HomepageMetadata.fromJson(Map<String, dynamic> json) =>
      _$HomepageMetadataFromJson(json);
}

@freezed
abstract class BookRecommendationStats with _$BookRecommendationStats {
  const factory BookRecommendationStats({
    @Default(0) int downvotes,
    @Default(0) int recommendationCount,
    @Default(0) int upvotes,
    @Default(0) int viewCount,
  }) = _BookRecommendationStats;

  factory BookRecommendationStats.fromJson(Map<String, dynamic> json) =>
      _$BookRecommendationStatsFromJson(json);
}

@freezed
abstract class DailyTopic with _$DailyTopic {
  const DailyTopic._();

  const factory DailyTopic({
    @Default('') String id,
    @Default('') String topicName,
    @Default('') String description,
    @Default('') String fullDescription,
    @Default('') String coverImageUrl,
    @Default(true) bool isEnabled,
    dynamic timestamp,
    dynamic createdAt,
    dynamic updatedAt,
  }) = _DailyTopic;

  factory DailyTopic.fromJson(Map<String, dynamic> json) =>
      _$DailyTopicFromJson(json);

  int get sortTimestamp =>
      _timestampToMillis(timestamp) ??
      _timestampToMillis(updatedAt) ??
      _timestampToMillis(createdAt) ??
      0;
}

int? _timestampToMillis(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  try {
    final milliseconds = value.millisecondsSinceEpoch;
    if (milliseconds is int) return milliseconds;
  } catch (_) {
    return null;
  }
  return null;
}
