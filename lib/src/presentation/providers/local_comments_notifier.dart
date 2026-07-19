import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/comment.dart';
import './feed_providers.dart';
import './comment_providers.dart';

/// Represents a comment or reply that failed to publish to the database.
class FailedComment {
  final String localId;
  final String targetId; // postId or bookId
  final Comment? comment; // if top-level comment
  final String? parentCommentId; // if reply
  final CommentReply? reply; // if reply
  final String error;

  FailedComment({
    required this.localId,
    required this.targetId,
    this.comment,
    this.parentCommentId,
    this.reply,
    required this.error,
  });
}

class FailedCommentsNotifier extends Notifier<List<FailedComment>> {
  @override
  List<FailedComment> build() {
    return const [];
  }

  void addFailedComment({
    required String targetId,
    Comment? comment,
    String? parentCommentId,
    CommentReply? reply,
    required String error,
  }) {
    final localId = '${DateTime.now().millisecondsSinceEpoch}_${comment?.userId ?? reply?.userId ?? "unknown"}';
    state = [
      ...state,
      FailedComment(
        localId: localId,
        targetId: targetId,
        comment: comment,
        parentCommentId: parentCommentId,
        reply: reply,
        error: error,
      )
    ];
  }

  void removeFailedComment(String localId) {
    state = state.where((item) => item.localId != localId).toList();
  }

  Future<void> retryComment(String localId) async {
    final item = state.firstWhere((element) => element.localId == localId);
    
    if (item.parentCommentId != null && item.reply != null) {
      // Retry reply comment submission
      if (item.comment?.feedPostId != null || item.targetId.startsWith('post_') || !item.targetId.contains(RegExp(r'^\d+$'))) {
        await ref.read(feedRepositoryProvider).addCommentReply(
          item.targetId,
          item.parentCommentId!,
          item.reply!,
        );
      } else {
        await ref.read(commentRepositoryProvider).addReply(
          item.parentCommentId!,
          item.reply!,
        );
      }
    } else if (item.comment != null) {
      // Retry top-level comment submission
      if (item.comment!.feedPostId != null) {
        await ref.read(feedRepositoryProvider).addComment(item.targetId, {
          'userId': item.comment!.userId,
          'username': item.comment!.username,
          'displayName': item.comment!.displayName,
          'userPhotoURL': item.comment!.userPhotoURL,
          'text': item.comment!.text,
        });
      } else {
        await ref.read(commentRepositoryProvider).addComment(item.comment!);
      }
    }
    
    // Remove from local failures on success
    removeFailedComment(localId);
  }
}

final failedCommentsProvider =
    NotifierProvider<FailedCommentsNotifier, List<FailedComment>>(
  FailedCommentsNotifier.new,
);
