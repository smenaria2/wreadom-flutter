import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class ProfileVisibility with _$ProfileVisibility {
  const factory ProfileVisibility({
    bool? followers,
    bool? following,
    bool? testimonies,
    bool? feedPosts,
    bool? profilePicture,
  }) = _ProfileVisibility;

  factory ProfileVisibility.fromJson(Map<String, dynamic> json) => _$ProfileVisibilityFromJson(json);
}

@freezed
abstract class NotificationPreference with _$NotificationPreference {
  const factory NotificationPreference({
    required bool app,
    required bool browser,
  }) = _NotificationPreference;

  factory NotificationPreference.fromJson(Map<String, dynamic> json) => _$NotificationPreferenceFromJson(json);
}

@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    required NotificationPreference messages,
    required NotificationPreference groupMessages,
    required NotificationPreference comments,
    required NotificationPreference replies,
    required NotificationPreference followers,
    required NotificationPreference testimonials,
    required NotificationPreference likes,
    required NotificationPreference followedAuthorPosts,
    required NotificationPreference newCreations,
    required bool browserNotifications,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);
}

@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    String? id,
    required String userId,
    required dynamic bookId,
    required double position,
    required String label,
    required int timestamp,
    String? chapterTitle,
    int? chapterIndex,
    String? highlightedText,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, dynamic> json) => _$BookmarkFromJson(json);
}

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String username,
    required String email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? penName,
    String? privacyLevel,
    bool? isDeactivated,
    ProfileVisibility? profileVisibility,
    int? followersCount,
    int? followingCount,
    int? totalPoints,
    int? tier,
    int? pointsLastUpdatedAt,
    required List<dynamic> readingHistory,
    required List<dynamic> savedBooks,
    required List<Bookmark> bookmarks,
    String? preferredLanguage,
    List<String>? pinnedWorks,
    int? createdAt,
    int? lastLogin,
    Map<String, dynamic>? readingProgress,
    List<String>? fcmTokens,
    NotificationSettings? notificationSettings,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}
