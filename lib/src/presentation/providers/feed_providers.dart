import 'dart:async';

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
import '../../domain/models/book.dart';
import '../../utils/map_utils.dart';
import 'auth_providers.dart';
import 'follow_providers.dart';
import 'paged_list_state.dart';
import '../../data/services/startup_performance.dart';
import 'startup_cache_provider.dart';
import 'book_providers.dart';

part 'feed_providers.g.dart';

enum FeedFilter { following, public, mine }

class QuestionLeafAnswersQuery {
  const QuestionLeafAnswersQuery({
    required this.bookId,
    required this.leafId,
    required this.question,
  });

  final String bookId;
  final String leafId;
  final String question;

  @override
  bool operator ==(Object other) {
    return other is QuestionLeafAnswersQuery &&
        other.bookId == bookId &&
        other.leafId == leafId &&
        other.question == question;
  }

  @override
  int get hashCode => Object.hash(bookId, leafId, question);
}

const int feedPageSize = 10;
const Duration followingFeedLoadTimeout = Duration(seconds: 4);

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

final feedBookEnrichmentProvider =
    NotifierProvider<FeedBookEnrichmentController, Map<String, Book>>(
      FeedBookEnrichmentController.new,
    );

class FeedBookEnrichmentController extends Notifier<Map<String, Book>> {
  final Set<String> _pending = <String>{};
  final Map<String, DateTime> _lastAttempt = <String, DateTime>{};
  final Set<String> _retriedAfterRefresh = <String>{};
  bool _scheduled = false;
  static const _retryCooldown = Duration(seconds: 30);

  @override
  Map<String, Book> build() => const {};

  void request(String bookId) {
    final normalized = bookId.trim();
    if (normalized.isEmpty || state.containsKey(normalized)) return;
    final attemptedAt = _lastAttempt[normalized];
    if (attemptedAt != null &&
        DateTime.now().difference(attemptedAt) < _retryCooldown) {
      return;
    }
    _retriedAfterRefresh.remove(normalized);
    _queue(normalized);
  }

  void _queue(String bookId) {
    _pending.add(bookId);
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_flush);
  }

  Future<void> _flush() async {
    _scheduled = false;
    final ids = _pending.toList(growable: false);
    _pending.clear();
    if (ids.isEmpty) return;
    final attemptedAt = DateTime.now();
    for (final id in ids) {
      _lastAttempt[id] = attemptedAt;
    }
    var resolvedIds = const <String>{};
    try {
      final books = await ref.read(bookRepositoryProvider).getBooksByIds(ids);
      if (!ref.mounted) return;
      resolvedIds = books.map((book) => book.id).toSet();
      if (books.isNotEmpty) {
        state = {...state, for (final book in books) book.id: book};
      }
    } catch (_) {
      // Cards already render their stored fields or placeholders.
    }
    final unresolved = ids
        .where(
          (id) => !resolvedIds.contains(id) && _retriedAfterRefresh.add(id),
        )
        .toList(growable: false);
    if (unresolved.isEmpty) return;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 4200), () {
        if (!ref.mounted) return;
        for (final id in unresolved) {
          if (!state.containsKey(id)) _queue(id);
        }
      }),
    );
  }
}

final questionLeafAnswersProvider =
    FutureProvider.family<List<FeedPost>, QuestionLeafAnswersQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(feedRepositoryProvider)
          .getQuestionAnswers(
            bookId: query.bookId,
            questionLeafId: query.leafId,
            question: query.question,
          );
    });

class PagedFeedPostsController extends Notifier<PagedListState<FeedPost>> {
  PagedFeedPostsController(this._filter);

  final FeedFilter _filter;
  Object? _cursor;
  int _loadGeneration = 0;
  String? _activeUserId;
  Future<void>? _activeRefresh;

