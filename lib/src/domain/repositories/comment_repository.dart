import '../models/comment.dart';

abstract class CommentRepository {
  Future<List<Comment>> getBookComments(String bookId);
  Future<String> addComment(Comment comment);
  Future<void> addReply(String commentId, CommentReply reply);
  Future<void> deleteComment(String commentId);
}
