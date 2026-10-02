import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_notification_repository.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'auth_providers.dart';
import 'paged_list_state.dart';

const int notificationPageSize = 25;

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

final notificationEventProvider = StreamProvider<String>((ref) {
  return NotificationService.instance.notificationEvents;
});

final notificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) async* {
  // Only the uid is needed; avoid waiting on the profile document.
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationRepositoryProvider).watchNotifications(user.uid);
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
    ref.listen(authStateProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.uid;
      final nextUserId = next.asData?.value?.uid;
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
    // Keep the current items on screen while refreshing; only show the
    // full-screen spinner when there is nothing to show yet.
    state = state.items.isEmpty
        ? const PagedListState(isInitialLoading: true)
        : state.copyWith(clearError: true);
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
      final user = await ref.read(authStateProvider.future);
      if (user == null) {
        _loadedUserId = null;
        state = const PagedListState(hasMore: false);
        return;
      }
      if (_loadedUserId != null && _loadedUserId != user.uid) {
        _cursor = null;
        reset = true;
      }
      _loadedUserId = user.uid;
      final page = await ref
          .read(notificationRepositoryProvider)
          .getNotificationsPage(
            user.uid,
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
