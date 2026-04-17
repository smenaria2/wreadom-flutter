import '../models/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getBookComments(String bookId);
  Future<String> addComment(Comment comment);
  Future<void> addReply(String commentId, CommentReply reply);
  Future<List<Comment>> getFeedPostComments(String postId);
  Future<void> deleteComment(String commentId);
  Future<void> deleteReply(String commentId, String replyId);
  Future<void> toggleCommentLike(String commentId, String userId);
  Future<void> toggleReplyLike(String commentId, String replyId, String userId);
}
