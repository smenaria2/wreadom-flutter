// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileVisibility _$ProfileVisibilityFromJson(Map<String, dynamic> json) =>
    _ProfileVisibility(
      followers: json['followers'] as bool?,
      following: json['following'] as bool?,
      testimonies: json['testimonies'] as bool?,
      feedPosts: json['feedPosts'] as bool?,
      profilePicture: json['profilePicture'] as bool?,
    );

Map<String, dynamic> _$ProfileVisibilityToJson(_ProfileVisibility instance) =>
    <String, dynamic>{
      'followers': instance.followers,
      'following': instance.following,
      'testimonies': instance.testimonies,
      'feedPosts': instance.feedPosts,
      'profilePicture': instance.profilePicture,
    };

_NotificationPreference _$NotificationPreferenceFromJson(
  Map<String, dynamic> json,
) => _NotificationPreference(
  app: json['app'] as bool,
  browser: json['browser'] as bool,
);

Map<String, dynamic> _$NotificationPreferenceToJson(
  _NotificationPreference instance,
) => <String, dynamic>{'app': instance.app, 'browser': instance.browser};

_NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => _NotificationSettings(
  messages: NotificationPreference.fromJson(
    json['messages'] as Map<String, dynamic>,
  ),
  groupMessages: NotificationPreference.fromJson(
    json['groupMessages'] as Map<String, dynamic>,
  ),
  comments: NotificationPreference.fromJson(
    json['comments'] as Map<String, dynamic>,
  ),
  replies: NotificationPreference.fromJson(
    json['replies'] as Map<String, dynamic>,
  ),
  followers: NotificationPreference.fromJson(
    json['followers'] as Map<String, dynamic>,
  ),
  testimonials: NotificationPreference.fromJson(
    json['testimonials'] as Map<String, dynamic>,
  ),
  likes: NotificationPreference.fromJson(json['likes'] as Map<String, dynamic>),
  followedAuthorPosts: NotificationPreference.fromJson(
    json['followedAuthorPosts'] as Map<String, dynamic>,
  ),
  newCreations: NotificationPreference.fromJson(
    json['newCreations'] as Map<String, dynamic>,
  ),
  browserNotifications: json['browserNotifications'] as bool,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  _NotificationSettings instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'groupMessages': instance.groupMessages,
  'comments': instance.comments,
  'replies': instance.replies,
  'followers': instance.followers,
  'testimonials': instance.testimonials,
  'likes': instance.likes,
  'followedAuthorPosts': instance.followedAuthorPosts,
  'newCreations': instance.newCreations,
  'browserNotifications': instance.browserNotifications,
};

_Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => _Bookmark(
  id: json['id'] as String?,
  userId: json['userId'] as String,
  bookId: json['bookId'],
  position: (json['position'] as num).toDouble(),
  label: json['label'] as String,
  timestamp: (json['timestamp'] as num).toInt(),
  chapterTitle: json['chapterTitle'] as String?,
  chapterIndex: (json['chapterIndex'] as num?)?.toInt(),
  highlightedText: json['highlightedText'] as String?,
);

Map<String, dynamic> _$BookmarkToJson(_Bookmark instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'bookId': instance.bookId,
  'position': instance.position,
  'label': instance.label,
  'timestamp': instance.timestamp,
  'chapterTitle': instance.chapterTitle,
  'chapterIndex': instance.chapterIndex,
  'highlightedText': instance.highlightedText,
};

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: json['id'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String?,
  photoURL: json['photoURL'] as String?,
  bio: json['bio'] as String?,
  penName: json['penName'] as String?,
  privacyLevel: json['privacyLevel'] as String?,
  isDeactivated: json['isDeactivated'] as bool?,
  profileVisibility: json['profileVisibility'] == null
      ? null
      : ProfileVisibility.fromJson(
          json['profileVisibility'] as Map<String, dynamic>,
        ),
  followersCount: (json['followersCount'] as num?)?.toInt(),
  followingCount: (json['followingCount'] as num?)?.toInt(),
  totalPoints: (json['totalPoints'] as num?)?.toInt(),
  tier: (json['tier'] as num?)?.toInt(),
  pointsLastUpdatedAt: (json['pointsLastUpdatedAt'] as num?)?.toInt(),
  readingHistory: json['readingHistory'] as List<dynamic>,
  savedBooks: json['savedBooks'] as List<dynamic>,
  bookmarks: (json['bookmarks'] as List<dynamic>)
      .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
      .toList(),
  preferredLanguage: json['preferredLanguage'] as String?,
  pinnedWorks: (json['pinnedWorks'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: (json['createdAt'] as num?)?.toInt(),
  lastLogin: (json['lastLogin'] as num?)?.toInt(),
  readingProgress: json['readingProgress'] as Map<String, dynamic>?,
  notificationSettings: json['notificationSettings'] == null
      ? null
      : NotificationSettings.fromJson(
          json['notificationSettings'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'bio': instance.bio,
      'penName': instance.penName,
      'privacyLevel': instance.privacyLevel,
      'isDeactivated': instance.isDeactivated,
      'profileVisibility': instance.profileVisibility,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
      'totalPoints': instance.totalPoints,
      'tier': instance.tier,
      'pointsLastUpdatedAt': instance.pointsLastUpdatedAt,
      'readingHistory': instance.readingHistory,
      'savedBooks': instance.savedBooks,
      'bookmarks': instance.bookmarks,
      'preferredLanguage': instance.preferredLanguage,
      'pinnedWorks': instance.pinnedWorks,
      'createdAt': instance.createdAt,
      'lastLogin': instance.lastLogin,
      'readingProgress': instance.readingProgress,
      'notificationSettings': instance.notificationSettings,
    };
