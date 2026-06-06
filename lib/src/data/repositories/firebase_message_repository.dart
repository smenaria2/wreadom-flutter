import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/message.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/message_repository.dart';
import '../utils/firestore_utils.dart';
import '../../utils/map_utils.dart';

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
    if (deterministicSnap.exists) {
      await deterministicRef.update({
        'deletedFor': FieldValue.arrayRemove([currentUser.id]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return deterministicId;
    }

    final existing = await _firestore
        .collection('conversations')
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: currentUser.id)
        .limit(50)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.length == 2 &&
          participants.contains(currentUser.id) &&
          participants.contains(otherUser.id)) {
        await doc.reference.update({
          'deletedFor': FieldValue.arrayRemove([currentUser.id]),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
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
        'deletedFor': <String>[],
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
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    final conversationRef = _firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);
    await _firestore.runTransaction((transaction) async {
      final conversationSnap = await transaction.get(conversationRef);
      final conversationData = conversationSnap.data();
      if (conversationData == null) return;
      final participants = List<String>.from(
        conversationData['participants'] ?? const [],
      );
      if (!participants.contains(userId)) return;

      final messageSnap = await transaction.get(messageRef);
      final messageData = messageSnap.data();
      if (messageData == null) return;
      if (_isProtectedFirstDirectMessage(
        conversationData: conversationData,
        messageData: messageData,
        userId: userId,
      )) {
        throw const MessageLimitException(
          'The first message cannot be deleted until the recipient replies.',
        );
      }

      transaction.update(messageRef, {
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
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
    await ref.update({
      'deletedFor': FieldValue.arrayUnion([userId]),
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
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) {
                final data = mapFirestoreData(doc.data(), doc.id);
                return Conversation.fromJson(data);
              })
              .where((conversation) => conversation.lastMessage != null)
              .where(
                (conversation) => !conversation.deletedFor.contains(userId),
              )
              .toList();
          return items;
        });
  }

  @override
  Future<PagedResult<Conversation>> getConversationsPage(
    String userId, {
    int limit = 25,
    Object? cursor,
  }) async {
    Query query = _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit + 1);

    if (cursor is DocumentSnapshot) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final pageDocs = snapshot.docs.take(limit).toList();
    final items = pageDocs
        .map((doc) {
          final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
          return Conversation.fromJson(data);
        })
        .where((conversation) => conversation.lastMessage != null)
        .where((conversation) => !conversation.deletedFor.contains(userId))
        .toList();
    return PagedResult(
      items: items,
      hasMore: snapshot.docs.length > limit,
      nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
    );
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
        .orderBy('timestamp')
        .limitToLast(100)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) {
            final data = mapFirestoreData(doc.data(), doc.id);
            return Message.fromJson(data);
          }).toList();
          return items;
        });
  }

  @override
  Future<PagedResult<Message>> getMessagesPage(
    String conversationId, {
    int limit = 25,
    Object? cursor,
  }) async {
    if (conversationId.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }
    Query query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (cursor is DocumentSnapshot) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final pageDocs = snapshot.docs.take(limit).toList();
    final items = pageDocs
        .map((doc) {
          final data = mapFirestoreData(doc.data(), doc.id);
          return Message.fromJson(data);
        })
        .toList()
        .reversed
        .toList();
    return PagedResult(
      items: items,
      hasMore: snapshot.docs.length > limit,
      nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
    );
  }

  bool _isProtectedFirstDirectMessage({
    required Map<String, dynamic> conversationData,
    required Map<String, dynamic> messageData,
    required String userId,
  }) {
    if (conversationData['type'] != 'direct') return false;
    if (conversationData['createdBy']?.toString() != userId) return false;
    if (conversationData['recipientHasReplied'] == true) return false;
    final senderId = messageData['senderId']?.toString();
    if (senderId != userId) return false;
    final firstMessageSenderId = conversationData['firstMessageSenderId']
        ?.toString();
    if (firstMessageSenderId == userId) return true;
    final lastMessage = conversationData['lastMessage'];
    return firstMessageSenderId == null &&
        lastMessage is Map &&
        lastMessage['senderId']?.toString() == userId &&
        lastMessage['timestamp'] == messageData['timestamp'];
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
    final hasRecipientReply = await _hasRecipientReply(
      conversationRef: conversationRef,
      senderId: senderId,
    );
    await _firestore.runTransaction((transaction) async {
      final conversation = await transaction.get(conversationRef);
      final data = conversation.data();
      if (data == null) return;
      _assertCanSend(
        data: data,
        senderId: senderId,
        hasRecipientReply: hasRecipientReply,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.set(messageRef, messageDataBuilder(now));
      transaction.update(conversationRef, {
        'updatedAt': now,
        'lastMessage': lastMessageBuilder(now),
        'deletedFor': FieldValue.arrayRemove([senderId]),
        ..._messageLimitStateUpdates(
          data: data,
          senderId: senderId,
          hasRecipientReply: hasRecipientReply,
        ),
      });
    });
  }

  Future<bool> _hasRecipientReply({
    required DocumentReference<Map<String, dynamic>> conversationRef,
    required String senderId,
  }) async {
    final conversation = await conversationRef.get();
    final data = conversation.data();
    if (data == null || data['type'] != 'direct') return false;
    final createdBy = data['createdBy']?.toString();
    if (createdBy != senderId) return false;
    if (data['recipientHasReplied'] == true) return true;
    final participants = List<String>.from(data['participants'] ?? const []);
    final recipientId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );
    if (recipientId.isEmpty) return false;

    final reply = await conversationRef
        .collection('messages')
        .where('senderId', isEqualTo: recipientId)
        .limit(1)
        .get();
    return reply.docs.isNotEmpty;
  }

  void _assertCanSend({
    required Map<String, dynamic> data,
    required String senderId,
    required bool hasRecipientReply,
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
    final recipientHasReplied =
        hasRecipientReply || _recipientHasRepliedFromConversation(data);
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
    required bool hasRecipientReply,
  }) {
    if (data['type'] != 'direct') return const {};

    final createdBy = data['createdBy']?.toString();
    final firstMessageSenderId = data['firstMessageSenderId']?.toString();
    if (createdBy == senderId &&
        hasRecipientReply &&
        data['recipientHasReplied'] != true) {
      return {'recipientHasReplied': true};
    }
    if (createdBy == senderId && firstMessageSenderId == null) {
      return {'firstMessageSenderId': senderId};
    }
    if (createdBy != null && createdBy != senderId) {
      return {'recipientHasReplied': true};
    }
    return const {};
  }

  bool _recipientHasRepliedFromConversation(Map<String, dynamic> data) {
    if (data['recipientHasReplied'] == true) return true;
    final createdBy = data['createdBy']?.toString();
    if (createdBy == null || createdBy.isEmpty) return false;
    final lastMessage = data['lastMessage'];
    return lastMessage is Map &&
        lastMessage['senderId']?.toString() != null &&
        lastMessage['senderId']?.toString() != createdBy;
  }
}
