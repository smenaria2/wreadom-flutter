import 'dart:typed_data';
import '../models/comment.dart';
import '../models/feed_post.dart';
import '../models/paged_result.dart';

abstract class FeedRepository {
  Future<List<FeedPost>> getFeedPosts({int limit = 10, dynamic lastDoc});
  Future<PagedResult<FeedPost>> getFeedPostsPage({
    int limit = 10,
    Object? cursor,
  });
  Future<List<FeedPost>> getFollowingFeed(
    List<String> followedUserIds, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<PagedResult<FeedPost>> getFollowingFeedPage(
    List<String> followedUserIds, {
    int limit = 10,
    Object? cursor,
  });
  Future<List<FeedPost>> getUserFeedPosts(
    String userId, {
    int limit = 10,
    dynamic lastDoc,
  });
  Future<PagedResult<FeedPost>> getUserFeedPostsPage(
    String userId, {
    int limit = 10,
    Object? cursor,
  });
  Future<void> createFeedPost(FeedPost post);
  Future<FeedPost?> findUserReviewPost({
    required String userId,
    required String bookId,
    String? chapterId,
  });
  Future<void> updateFeedPost(String postId, Map<String, dynamic> updates);
  Future<void> deleteFeedPost(String postId);
  Future<void> toggleLike(String postId, String userId);
  Future<void> addComment(String postId, Map<String, dynamic> comment);
  Future<void> addCommentReply(
    String postId,
    String commentId,
    CommentReply reply,
  );
  Future<void> updateCommentText(String postId, String commentId, String text);
  Future<void> deleteComment(String postId, String commentId);
  Future<void> updateReplyText(
    String postId,
    String commentId,
    String replyId,
    String text,
  );
  Future<void> deleteReply(String postId, String commentId, String replyId);
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
  );
  Future<void> toggleReplyLike(
    String postId,
    String commentId,
    String replyId,
    String userId,
  );
  Future<String> uploadPostImage(Uint8List bytes, String fileName);
  Future<FeedPost?> getFeedPost(String postId);
}
