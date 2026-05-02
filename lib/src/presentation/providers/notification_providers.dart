import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_notification_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'auth_providers.dart';
import 'paged_list_state.dart';

const int notificationPageSize = 25;

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});

final pagedNotificationsProvider =
    NotifierProvider<
      PagedNotificationsController,
      PagedListState<AppNotification>
    >(PagedNotificationsController.new);

class PagedNotificationsController
    extends Notifier<PagedListState<AppNotification>> {
  Object? _cursor;
  String? _loadedUserId;

  @override
  PagedListState<AppNotification> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.id;
      final nextUserId = next.asData?.value?.id;
      if (previousUserId != nextUserId) {
        _cursor = null;
        _loadedUserId = nextUserId;
        state = const PagedListState(isInitialLoading: true);
        Future.microtask(refresh);
      }
    });
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
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        _loadedUserId = null;
        state = const PagedListState(hasMore: false);
        return;
      }
      if (_loadedUserId != null && _loadedUserId != user.id) {
        _cursor = null;
        reset = true;
      }
      _loadedUserId = user.id;
      final page = await ref
          .read(notificationRepositoryProvider)
          .getNotificationsPage(
            user.id,
            limit: notificationPageSize,
            cursor: _cursor,
          );
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

/// Count of unread notifications for the current user (0 if logged out).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
