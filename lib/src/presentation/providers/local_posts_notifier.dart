import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/feed_post.dart';
import './feed_providers.dart';

/// Represents a feed post or review that failed to publish to the database.
class FailedPost {
  const FailedPost({
    required this.localId,
    required this.post,
    required this.error,
    this.isPending = false,
  });

  final String localId;
  final FeedPost post;
  final String error;
  final bool isPending;

  FailedPost copyWith({String? error, bool? isPending}) => FailedPost(
    localId: localId,
    post: post,
    error: error ?? this.error,
    isPending: isPending ?? this.isPending,
  );
}

class FailedPostsNotifier extends Notifier<List<FailedPost>> {
  final Set<String> _retrying = <String>{};
  int _sequence = 0;

  @override
  List<FailedPost> build() => const [];

  String addPendingPost(FeedPost post) {
    final localId = _nextLocalId(post);
    state = [
      FailedPost(localId: localId, post: post, error: '', isPending: true),
      ...state,
    ];
    return localId;
  }

  void addFailedPost(FeedPost post, String error) {
    final localId = _nextLocalId(post);
    state = [FailedPost(localId: localId, post: post, error: error), ...state];
  }

  String _nextLocalId(FeedPost post) =>
      '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}_${post.userId}';

  void markFailed(String localId, String error) {
    state = [
      for (final item in state)
        if (item.localId == localId)
          item.copyWith(error: error, isPending: false)
        else
          item,
    ];
  }

  void removeFailedPost(String localId) {
    state = state.where((item) => item.localId != localId).toList();
  }

  Future<void> retryPost(String localId) async {
    if (!_retrying.add(localId)) return;
    try {
      FailedPost? item;
      for (final candidate in state) {
        if (candidate.localId == localId) {
          item = candidate;
          break;
        }
      }
      if (item == null) return;

      try {
        await ref.read(feedRepositoryProvider).createFeedPost(item.post);
      } catch (error) {
        state = [
          for (final candidate in state)
            if (candidate.localId == localId)
              FailedPost(
                localId: candidate.localId,
                post: candidate.post,
                error: error.toString(),
              )
            else
              candidate,
        ];
        rethrow;
      }

      removeFailedPost(localId);
      _refreshFeeds(item.post.userId);
    } finally {
      _retrying.remove(localId);
    }
  }

  void _refreshFeeds(String userId) {
    ref.invalidate(feedPostsProvider);
    for (final filter in FeedFilter.values) {
      ref.invalidate(filteredFeedPostsProvider(filter));
      unawaited(
        ref.read(pagedFeedPostsProvider(filter).notifier).refreshInPlace(),
      );
    }
    ref.invalidate(userFeedPostsProvider(userId));
    unawaited(
      ref.read(pagedUserFeedPostsProvider(userId).notifier).refreshInPlace(),
    );
  }
}

final failedPostsProvider =
    NotifierProvider<FailedPostsNotifier, List<FailedPost>>(
      FailedPostsNotifier.new,
    );

/// Plan-facing name retained for review-specific consumers.
final failedReviewsProvider = failedPostsProvider;
