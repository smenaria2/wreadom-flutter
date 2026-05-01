import '../models/message.dart';
import '../models/paged_result.dart';
import '../models/user_model.dart';

class MessageLimitException implements Exception {
  const MessageLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class MessageRepository {
  Stream<List<Conversation>> watchConversations(String userId);
  Future<PagedResult<Conversation>> getConversationsPage(
    String userId, {
    int limit = 25,
    Object? cursor,
  });
  Stream<Conversation?> watchConversation(String conversationId);
  Stream<List<Message>> watchMessages(String conversationId);
  Future<PagedResult<Message>> getMessagesPage(
    String conversationId, {
    int limit = 25,
    Object? cursor,
  });
  Future<String> getOrCreateDirectConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  });
  Future<void> sendMessage({
    required String conversationId,
    required UserModel sender,
    required String text,
  });
  Future<void> sendStoryMessage({
    required String conversationId,
    required UserModel sender,
    required MessageStoryData storyData,
  });
  Future<void> deleteConversationForUser({
    required String conversationId,
    required String userId,
  });
  Future<void> blockUserInConversation({
    required String conversationId,
    required String blockedUserId,
  });
}
