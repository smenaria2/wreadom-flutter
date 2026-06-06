import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_feed_repository.dart';
import '../../data/utils/firestore_utils.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/user_model.dart';
import '../../utils/map_utils.dart';
import 'auth_providers.dart';
import 'follow_providers.dart';
import 'paged_list_state.dart';

part 'feed_providers.g.dart';

enum FeedFilter { following, public, mine }

const int feedPageSize = 10;
const Duration followingFeedLoadTimeout = Duration(seconds: 15);

String? _currentFirebaseUserIdOrNull() {
  try {
    return fb_auth.FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}

String? _effectiveFeedUserId(AsyncValue<UserModel?> authState) {
  final profileUserId = authState.asData?.value?.id.trim();
  if (profileUserId != null && profileUserId.isNotEmpty) return profileUserId;
  final firebaseUserId = _currentFirebaseUserIdOrNull()?.trim();
  if (firebaseUserId == null || firebaseUserId.isEmpty) return null;
  return firebaseUserId;
}

final filteredFeedPostsProvider =
    FutureProvider.family<List<FeedPost>, FeedFilter>((ref, filter) async {
      final repo = ref.watch(feedRepositoryProvider);
      switch (filter) {
        case FeedFilter.following:
          final user = ref.watch(currentUserProvider).asData?.value;
          final userId = user?.id ?? _currentFirebaseUserIdOrNull();
          if (userId == null || userId.trim().isEmpty) return [];
          final following = await ref
              .read(followRepositoryProvider)
              .getFollowingList(userId)
              .timeout(followingFeedLoadTimeout);
          return repo
              .getFollowingFeed(following)
              .timeout(followingFeedLoadTimeout);
        case FeedFilter.public:
          return repo.getFeedPosts();
        case FeedFilter.mine:
          final user = ref.watch(currentUserProvider).asData?.value;
          final userId = user?.id ?? _currentFirebaseUserIdOrNull();
          if (userId == null || userId.trim().isEmpty) return [];
          return repo.getUserFeedPosts(userId);
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
  int _loadGeneration = 0;
  String? _activeUserId;

  @override
  PagedListState<FeedPost> build() {
    final initialAuthState = ref.read(currentUserProvider);
    ref.listen(currentUserProvider, (previous, next) {
      if (_filter == FeedFilter.public) return;
      final previousUserId = previous == null
          ? null
          : _effectiveFeedUserId(previous);
      final nextUserId = _effectiveFeedUserId(next);
      final becameReady = previous?.isLoading == true && !next.isLoading;
      if (!next.isLoading && (becameReady || previousUserId != nextUserId)) {
        _refreshForAuthUser(nextUserId);
      }
    });
    Future.microtask(() {
      if (_filter == FeedFilter.public) {
        refresh();
        return;
      }
      final userId = _effectiveFeedUserId(initialAuthState);
      if (userId != null || !initialAuthState.isLoading) {
        _refreshForAuthUser(userId);
      }
    });
    return const PagedListState();
  }

  void _refreshForAuthUser(String? userId) {
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    _cursor = null;
    _loadGeneration++;
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
    final generation = _loadGeneration;

    try {
      final repo = ref.read(feedRepositoryProvider);
      final PagedResult<FeedPost> page = switch (_filter) {
        FeedFilter.following => await _loadFollowing(repo),
        FeedFilter.public => await repo.getFeedPostsPage(
          limit: feedPageSize,
          cursor: _cursor,
        ),
        FeedFilter.mine => await _loadMine(repo),
      };
      if (!ref.mounted || generation != _loadGeneration) return;
      _cursor = page.nextCursor;
      state = PagedListState(
        items: reset ? page.items : [...state.items, ...page.items],
        hasMore: page.hasMore,
      );
    } catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        isInitialLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<PagedResult<FeedPost>> _loadFollowing(FeedRepository repo) async {
    final userId = _effectiveFeedUserId(ref.read(currentUserProvider));
    if (userId == null || userId.trim().isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    final following = await ref
        .read(followRepositoryProvider)
        .getFollowingList(userId)
        .timeout(followingFeedLoadTimeout);
    if (following.isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    return repo
        .getFollowingFeedPage(following, limit: feedPageSize, cursor: _cursor)
        .timeout(followingFeedLoadTimeout);
  }

  Future<PagedResult<FeedPost>> _loadMine(FeedRepository repo) async {
    final userId = _effectiveFeedUserId(ref.read(currentUserProvider));
    if (userId == null || userId.trim().isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    return repo.getUserFeedPostsPage(
      userId,
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

final liveSinglePostProvider = StreamProvider.family<FeedPost?, String>((
  ref,
  postId,
) async* {
  final initial = await ref.watch(feedRepositoryProvider).getFeedPost(postId);
  if (initial != null) yield initial;

  yield* FirebaseFirestore.instance
      .collection('feed')
      .doc(postId)
      .snapshots()
      .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
        return FeedPost.fromJson(data);
      });
});
