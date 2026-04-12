import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseCommentRepository implements CommentRepository {
  FirebaseCommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> addComment(Comment comment) async {
    final data = comment.toJson()..remove('id');
    final doc = await _firestore.collection('comments').add(data);
    return doc.id;
  }

  @override
  Future<void> addReply(String commentId, CommentReply reply) async {
    await _firestore.collection('comments').doc(commentId).update({
      'replies': FieldValue.arrayUnion([reply.toJson()..remove('id')]),
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).delete();
  }

  @override
  Future<List<Comment>> getBookComments(String bookId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('bookId', isEqualTo: bookId)
        .get();
    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Comment.fromJson(data);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }
}
