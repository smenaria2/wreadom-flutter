import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_follow_repository.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/follow_repository.dart';
import 'auth_providers.dart';
import 'paged_list_state.dart';

enum FollowListType { followers, following }

const int followListPageSize = 20;

class FollowListQuery {
  const FollowListQuery({required this.userId, required this.type});

  final String userId;
  final FollowListType type;

  @override
  bool operator ==(Object other) {
    return other is FollowListQuery &&
        other.userId == userId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(userId, type);
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FirebaseFollowRepository();
});

final isFollowingProvider = FutureProvider.family<bool, String>((
  ref,
  targetUserId,
) async {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return false;
  return ref.read(followRepositoryProvider).isFollowing(user.id, targetUserId);
});

final followingListProvider = FutureProvider<List<String>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.read(followRepositoryProvider).getFollowingList(user.id);
});

final userFollowingListProvider = FutureProvider.family<List<String>, String>((
  ref,
  userId,
) async {
  return ref.read(followRepositoryProvider).getFollowingList(userId);
});

final userFollowersListProvider = FutureProvider.family<List<String>, String>((
  ref,
  userId,
) async {
  return ref.read(followRepositoryProvider).getFollowersList(userId);
});

final pagedFollowListProvider =
    NotifierProvider.family<
      PagedFollowListController,
      PagedListState<String>,
      FollowListQuery
    >(PagedFollowListController.new);

class PagedFollowListController extends Notifier<PagedListState<String>> {
  PagedFollowListController(this._query);

  final FollowListQuery _query;
  Object? _cursor;

  @override
  PagedListState<String> build() {
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
      final repo = ref.read(followRepositoryProvider);
      final PagedResult<String> page = switch (_query.type) {
        FollowListType.followers => await repo.getFollowersPage(
          _query.userId,
          limit: followListPageSize,
          cursor: _cursor,
        ),
        FollowListType.following => await repo.getFollowingPage(
          _query.userId,
          limit: followListPageSize,
          cursor: _cursor,
        ),
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
}
