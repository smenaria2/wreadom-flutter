import '../../domain/models/message.dart';

class MessageGroupPlacement {
  const MessageGroupPlacement({
    required this.startsGroup,
    required this.continuesGroup,
  });

  final bool startsGroup;
  final bool continuesGroup;
}

List<Conversation> visibleConversations(List<Conversation> conversations) {
  return conversations
      .where((conversation) => conversation.lastMessage != null)
      .toList();
}

MessageGroupPlacement messageGroupPlacement(List<Message> messages, int index) {
  final message = messages[index];
  final previous = index > 0 ? messages[index - 1] : null;
  final next = index + 1 < messages.length ? messages[index + 1] : null;
  return MessageGroupPlacement(
    startsGroup: previous?.senderId != message.senderId,
    continuesGroup: next?.senderId == message.senderId,
  );
}
