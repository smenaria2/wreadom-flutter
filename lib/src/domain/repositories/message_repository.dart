import '../models/message.dart';
import '../models/user_model.dart';

class MessageLimitException implements Exception {
  const MessageLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class MessageRepository {
  Stream<List<Conversation>> watchConversations(String userId);
  Stream<Conversation?> watchConversation(String conversationId);
  Stream<List<Message>> watchMessages(String conversationId);
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
