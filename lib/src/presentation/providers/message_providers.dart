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

  @override
  PagedListState<Message> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final previousUserId = previous?.asData?.value?.id;
      final nextUserId = next.asData?.value?.id;
      if (previousUserId != nextUserId) {
        _olderCursor = null;
        _loadGeneration++;
        state = const PagedListState(isInitialLoading: true);
        Future.microtask(refresh);
      }
    });
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
      state = PagedListState(
        items: reset ? visibleItems : [...visibleItems, ...state.items],
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
