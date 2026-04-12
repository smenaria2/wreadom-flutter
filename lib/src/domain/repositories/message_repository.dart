import '../models/message.dart';
import '../models/user_model.dart';

abstract class MessageRepository {
  Stream<List<Conversation>> watchConversations(String userId);
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
}
