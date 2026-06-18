import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_message_repository.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import 'auth_providers.dart';
import 'paged_list_state.dart';

const int conversationPageSize = 25;
const int messagePageSize = 25;

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return FirebaseMessageRepository();
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(messageRepositoryProvider).watchConversations(user.id);
});

final pagedConversationsProvider =
    NotifierProvider<
      PagedConversationsController,
      PagedListState<Conversation>
    >(PagedConversationsController.new);

final pagedConversationMessagesProvider =
    NotifierProvider.family<
      PagedConversationMessagesController,
      PagedListState<Message>,
      String
    >(PagedConversationMessagesController.new);

class PagedConversationsController
    extends Notifier<PagedListState<Conversation>> {
  Object? _cursor;
  int _loadGeneration = 0;

  @override
  PagedListState<Conversation> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.id;
      final nextUserId = next.asData?.value?.id;
      if (previousUserId != nextUserId) {
        _cursor = null;
        _loadGeneration++;
        state = const PagedListState(isInitialLoading: true);
        Future.microtask(refresh);
      }
    });
    Future.microtask(refresh);
    return const PagedListState();
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
      final user = await ref.read(currentUserProvider.future);
      if (!ref.mounted || generation != _loadGeneration) return;
      if (user == null) {
        state = const PagedListState(hasMore: false);
        return;
      }
      final page = await ref
          .read(messageRepositoryProvider)
          .getConversationsPage(
            user.id,
            limit: conversationPageSize,
            cursor: _cursor,
          );
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
}

class PagedConversationMessagesController
    extends Notifier<PagedListState<Message>> {
  PagedConversationMessagesController(this._conversationId);

  final String _conversationId;
  Object? _olderCursor;
  int _loadGeneration = 0;
  String? _currentUserId;
  final Map<String, Message> _liveMessagesByKey = {};
  final Set<String> _liveHiddenKeys = {};

  @override
  PagedListState<Message> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.id;
      final nextUserId = next.asData?.value?.id;
      _currentUserId = nextUserId;
      if (previousUserId != nextUserId) {
        _olderCursor = null;
        _liveMessagesByKey.clear();
        _liveHiddenKeys.clear();
        _loadGeneration++;
        state = const PagedListState(isInitialLoading: true);
        Future.microtask(refresh);
      }
    });
    ref.listen<AsyncValue<List<Message>>>(
      conversationMessagesProvider(_conversationId),
      (previous, next) {
        next.when(
          data: _mergeLiveMessages,
          loading: () {},
          error: (error, _) {
            state = state.copyWith(
              isInitialLoading: false,
              isLoadingMore: false,
              error: error,
            );
          },
        );
      },
      fireImmediately: true,
    );
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    _olderCursor = null;
    _loadGeneration++;
    state = const PagedListState(isInitialLoading: true);
    await _load(reset: true);
  }

  Future<void> loadMore() => _load();

  void retryLiveUpdates() {
    ref.invalidate(conversationMessagesProvider(_conversationId));
  }

  Future<void> _load({bool reset = false}) async {
    if (state.isLoadingMore || (state.isInitialLoading && !reset)) return;
    if (!reset && !state.hasMore) return;
    if (!reset) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    final generation = _loadGeneration;

    try {
      final user = await ref.read(currentUserProvider.future);
      if (!ref.mounted || generation != _loadGeneration) return;
      if (user == null) {
        state = const PagedListState(hasMore: false);
        return;
      }
      final page = await ref
          .read(messageRepositoryProvider)
          .getMessagesPage(
            _conversationId,
            limit: messagePageSize,
            cursor: _olderCursor,
          );
      if (!ref.mounted || generation != _loadGeneration) return;
      _olderCursor = page.nextCursor;
      final visibleItems = page.items
          .where((message) => !message.deletedFor.contains(user.id))
          .toList();
      final pageItems = reset
          ? visibleItems
          : [...visibleItems, ...state.items];
      final mergedWithLive = <Message>[
        ...pageItems.where(
          (message) => !_liveHiddenKeys.contains(_messageKey(message)),
        ),
        ..._liveMessagesByKey.values,
      ];
      state = PagedListState(
        items: _mergeMessages(mergedWithLive),
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

  void _mergeLiveMessages(List<Message> liveMessages) {
    final userId =
        _currentUserId ?? ref.read(currentUserProvider).asData?.value?.id;
    final mergedByKey = <String, Message>{
      for (final message in state.items) _messageKey(message): message,
    };

    for (final message in liveMessages) {
      final key = _messageKey(message);
      if (userId != null && message.deletedFor.contains(userId)) {
        _liveMessagesByKey.remove(key);
        _liveHiddenKeys.add(key);
        mergedByKey.remove(key);
      } else {
        _liveHiddenKeys.remove(key);
        _liveMessagesByKey[key] = message;
        mergedByKey[key] = message;
      }
    }

    state = state.copyWith(
      items: _mergeMessages(mergedByKey.values),
      isInitialLoading: false,
      isLoadingMore: false,
      clearError: true,
    );
  }

  List<Message> _mergeMessages(Iterable<Message> messages) {
    final byKey = <String, Message>{};
    for (final message in messages) {
      byKey[_messageKey(message)] = message;
    }
    final merged = byKey.values.toList()
      ..sort((first, second) {
        final timestampOrder = first.timestamp.compareTo(second.timestamp);
        if (timestampOrder != 0) return timestampOrder;
        return _messageKey(first).compareTo(_messageKey(second));
      });
    return merged;
  }

  String _messageKey(Message message) {
    final id = message.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return '${message.timestamp}|${message.senderId}|${message.type}|'
        '${message.text ?? ''}';
  }
}

final conversationMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
      final userId = ref.watch(currentUserProvider).asData?.value?.id;
      if (userId == null) return Stream.value(const <Message>[]);
      return ref
          .watch(messageRepositoryProvider)
          .watchMessages(conversationId)
          .map(
            (messages) => messages
                .where((message) => !message.deletedFor.contains(userId))
                .toList(),
          );
    });

final conversationProvider = StreamProvider.family<Conversation?, String>((
  ref,
  conversationId,
) {
  final userId = ref.watch(currentUserProvider).asData?.value?.id;
  if (userId == null) return Stream.value(null);
  return ref.watch(messageRepositoryProvider).watchConversation(conversationId);
});
