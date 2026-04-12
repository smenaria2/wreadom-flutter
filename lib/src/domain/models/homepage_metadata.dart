import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';

part 'homepage_metadata.freezed.dart';
part 'homepage_metadata.g.dart';

@freezed
abstract class HomepageMetadata with _$HomepageMetadata {
  const factory HomepageMetadata({
    required List<UserModel> authors,
    required List<dynamic> dailyTopics,
    required Map<String, dynamic> recommendationStats,
    required dynamic lastUpdated,
    String? appVersion,
  }) = _HomepageMetadata;

  factory HomepageMetadata.fromJson(Map<String, dynamic> json) => _$HomepageMetadataFromJson(json);
}
