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
      'memberStatus': {
        currentUser.id: 'accepted',
        otherUser.id: 'accepted',
      },
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
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
}
