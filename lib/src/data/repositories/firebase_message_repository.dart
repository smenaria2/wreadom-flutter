import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/message.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> getOrCreateDirectConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    final existing = await _firestore
        .collection('conversations')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: currentUser.id)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.length == 2 &&
          participants.contains(currentUser.id) &&
          participants.contains(otherUser.id)) {
        return doc.id;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = await _firestore.collection('conversations').add({
      'participants': [currentUser.id, otherUser.id],
      'participantDetails': {
        currentUser.id: {
          'username': currentUser.username,
          'displayName': currentUser.displayName,
          'penName': currentUser.penName,
          'photoURL': currentUser.photoURL,
        },
        otherUser.id: {
          'username': otherUser.username,
          'displayName': otherUser.displayName,
          'penName': otherUser.penName,
          'photoURL': otherUser.photoURL,
        },
      },
      'memberStatus': {currentUser.id: 'accepted', otherUser.id: 'accepted'},
      'type': 'direct',
      'createdAt': now,
      'updatedAt': now,
      'createdBy': currentUser.id,
    });
    return ref.id;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required UserModel sender,
    required String text,
  }) async {
    await _assertCanSend(conversationId: conversationId, senderId: sender.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    await conversationRef.collection('messages').add({
      'senderId': sender.id,
      'senderName': sender.displayName ?? sender.username,
      'senderPhotoURL': sender.photoURL,
      'text': text,
      'timestamp': now,
      'type': 'text',
      'readBy': [sender.id],
    });
    await conversationRef.update({
      'updatedAt': now,
      'lastMessage': {
        'text': text,
        'senderId': sender.id,
        'timestamp': now,
        'readBy': [sender.id],
      },
    });
  }

  @override
  Future<void> sendStoryMessage({
    required String conversationId,
    required UserModel sender,
    required MessageStoryData storyData,
  }) async {
    await _assertCanSend(conversationId: conversationId, senderId: sender.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final previewText = 'Sent a book: ${storyData.title}';
    await conversationRef.collection('messages').add({
      'senderId': sender.id,
      'senderName': sender.displayName ?? sender.username,
      'senderPhotoURL': sender.photoURL,
      'text': previewText,
      'timestamp': now,
      'type': 'story',
      'storyData': storyData.toJson(),
      'readBy': [sender.id],
    });
    await conversationRef.update({
      'updatedAt': now,
      'lastMessage': {
        'text': previewText,
        'senderId': sender.id,
        'timestamp': now,
        'readBy': [sender.id],
      },
    });
  }

  @override
  Future<void> deleteConversationForUser({
    required String conversationId,
    required String userId,
  }) async {
    final ref = _firestore.collection('conversations').doc(conversationId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final participants = List<String>.from(snap.data()?['participants'] ?? []);
    if (participants.length <= 1) {
      await ref.delete();
      return;
    }
    await ref.update({
      'participants': FieldValue.arrayRemove([userId]),
      'memberStatus.$userId': 'deleted',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> blockUserInConversation({
    required String conversationId,
    required String blockedUserId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'memberStatus.$blockedUserId': 'blocked',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) {
            final data = mapFirestoreData(doc.data(), doc.id);
            return Conversation.fromJson(data);
          }).toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  @override
  Stream<Conversation?> watchConversation(String conversationId) {
    if (conversationId.isEmpty) return Stream.value(null);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          final data = mapFirestoreData(doc.data()!, doc.id);
          return Conversation.fromJson(data);
        });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    if (conversationId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) {
            final data = mapFirestoreData(doc.data(), doc.id);
            return Message.fromJson(data);
          }).toList();
          items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return items;
        });
  }

  Future<void> _assertCanSend({
    required String conversationId,
    required String senderId,
  }) async {
    if (conversationId.isEmpty) return;
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final conversation = await conversationRef.get();
    final data = conversation.data();
    if (data == null) return;
    final memberStatus = data['memberStatus'];
    if (memberStatus is Map && memberStatus[senderId] == 'blocked') {
      throw const MessageLimitException(
        'You can\'t send messages in this conversation.',
      );
    }
    if (data['type'] != 'direct' || data['createdBy'] != senderId) return;

    final messages = await conversationRef
        .collection('messages')
        .orderBy('timestamp')
        .limit(20)
        .get();
    if (messages.docs.isEmpty) return;

    final hasRecipientReply = messages.docs.any((doc) {
      return doc.data()['senderId'] != senderId;
    });
    if (hasRecipientReply) return;

    throw const MessageLimitException(
      'The recipient will receive only one message from you unless they reply.',
    );
  }
}
