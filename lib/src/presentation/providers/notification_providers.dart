import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_notification_repository.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'auth_providers.dart';
import 'paged_list_state.dart';
import '../../data/services/startup_performance.dart';
import 'startup_cache_provider.dart';

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
  int _loadGeneration = 0;
  Future<void>? _activeRefresh;

  @override
  PagedListState<AppNotification> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.id;
      final nextUserId = next.asData?.value?.id;
      if (previousUserId != nextUserId) {
        _cursor = null;
        _loadedUserId = nextUserId;
        _loadGeneration++;
        _activeRefresh = null;
        state = const PagedListState(isInitialLoading: true);
        Future.microtask(() => refresh());
      }
    });
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    final active = _activeRefresh;
    if (active != null) return active;
    late final Future<void> refresh;
    refresh = _performRefresh();
    _activeRefresh = refresh;
    unawaited(
      refresh.then<void>((_) {
        if (identical(_activeRefresh, refresh)) _activeRefresh = null;
      }),
    );
    return refresh;
  }

  Future<void> _performRefresh() async {
    _cursor = null;
    _loadGeneration++;
    state = state.items.isEmpty
        ? const PagedListState(isInitialLoading: true)
        : state.copyWith(
            isInitialLoading: false,
            isRefreshing: true,
            isLoadingMore: false,
            hasMore: true,
            clearError: true,
          );
    await _load(reset: true);
  }

  Future<void> loadMore() => _load();

  Future<void> _load({bool reset = false}) async {
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
      final user = await ref.read(currentUserProvider.future);
      if (!ref.mounted || generation != _loadGeneration) return;
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
      final cache = ref.read(startupDataCacheProvider);
      if (reset && state.items.isEmpty) {
        final cached = cache?.read<List<AppNotification>>(
          scope: 'notifications_first_page',
          userId: user.id,
          decode: (json) => (json! as List)
              .map(
                (item) => AppNotification.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false),
        );
        if (cached != null && cached.isNotEmpty) {
          state = PagedListState(items: cached, hasMore: true);
          StartupPerformance.mark(
            'first_nonempty_state',
            page: 'notifications',
            outcome: 'cache',
            once: true,
          );
        }
      }
      final page = await ref
          .read(notificationRepositoryProvider)
          .getNotificationsPage(
            user.id,
            limit: notificationPageSize,
            cursor: _cursor,
          )
          .timeout(const Duration(seconds: 4));
      if (!ref.mounted || generation != _loadGeneration) return;
      _cursor = page.nextCursor;
      if (reset) {
        unawaited(
          cache?.write(
            scope: 'notifications_first_page',
            userId: user.id,
            value: page.items
                .map((item) => {...item.toJson(), 'id': item.id})
                .toList(),
          ),
        );
      }
      state = PagedListState(
        items: reset ? page.items : [...state.items, ...page.items],
        hasMore: page.hasMore,
      );
      if (state.items.isNotEmpty) {
        StartupPerformance.mark(
          'first_nonempty_state',
          page: 'notifications',
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
}

/// Count of unread notifications for the current user (0 if logged out).
final unreadNotificationCountStreamProvider = StreamProvider<int>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield 0;
    return;
  }
  final cached = ref
      .read(startupDataCacheProvider)
      ?.read<List<AppNotification>>(
        scope: 'notifications_first_page',
        userId: user.id,
        decode: (json) => (json! as List)
            .map(
              (item) => AppNotification.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
  if (cached != null) yield cached.where((item) => !item.isRead).length;
  try {
    await for (final snapshot
        in FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.id)
            .where('isRead', isEqualTo: false)
            .limit(100)
            .snapshots()) {
      yield snapshot.docs.length;
    }
  } catch (_) {
    // Keep the last cached/listener count during transient listener failures.
  }
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final async = ref.watch(unreadNotificationCountStreamProvider);
  return async.maybeWhen(data: (unreadTotal) => unreadTotal, orElse: () => 0);
});
