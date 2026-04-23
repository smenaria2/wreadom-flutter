import 'package:freezed_annotation/freezed_annotation.dart';
import 'comment.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

@freezed
abstract class StoryImage with _$StoryImage {
  const factory StoryImage({
    required String id,
    required String url,
    String? caption,
    required List<String> likes,
  }) = _StoryImage;

  factory StoryImage.fromJson(Map<String, dynamic> json) =>
      _$StoryImageFromJson(json);
}

@freezed
abstract class FeedPost with _$FeedPost {
  const factory FeedPost({
    String? id,
    required String userId,
    required String username,
    required String
    type, // 'comment' | 'quote' | 'review' | 'testimony' | 'post'
    dynamic bookId,
    String? bookTitle,
    String? bookCover,
    required String text,
    String? quote,
    int? rating,
    String? chapterTitle,
    String? chapterId,
    required int timestamp,
    required List<String> likes,
    String? userPhotoURL,
    String? displayName,
    String? penName,
    List<Comment>? comments,
    String? targetUserId,
    String? targetUsername,
    String? targetUserDisplayName,
    String? targetUserPenName,
    String? privacy,
    required String visibility,
    String? imageUrl,
    List<StoryImage>? images,
    int? commentCount,
    Map<String, String>? mentions,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);
}
