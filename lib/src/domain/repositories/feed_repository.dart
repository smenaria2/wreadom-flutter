import 'dart:typed_data';
import '../models/comment.dart';
import '../models/feed_post.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> getFeedPosts({int limit = 10, dynamic lastDoc});
  Future<List<FeedPost>> getFollowingFeed(
    List<String> followedUserIds, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<List<FeedPost>> getUserFeedPosts(
    String userId, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<void> createFeedPost(FeedPost post);
  Future<void> updateFeedPost(String postId, Map<String, dynamic> updates);
  Future<void> deleteFeedPost(String postId);
  Future<void> toggleLike(String postId, String userId);
  Future<void> addComment(String postId, Map<String, dynamic> comment);
  Future<void> addCommentReply(
    String postId,
    String commentId,
    CommentReply reply,
  );
  Future<String> uploadPostImage(Uint8List bytes, String fileName);
  Future<FeedPost?> getFeedPost(String postId);
}
