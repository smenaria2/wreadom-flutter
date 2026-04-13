// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoryImage _$StoryImageFromJson(Map<String, dynamic> json) => _StoryImage(
  id: json['id'] as String,
  url: json['url'] as String,
  caption: json['caption'] as String?,
  likes: (json['likes'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$StoryImageToJson(_StoryImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'caption': instance.caption,
      'likes': instance.likes,
    };

_FeedPost _$FeedPostFromJson(Map<String, dynamic> json) => _FeedPost(
  id: json['id'] as String?,
  userId: json['userId'] as String,
  username: json['username'] as String,
  type: json['type'] as String,
  bookId: json['bookId'],
  bookTitle: json['bookTitle'] as String?,
  bookCover: json['bookCover'] as String?,
  text: json['text'] as String,
  quote: json['quote'] as String?,
  rating: (json['rating'] as num?)?.toInt(),
  chapterTitle: json['chapterTitle'] as String?,
  chapterId: json['chapterId'] as String?,
  timestamp: (json['timestamp'] as num).toInt(),
  likes: (json['likes'] as List<dynamic>).map((e) => e as String).toList(),
  userPhotoURL: json['userPhotoURL'] as String?,
  displayName: json['displayName'] as String?,
  penName: json['penName'] as String?,
  comments: (json['comments'] as List<dynamic>?)
      ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
      .toList(),
  targetUserId: json['targetUserId'] as String?,
  targetUsername: json['targetUsername'] as String?,
  targetUserDisplayName: json['targetUserDisplayName'] as String?,
  targetUserPenName: json['targetUserPenName'] as String?,
  privacy: json['privacy'] as String?,
  visibility: json['visibility'] as String,
  imageUrl: json['imageUrl'] as String?,
  images: (json['images'] as List<dynamic>?)
      ?.map((e) => StoryImage.fromJson(e as Map<String, dynamic>))
      .toList(),
  commentCount: (json['commentCount'] as num?)?.toInt(),
  mentions: (json['mentions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$FeedPostToJson(_FeedPost instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'username': instance.username,
  'type': instance.type,
  'bookId': instance.bookId,
  'bookTitle': instance.bookTitle,
  'bookCover': instance.bookCover,
  'text': instance.text,
  'quote': instance.quote,
  'rating': instance.rating,
  'chapterTitle': instance.chapterTitle,
  'chapterId': instance.chapterId,
  'timestamp': instance.timestamp,
  'likes': instance.likes,
  'userPhotoURL': instance.userPhotoURL,
  'displayName': instance.displayName,
  'penName': instance.penName,
  'comments': instance.comments,
  'targetUserId': instance.targetUserId,
  'targetUsername': instance.targetUsername,
  'targetUserDisplayName': instance.targetUserDisplayName,
  'targetUserPenName': instance.targetUserPenName,
  'privacy': instance.privacy,
  'visibility': instance.visibility,
  'imageUrl': instance.imageUrl,
  'images': instance.images,
  'commentCount': instance.commentCount,
  'mentions': instance.mentions,
};