  @override
  PagedListState<FeedPost> build() {
    final initialAuthState = ref.read(currentUserProvider);
    final initialUserId = _effectiveFeedUserId(initialAuthState);
    _activeUserId = initialUserId;
    final cachedItems = _readCachedFirstPage(initialUserId);
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
        refreshInPlace();
        return;
      }
      final userId = _effectiveFeedUserId(initialAuthState);
      if (userId != null || !initialAuthState.isLoading) {
        _activeUserId = userId;
        unawaited(refreshInPlace());
      }
    });
    if (cachedItems.isNotEmpty) {
      StartupPerformance.mark(
        'first_nonempty_state',
        page: 'feed_${_filter.name}',
        outcome: 'cache',
        once: true,
      );
    }
    return PagedListState(
      items: cachedItems,
      isInitialLoading: cachedItems.isEmpty,
    );
  }

  List<FeedPost> _readCachedFirstPage(String? userId) {
    if (_filter != FeedFilter.public && userId == null) return const [];
    return ref
            .read(startupDataCacheProvider)
            ?.read<List<FeedPost>>(
              scope: 'feed_${_filter.name}',
              userId: _filter == FeedFilter.public ? null : userId,
              decode: (json) => (json! as List)
                  .map(
                    (item) => FeedPost.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList(growable: false),
            ) ??
        const [];
  }

  void _refreshForAuthUser(String? userId) {
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    _cursor = null;
    _loadGeneration++;
    _activeRefresh = null;
    final cachedItems = _readCachedFirstPage(userId);
    state = PagedListState(
      items: cachedItems,
      isInitialLoading: cachedItems.isEmpty,
    );
    Future.microtask(() => refreshInPlace());
  }

  Future<void> refresh() async {
    await refreshInPlace();
  }

  Future<void> refreshInPlace() async {
    final active = _activeRefresh;
    if (active != null) return active;
    late final Future<void> refresh;
    refresh = _performRefreshInPlace();
    _activeRefresh = refresh;
    unawaited(
      refresh.then<void>((_) {
        if (identical(_activeRefresh, refresh)) _activeRefresh = null;
      }),
    );
    return refresh;
  }

  Future<void> _performRefreshInPlace() async {
    _cursor = null;
    _loadGeneration++;
    final fallbackItems = state.items;
    final fallbackHasMore = state.hasMore;
    if (state.items.isEmpty) {
      state = const PagedListState(isInitialLoading: true);
    } else {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: true,
        isLoadingMore: false,
        hasMore: true,
        clearError: true,
      );
    }
    await _load(
      reset: true,
      fallbackItemsOnEmptyReset: fallbackItems,
      fallbackHasMoreOnEmptyReset: fallbackHasMore,
    );
  }

  Future<void> loadMore() => _load();

  void removePost(String postId) {
    if (postId.trim().isEmpty) return;
    final nextItems = state.items
        .where((post) => post.id != postId)
        .toList(growable: false);
    if (nextItems.length == state.items.length) return;
    state = state.copyWith(items: nextItems, clearError: true);
  }

  Future<void> _load({
    bool reset = false,
    List<FeedPost>? fallbackItemsOnEmptyReset,
    bool? fallbackHasMoreOnEmptyReset,
  }) async {
    if (state.isLoadingMore ||
        (state.isInitialLoading && !reset) ||
        (state.isRefreshing && !reset)) {
      return;
    }
    if (!reset && !state.hasMore) return;
    if (!reset) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    final generation = _loadGeneration;

    try {
      final repo = ref.read(feedRepositoryProvider);
      final PagedResult<FeedPost> page = switch (_filter) {
        FeedFilter.following => await _loadFollowing(repo),
        FeedFilter.public =>
          await repo
              .getFeedPostsPage(limit: feedPageSize, cursor: _cursor)
              .timeout(followingFeedLoadTimeout),
        FeedFilter.mine => await _loadMine(repo),
      };
      if (!ref.mounted || generation != _loadGeneration) return;
      _cursor = page.nextCursor;
      final nextItems = reset ? page.items : [...state.items, ...page.items];
      final useFallbackItems =
          reset &&
          nextItems.isEmpty &&
          fallbackItemsOnEmptyReset != null &&
          fallbackItemsOnEmptyReset.isNotEmpty;
      if (reset && page.items.isNotEmpty) {
        final userId = _filter == FeedFilter.public ? null : _activeUserId;
        if (_filter == FeedFilter.public || userId != null) {
          unawaited(
            ref
                .read(startupDataCacheProvider)
                ?.write(
                  scope: 'feed_${_filter.name}',
                  userId: userId,
                  value: page.items.map((post) => post.toJson()).toList(),
                ),
          );
        }
      }
      state = PagedListState(
        items: useFallbackItems ? fallbackItemsOnEmptyReset : nextItems,
        hasMore: useFallbackItems
            ? fallbackHasMoreOnEmptyReset ?? page.hasMore
            : page.hasMore,
      );
      if (state.items.isNotEmpty) {
        StartupPerformance.mark(
          'first_nonempty_state',
          page: 'feed_${_filter.name}',
          outcome: 'refresh',
          once: true,
        );
      }
    } catch (error) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<PagedResult<FeedPost>> _loadFollowing(FeedRepository repo) async {
    final stopwatch = Stopwatch()..start();
    final userId = _effectiveFeedUserId(ref.read(currentUserProvider));
    if (userId == null || userId.trim().isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    final cache = ref.read(startupDataCacheProvider);
    final cachedFollowing = cache?.read<List<String>>(
      scope: 'following_ids',
      userId: userId,
      decode: (json) => (json! as List).map((id) => id.toString()).toList(),
    );
    List<String> following;
    if (cachedFollowing != null) {
      following = cachedFollowing;
      unawaited(
        _refreshFollowingIds(userId, cachedFollowing).then((changed) {
          if (changed) _refreshAfterCurrentLoad(userId);
        }),
      );
    } else {
      following = await ref
          .read(followRepositoryProvider)
          .getFollowingList(userId)
          .timeout(const Duration(seconds: 2));
      unawaited(
        cache?.write(scope: 'following_ids', userId: userId, value: following),
      );
    }
    if (following.isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    final remaining = followingFeedLoadTimeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Following feed refresh timed out');
    }
    return repo
        .getFollowingFeedPage(following, limit: feedPageSize, cursor: _cursor)
        .timeout(remaining);
  }

  Future<bool> _refreshFollowingIds(
    String userId,
    List<String> previous,
  ) async {
    try {
      final refreshed = await ref
          .read(followRepositoryProvider)
          .getFollowingList(userId)
          .timeout(const Duration(seconds: 2));
      if (!ref.mounted || _activeUserId != userId) return false;
      unawaited(
        ref
            .read(startupDataCacheProvider)
            ?.write(
              scope: 'following_ids',
              userId: userId,
              value: refreshed,
            ),
      );
      final previousSet = previous.toSet();
      final refreshedSet = refreshed.toSet();
      return previousSet.length != refreshedSet.length ||
          !previousSet.containsAll(refreshedSet);
    } catch (_) {
      return false;
    }
  }

  void _refreshAfterCurrentLoad(String userId) {
    final active = _activeRefresh;
    if (active == null) {
      if (ref.mounted && _activeUserId == userId) unawaited(refreshInPlace());
      return;
    }
    unawaited(
      active.then<void>((_) {
        if (ref.mounted && _activeUserId == userId) {
          unawaited(refreshInPlace());
        }
      }),
    );
  }

  Future<PagedResult<FeedPost>> _loadMine(FeedRepository repo) async {
    final userId = _effectiveFeedUserId(ref.read(currentUserProvider));
    if (userId == null || userId.trim().isEmpty) {
      return const PagedResult<FeedPost>(items: [], hasMore: false);
    }
    return repo
        .getUserFeedPostsPage(userId, limit: feedPageSize, cursor: _cursor)
        .timeout(followingFeedLoadTimeout);
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

  Future<void> refreshInPlace() async {
    _cursor = null;
    final fallbackItems = state.items;
    final fallbackHasMore = state.hasMore;
    if (state.items.isEmpty) {
      state = const PagedListState(isInitialLoading: true);
    } else {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: true,
        isLoadingMore: false,
        hasMore: true,
        clearError: true,
      );
    }
    await _load(
      reset: true,
      fallbackItemsOnEmptyReset: fallbackItems,
      fallbackHasMoreOnEmptyReset: fallbackHasMore,
    );
  }

  Future<void> loadMore() => _load();

  void removePost(String postId) {
    if (postId.trim().isEmpty) return;
    final nextItems = state.items
        .where((post) => post.id != postId)
        .toList(growable: false);
    if (nextItems.length == state.items.length) return;
    state = state.copyWith(items: nextItems, clearError: true);
  }

  Future<void> _load({
    bool reset = false,
    List<FeedPost>? fallbackItemsOnEmptyReset,
    bool? fallbackHasMoreOnEmptyReset,
  }) async {
    if (state.isLoadingMore ||
        (state.isInitialLoading && !reset) ||
        (state.isRefreshing && !reset)) {
      return;
    }
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
      final nextItems = reset ? page.items : [...state.items, ...page.items];
      final useFallbackItems =
          reset &&
          nextItems.isEmpty &&
          fallbackItemsOnEmptyReset != null &&
          fallbackItemsOnEmptyReset.isNotEmpty;
      state = PagedListState(
        items: useFallbackItems ? fallbackItemsOnEmptyReset : nextItems,
        hasMore: useFallbackItems
            ? fallbackHasMoreOnEmptyReset ?? page.hasMore
            : page.hasMore,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
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

void refreshFeedAfterPostPublish(WidgetRef ref, {String? userId}) {
  ref.invalidate(feedPostsProvider);
  for (final filter in FeedFilter.values) {
    ref.invalidate(filteredFeedPostsProvider(filter));
    unawaited(
      ref.read(pagedFeedPostsProvider(filter).notifier).refreshInPlace(),
    );
  }

  final trimmedUserId = userId?.trim();
  if (trimmedUserId != null && trimmedUserId.isNotEmpty) {
    ref.invalidate(userFeedPostsProvider(trimmedUserId));
    unawaited(
      ref
          .read(pagedUserFeedPostsProvider(trimmedUserId).notifier)
          .refreshInPlace(),
    );
  }
}

void refreshFeedAfterPostPublishInContainer(
  ProviderContainer container, {
  String? userId,
}) {
  container.invalidate(feedPostsProvider);
  for (final filter in FeedFilter.values) {
    container.invalidate(filteredFeedPostsProvider(filter));
    unawaited(
      container.read(pagedFeedPostsProvider(filter).notifier).refreshInPlace(),
    );
  }

  final trimmedUserId = userId?.trim();
  if (trimmedUserId != null && trimmedUserId.isNotEmpty) {
    container.invalidate(userFeedPostsProvider(trimmedUserId));
    unawaited(
      container
          .read(pagedUserFeedPostsProvider(trimmedUserId).notifier)
          .refreshInPlace(),
    );
  }
}

@riverpod
Future<FeedPost?> singlePost(Ref ref, String postId) async {
  return ref.watch(feedRepositoryProvider).getFeedPost(postId);
}

@riverpod
Future<List<String>> activeQuestions(Ref ref) {
  return ref.watch(feedRepositoryProvider).getActiveQuestions();
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
