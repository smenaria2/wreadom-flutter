import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/comment.dart';
import './comment_providers.dart';
import './feed_providers.dart';

enum FailedCommentTarget { book, feedPost }

enum LocalCommentStatus { pending, failed }

/// Represents a comment or reply that failed to publish to the database.
class FailedComment {
  const FailedComment({
    required this.localId,
    required this.targetId,
    required this.target,
    this.comment,
    this.parentCommentId,
    this.reply,
    required this.error,
    this.status = LocalCommentStatus.failed,
  });

  final String localId;
  final String targetId;
  final FailedCommentTarget target;
  final Comment? comment;
  final String? parentCommentId;
  final CommentReply? reply;
  final String error;
  final LocalCommentStatus status;

  bool get isPending => status == LocalCommentStatus.pending;

  FailedComment copyWith({String? error, LocalCommentStatus? status}) {
    return FailedComment(
      localId: localId,
      targetId: targetId,
      target: target,
      comment: comment,
      parentCommentId: parentCommentId,
      reply: reply,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }
}

class FailedCommentsNotifier extends Notifier<List<FailedComment>> {
  final Set<String> _retrying = <String>{};
  int _sequence = 0;

  @override
  List<FailedComment> build() => const [];

  String addPendingComment({
    required String targetId,
    required FailedCommentTarget target,
    Comment? comment,
    String? parentCommentId,
    CommentReply? reply,
  }) {
    final localId = addFailedComment(
      targetId: targetId,
      target: target,
      comment: comment,
      parentCommentId: parentCommentId,
      reply: reply,
      error: '',
    );
    state = [
      for (final item in state)
        if (item.localId == localId)
          item.copyWith(status: LocalCommentStatus.pending)
        else
          item,
    ];
    return localId;
  }

  String addFailedComment({
    required String targetId,
    required FailedCommentTarget target,
    Comment? comment,
    String? parentCommentId,
    CommentReply? reply,
    required String error,
  }) {
    final normalizedTargetId = targetId.trim();
    if (normalizedTargetId.isEmpty) {
      throw ArgumentError.value(targetId, 'targetId', 'Must not be empty.');
    }
    if ((comment == null) == (reply == null)) {
      throw ArgumentError('Provide exactly one comment or reply.');
    }
    if (reply != null && parentCommentId?.trim().isNotEmpty != true) {
      throw ArgumentError('A failed reply requires its parent comment ID.');
    }

    final localId =
        '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}_${comment?.userId ?? reply!.userId}';
    state = [
      FailedComment(
        localId: localId,
        targetId: normalizedTargetId,
        target: target,
        comment: comment,
        parentCommentId: parentCommentId,
        reply: reply,
        error: error,
      ),
      ...state,
    ];
    return localId;
  }

  void markFailed(String localId, String error) {
    state = [
      for (final item in state)
        if (item.localId == localId)
          item.copyWith(error: error, status: LocalCommentStatus.failed)
        else
          item,
    ];
  }

  void removeFailedComment(String localId) {
    state = state.where((item) => item.localId != localId).toList();
  }

  Future<void> retryComment(String localId) async {
    if (!_retrying.add(localId)) return;
    try {
      FailedComment? item;
      for (final candidate in state) {
        if (candidate.localId == localId) {
          item = candidate;
          break;
        }
      }
      if (item == null) return;

      switch (item.target) {
        case FailedCommentTarget.feedPost:
          await _retryFeedComment(item);
          _refreshFeedComment(item.targetId);
        case FailedCommentTarget.book:
          await _retryBookComment(item);
          ref.invalidate(liveBookCommentsProvider(item.targetId));
          ref.invalidate(bookCommentsProvider(item.targetId));
      }

      removeFailedComment(localId);
    } finally {
      _retrying.remove(localId);
    }
  }

  Future<void> _retryFeedComment(FailedComment item) async {
    if (item.reply != null) {
      await ref
          .read(feedRepositoryProvider)
          .addCommentReply(item.targetId, item.parentCommentId!, item.reply!);
      return;
    }

    final comment = item.comment!;
    await ref.read(feedRepositoryProvider).addComment(item.targetId, {
      'userId': comment.userId,
      'username': comment.username,
      'displayName': comment.displayName,
      'penName': comment.penName,
      'userPhotoURL': comment.userPhotoURL,
      'text': comment.text,
    });
  }

  Future<void> _retryBookComment(FailedComment item) async {
    if (item.reply != null) {
      await ref
          .read(commentRepositoryProvider)
          .addReply(item.parentCommentId!, item.reply!);
      return;
    }
    await ref.read(commentRepositoryProvider).addComment(item.comment!);
  }

  void _refreshFeedComment(String postId) {
    ref.invalidate(liveFeedPostCommentsProvider(postId));
    ref.invalidate(liveSinglePostProvider(postId));
    for (final filter in FeedFilter.values) {
      unawaited(
        ref.read(pagedFeedPostsProvider(filter).notifier).refreshInPlace(),
      );
    }
  }
}

final failedCommentsProvider =
    NotifierProvider<FailedCommentsNotifier, List<FailedComment>>(
      FailedCommentsNotifier.new,
    );
