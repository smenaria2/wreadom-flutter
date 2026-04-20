import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_message_repository.dart';
import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import 'auth_providers.dart';

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
