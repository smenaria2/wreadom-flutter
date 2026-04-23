import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/message.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _directConversationId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return 'direct_${ids[0]}_${ids[1]}';
  }

  @override
  Future<String> getOrCreateDirectConversation({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    final deterministicId = _directConversationId(currentUser.id, otherUser.id);
    final deterministicRef = _firestore
        .collection('conversations')
        .doc(deterministicId);
    final deterministicSnap = await deterministicRef.get();
    if (deterministicSnap.exists) return deterministicId;

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
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(deterministicRef);
      if (snap.exists) return;

      transaction.set(deterministicRef, {
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
        'firstMessageSenderId': null,
        'recipientHasReplied': false,
      });
    });
    return deterministicId;
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required UserModel sender,
    required String text,
  }) async {
    await _sendMessageDocument(
      conversationId: conversationId,
      senderId: sender.id,
      messageDataBuilder: (now) => {
        'senderId': sender.id,
        'senderName': sender.displayName ?? sender.username,
        'senderPhotoURL': sender.photoURL,
        'text': text,
        'timestamp': now,
        'type': 'text',
        'readBy': [sender.id],
      },
      lastMessageBuilder: (now) => {
        'text': text,
        'senderId': sender.id,
        'timestamp': now,
        'readBy': [sender.id],
      },
    );
  }

  @override
  Future<void> sendStoryMessage({
    required String conversationId,
    required UserModel sender,
    required MessageStoryData storyData,
  }) async {
    final previewText = 'Sent a book: ${storyData.title}';
    await _sendMessageDocument(
      conversationId: conversationId,
      senderId: sender.id,
      messageDataBuilder: (now) => {
        'senderId': sender.id,
        'senderName': sender.displayName ?? sender.username,
        'senderPhotoURL': sender.photoURL,
        'text': previewText,
        'timestamp': now,
        'type': 'story',
        'storyData': storyData.toJson(),
        'readBy': [sender.id],
      },
      lastMessageBuilder: (now) => {
        'text': previewText,
        'senderId': sender.id,
        'timestamp': now,
        'readBy': [sender.id],
      },
    );
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

  Future<void> _sendMessageDocument({
    required String conversationId,
    required String senderId,
    required Map<String, dynamic> Function(int now) messageDataBuilder,
    required Map<String, dynamic> Function(int now) lastMessageBuilder,
  }) async {
    if (conversationId.isEmpty) return;
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    await _firestore.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final data = conversation.data();
      if (data == null) return;
      _assertCanSend(data: data, senderId: senderId);

      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.set(messageRef, messageDataBuilder(now));
      transaction.update(conversationRef, {
        'updatedAt': now,
        'lastMessage': lastMessageBuilder(now),
        ..._messageLimitStateUpdates(data: data, senderId: senderId),
      });
    });
  }

  void _assertCanSend({
    required Map<String, dynamic> data,
    required String senderId,
  }) {
    final memberStatus = data['memberStatus'];
    if (memberStatus is Map && memberStatus[senderId] == 'blocked') {
      throw const MessageLimitException(
        'You can\'t send messages in this conversation.',
      );
    }
    if (data['type'] != 'direct') return;

    final createdBy = data['createdBy']?.toString();
    if (createdBy != senderId) return;

    final firstMessageSenderId = data['firstMessageSenderId']?.toString();
    final recipientHasReplied = data['recipientHasReplied'] == true;
    final lastMessage = data['lastMessage'];
    final legacyCreatorAlreadySent =
        firstMessageSenderId == null &&
        lastMessage is Map &&
        lastMessage['senderId']?.toString() == senderId;
    final creatorAlreadySent =
        firstMessageSenderId == senderId || legacyCreatorAlreadySent;

    if (creatorAlreadySent && !recipientHasReplied) {
      throw const MessageLimitException(
        'Only one message allowed unless recipient replies.',
      );
    }
  }

  Map<String, dynamic> _messageLimitStateUpdates({
    required Map<String, dynamic> data,
    required String senderId,
  }) {
    if (data['type'] != 'direct') return const {};

    final createdBy = data['createdBy']?.toString();
    final firstMessageSenderId = data['firstMessageSenderId']?.toString();
    if (createdBy == senderId && firstMessageSenderId == null) {
      return {'firstMessageSenderId': senderId};
    }
    if (createdBy != null && createdBy != senderId) {
      return {'recipientHasReplied': true};
    }
    return const {};
  }
}
