import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
import '../../data/repositories/firebase_feed_repository.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/models/feed_post.dart';
import 'auth_providers.dart';
import 'follow_providers.dart';

part 'feed_providers.g.dart';

enum FeedFilter { following, public, mine }

final filteredFeedPostsProvider =
    FutureProvider.family<List<FeedPost>, FeedFilter>((ref, filter) async {
      final repo = ref.watch(feedRepositoryProvider);
      switch (filter) {
        case FeedFilter.following:
          final following = await ref.watch(followingListProvider.future);
          return repo.getFollowingFeed(following);
        case FeedFilter.public:
          return repo.getFeedPosts();
        case FeedFilter.mine:
          final user = await ref.watch(currentUserProvider.future);
          if (user == null) return [];
          return repo.getUserFeedPosts(user.id);
      }
    });

@riverpod
FeedRepository feedRepository(Ref ref) {
  return FirebaseFeedRepository();
}

@riverpod
Future<List<FeedPost>> feedPosts(Ref ref) async {
  return ref.watch(feedRepositoryProvider).getFeedPosts();
}

@riverpod
Future<List<FeedPost>> userFeedPosts(Ref ref, String userId) async {
  return ref.watch(feedRepositoryProvider).getUserFeedPosts(userId);
}

@riverpod
Future<FeedPost?> singlePost(Ref ref, String postId) async {
  return ref.watch(feedRepositoryProvider).getFeedPost(postId);
}
