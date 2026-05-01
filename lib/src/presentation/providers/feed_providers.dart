import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_feed_repository.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/models/feed_post.dart';
import 'auth_providers.dart';
import 'follow_providers.dart';
import 'paged_list_state.dart';

part 'feed_providers.g.dart';

enum FeedFilter { following, public, mine }

const int feedPageSize = 10;

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

final pagedFeedPostsProvider =
    NotifierProvider.family<
      PagedFeedPostsController,
      PagedListState<FeedPost>,
      FeedFilter
    >(PagedFeedPostsController.new);

final pagedUserFeedPostsProvider =
    NotifierProvider.family<
      PagedUserFeedPostsController,
      PagedListState<FeedPost>,
      String
    >(PagedUserFeedPostsController.new);

class PagedFeedPostsController extends Notifier<PagedListState<FeedPost>> {
  PagedFeedPostsController(this._filter);

  final FeedFilter _filter;
  Object? _cursor;

  @override
  PagedListState<FeedPost> build() {
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    _cursor = null;
    state = const PagedListState(isInitialLoading: true);
    await _load(reset: true);
  }

  Future<void> loadMore() => _load();

  Future<void> _load({bool reset = false}) async {
    if (state.isLoadingMore || (state.isInitialLoading && !reset)) return;
    if (!reset && !state.hasMore) return;
    if (!reset) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final repo = ref.read(feedRepositoryProvider);
      final PagedResult<FeedPost> page = switch (_filter) {
        FeedFilter.following => await repo.getFollowingFeedPage(
          await ref.read(followingListProvider.future),
          limit: feedPageSize,
          cursor: _cursor,
        ),
        FeedFilter.public => await repo.getFeedPostsPage(
          limit: feedPageSize,
          cursor: _cursor,
        ),
        FeedFilter.mine => await _loadMine(repo),
      };
      if (!ref.mounted) return;
      _cursor = page.nextCursor;
      state = PagedListState(
        items: reset ? page.items : [...state.items, ...page.items],
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<PagedResult<FeedPost>> _loadMine(FeedRepository repo) async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    return repo.getUserFeedPostsPage(
      user.id,
      limit: feedPageSize,
      cursor: _cursor,
    );
  }
}

class PagedUserFeedPostsController extends Notifier<PagedListState<FeedPost>> {
  PagedUserFeedPostsController(this._userId);

  final String _userId;
  Object? _cursor;

  @override
  PagedListState<FeedPost> build() {
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    _cursor = null;
    state = const PagedListState(isInitialLoading: true);
    await _load(reset: true);
  }

  Future<void> loadMore() => _load();

  Future<void> _load({bool reset = false}) async {
    if (state.isLoadingMore || (state.isInitialLoading && !reset)) return;
    if (!reset && !state.hasMore) return;
    if (!reset) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }

    try {
      final page = await ref
          .read(feedRepositoryProvider)
          .getUserFeedPostsPage(_userId, limit: feedPageSize, cursor: _cursor);
      if (!ref.mounted) return;
      _cursor = page.nextCursor;
      state = PagedListState(
        items: reset ? page.items : [...state.items, ...page.items],
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }
}

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
