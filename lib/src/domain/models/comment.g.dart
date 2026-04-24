// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentReply _$CommentReplyFromJson(Map<String, dynamic> json) =>
    _CommentReply(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      penName: json['penName'] as String?,
      text: json['text'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      userPhotoURL: json['userPhotoURL'] as String?,
      likes: (json['likes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mentions: (json['mentions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$CommentReplyToJson(_CommentReply instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'penName': instance.penName,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'userPhotoURL': instance.userPhotoURL,
      'likes': instance.likes,
      'mentions': instance.mentions,
    };

_Comment _$CommentFromJson(Map<String, dynamic> json) => _Comment(
  id: json['id'] as String?,
  bookId: json['bookId'],
  bookTitle: json['bookTitle'] as String?,
  userId: json['userId'] as String,
  username: json['username'] as String,
  text: json['text'] as String,
  rating: (json['rating'] as num?)?.toInt(),
  chapterTitle: json['chapterTitle'] as String?,
  chapterIndex: (json['chapterIndex'] as num?)?.toInt(),
  chapterId: json['chapterId'] as String?,
  quote: json['quote'] as String?,
  timestamp: (json['timestamp'] as num).toInt(),
  feedPostId: json['feedPostId'] as String?,
  userPhotoURL: json['userPhotoURL'] as String?,
  displayName: json['displayName'] as String?,
  penName: json['penName'] as String?,
  replies: (json['replies'] as List<dynamic>?)
      ?.map((e) => CommentReply.fromJson(e as Map<String, dynamic>))
      .toList(),
  likes: (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList(),
  mentions: (json['mentions'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  isHighlighted: json['isHighlighted'] as bool?,
  highlightedAt: (json['highlightedAt'] as num?)?.toInt(),
  highlightedByUserId: json['highlightedByUserId'] as String?,
  audioUrl: json['audioUrl'] as String?,
  audioObjectKey: json['audioObjectKey'] as String?,
  audioDurationMs: (json['audioDurationMs'] as num?)?.toInt(),
  audioMimeType: json['audioMimeType'] as String?,
  audioSizeBytes: (json['audioSizeBytes'] as num?)?.toInt(),
);

Map<String, dynamic> _$CommentToJson(_Comment instance) => <String, dynamic>{
  'id': instance.id,
  'bookId': instance.bookId,
  'bookTitle': instance.bookTitle,
  'userId': instance.userId,
  'username': instance.username,
  'text': instance.text,
  'rating': instance.rating,
  'chapterTitle': instance.chapterTitle,
  'chapterIndex': instance.chapterIndex,
  'chapterId': instance.chapterId,
  'quote': instance.quote,
  'timestamp': instance.timestamp,
  'feedPostId': instance.feedPostId,
  'userPhotoURL': instance.userPhotoURL,
  'displayName': instance.displayName,
  'penName': instance.penName,
  'replies': instance.replies,
  'likes': instance.likes,
  'mentions': instance.mentions,
  'isHighlighted': instance.isHighlighted,
  'highlightedAt': instance.highlightedAt,
  'highlightedByUserId': instance.highlightedByUserId,
  'audioUrl': instance.audioUrl,
  'audioObjectKey': instance.audioObjectKey,
  'audioDurationMs': instance.audioDurationMs,
  'audioMimeType': instance.audioMimeType,
  'audioSizeBytes': instance.audioSizeBytes,
};
