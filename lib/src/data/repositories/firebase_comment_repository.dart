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
    final batch = _firestore.batch();
    final docRef = _firestore.collection('comments').doc();
    final data = comment.toJson()..remove('id');
    
    batch.set(docRef, data);

    // Sync counts atomically
    if (comment.bookId != null) {
      batch.update(
        _firestore.collection('books').doc(comment.bookId!),
        {'commentCount': FieldValue.increment(1)},
      );
    }
    if (comment.feedPostId != null) {
      batch.update(
        _firestore.collection('feed').doc(comment.feedPostId!),
        {'commentCount': FieldValue.increment(1)},
      );
    }

    await batch.commit();
    return docRef.id;
  }

  @override
  Future<void> addReply(String commentId, CommentReply reply) async {
    final replyId =
        reply.id ?? '${DateTime.now().millisecondsSinceEpoch}_${reply.userId}';
    final data = reply
        .copyWith(id: replyId, likes: reply.likes ?? const [])
        .toJson();
    await _firestore.collection('comments').doc(commentId).update({
      'replies': FieldValue.arrayUnion([data]),
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final docRef = _firestore.collection('comments').doc(commentId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;

    final comment = Comment.fromJson(mapFirestoreData(docSnap.data()!, docSnap.id));
    final batch = _firestore.batch();
    batch.delete(docRef);

    if (comment.bookId != null) {
      batch.update(
        _firestore.collection('books').doc(comment.bookId!),
        {'commentCount': FieldValue.increment(-1)},
      );
    }
    if (comment.feedPostId != null) {
      batch.update(
        _firestore.collection('feed').doc(comment.feedPostId!),
        {'commentCount': FieldValue.increment(-1)},
      );
    }
    await batch.commit();
  }

  @override
  Future<void> deleteReply(String commentId, String replyId) async {
    final ref = _firestore.collection('comments').doc(commentId);
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final replies = List<dynamic>.from(data['replies'] ?? const []);
      
      final updated = replies.where((raw) {
        if (raw is! Map) return true;
        final id = raw['id']?.toString();
        final timestamp = raw['timestamp']?.toString();
        // Check both id and timestamp as fallback (as seen in toggleReplyLike)
        return id != replyId && timestamp != replyId;
      }).toList();

      if (updated.length != replies.length) {
        transaction.update(ref, {'replies': updated});
      }
    });
  }

  @override
  Future<List<Comment>> getBookComments(String bookId) async {
    final idAsInt = int.tryParse(bookId);
    final ids = [bookId, ?idAsInt];
    final snapshot = await _firestore
        .collection('comments')
        .where('bookId', whereIn: ids)
        .get();
    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Comment.fromJson(data);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<List<Comment>> getFeedPostComments(String postId) async {
    final idAsInt = int.tryParse(postId);
    final ids = [postId, ?idAsInt];
    final snapshot = await _firestore
        .collection('comments')
        .where('feedPostId', whereIn: ids)
        .get();
    final items = snapshot.docs.map((doc) {
      final data = mapFirestoreData(doc.data(), doc.id);
      return Comment.fromJson(data);
    }).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Future<void> toggleCommentLike(String commentId, String userId) async {
    final ref = _firestore.collection('comments').doc(commentId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final likes = List<dynamic>.from(data['likes'] ?? const []);
    if (likes.contains(userId)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Future<void> toggleReplyLike(
    String commentId,
    String replyId,
    String userId,
  ) async {
    final ref = _firestore.collection('comments').doc(commentId);
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final replies = List<dynamic>.from(data['replies'] ?? const []);
      var changed = false;

      final updated = replies.map((raw) {
        if (raw is! Map) return raw;
        final reply = Map<String, dynamic>.from(raw);
        final id = reply['id']?.toString();
        final timestamp = reply['timestamp']?.toString();
        if (id != replyId && timestamp != replyId) return raw;

        final likes = List<dynamic>.from(reply['likes'] ?? const []);
        if (likes.contains(userId)) {
          likes.removeWhere((id) => id == userId);
        } else {
          likes.add(userId);
        }
        reply['likes'] = likes;
        changed = true;
        return reply;
      }).toList();

      if (changed) {
        transaction.update(ref, {'replies': updated});
      }
    });
  }
}
