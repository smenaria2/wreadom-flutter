import '../models/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getBookComments(String bookId);
  Future<Comment?> getUserBookReview(String bookId, String userId);
  Future<String> addComment(Comment comment);
  Future<String> upsertBookReview(Comment comment);
  Future<void> addReply(String commentId, CommentReply reply);
  Future<List<Comment>> getFeedPostComments(String postId);
  Future<void> deleteComment(String commentId);
  Future<void> deleteReply(String commentId, String replyId);
  Future<void> updateCommentText(String commentId, String text);
  Future<void> updateReplyText(String commentId, String replyId, String text);
  Future<void> toggleCommentLike(String commentId, String userId);
  Future<void> toggleReplyLike(String commentId, String replyId, String userId);
  Future<void> toggleReviewHighlight({
    required String commentId,
    required String bookId,
    required String authorId,
    int maxHighlighted = 3,
  });
}
