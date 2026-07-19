import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import './feed_providers.dart';

/// Represents a feed post or review that failed to publish to the database.
class FailedPost {
  final String localId;
  final FeedPost post;
  final String error;

  FailedPost({
    required this.localId,
    required this.post,
    required this.error,
  });
}

class FailedPostsNotifier extends Notifier<List<FailedPost>> {
  @override
  List<FailedPost> build() {
    return const [];
  }

  void addFailedPost(FeedPost post, String error) {
    final localId = '${DateTime.now().millisecondsSinceEpoch}_${post.userId}';
    state = [
      ...state,
      FailedPost(
        localId: localId,
        post: post,
        error: error,
      )
    ];
  }

  void removeFailedPost(String localId) {
    state = state.where((item) => item.localId != localId).toList();
  }

  Future<void> retryPost(String localId) async {
    final item = state.firstWhere((element) => element.localId == localId);
    
    // Attempt to publish
    await ref.read(feedRepositoryProvider).createFeedPost(item.post);
    
    // Remove from local failures on success
    removeFailedPost(localId);
  }
}

final failedPostsProvider =
    NotifierProvider<FailedPostsNotifier, List<FailedPost>>(
  FailedPostsNotifier.new,
);
