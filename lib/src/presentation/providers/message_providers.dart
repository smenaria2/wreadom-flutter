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

  @override
  PagedListState<Conversation> build() {
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

class PagedConversationMessagesController
    extends Notifier<PagedListState<Message>> {
  PagedConversationMessagesController(this._conversationId);

  final String _conversationId;
  Object? _olderCursor;

  @override
  PagedListState<Message> build() {
    Future.microtask(refresh);
    return const PagedListState();
  }

  Future<void> refresh() async {
    _olderCursor = null;
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
          .read(messageRepositoryProvider)
          .getMessagesPage(
            _conversationId,
            limit: messagePageSize,
            cursor: _olderCursor,
          );
      if (!ref.mounted) return;
      _olderCursor = page.nextCursor;
      state = PagedListState(
        items: reset ? page.items : [...page.items, ...state.items],
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

final conversationMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
      return ref.watch(messageRepositoryProvider).watchMessages(conversationId);
    });

final conversationProvider = StreamProvider.family<Conversation?, String>((
  ref,
  conversationId,
) {
  return ref.watch(messageRepositoryProvider).watchConversation(conversationId);
});
