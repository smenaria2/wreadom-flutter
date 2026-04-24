import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/models/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseCommentRepository implements CommentRepository {
  FirebaseCommentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<String> addComment(Comment comment) async {
    final docRef = _firestore.collection('comments').doc();
    final data = comment.toJson()..remove('id');
    data.removeWhere((key, value) => value == null);

    await docRef.set(data);
    return docRef.id;
  }

  @override
  Future<void> addReply(String commentId, CommentReply reply) async {
    final replyId =
        reply.id ?? '${DateTime.now().millisecondsSinceEpoch}_${reply.userId}';
    final data = reply
        .copyWith(id: replyId, likes: reply.likes ?? const [])
        .toJson();
    data.removeWhere((key, value) => value == null);
    await _firestore.collection('comments').doc(commentId).update({
      'replies': FieldValue.arrayUnion([data]),
    });
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final docRef = _firestore.collection('comments').doc(commentId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) return;
    final audioObjectKey = docSnap.data()?['audioObjectKey']?.toString().trim();
    if (audioObjectKey != null && audioObjectKey.isNotEmpty) {
      try {
        await _functions.httpsCallable('deleteAudioReviewObject').call({
          'objectKey': audioObjectKey,
        });
      } catch (_) {
        // Deleting the comment should not be blocked by storage cleanup.
      }
    }

    final batch = _firestore.batch();
    batch.delete(docRef);
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
  Future<void> updateCommentText(String commentId, String text) async {
    await _firestore.collection('comments').doc(commentId).update({
      'text': text,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> updateReplyText(
    String commentId,
    String replyId,
    String text,
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
        reply['text'] = text;
        reply['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        changed = true;
        return reply;
      }).toList();

      if (changed) {
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
    items.sort(_compareBookComments);
    return items;
  }

  @override
  Future<Comment?> getUserBookReview(String bookId, String userId) async {
    final snapshot = await _bookCommentsQuery(
      bookId,
    ).where('userId', isEqualTo: userId).get();
    if (snapshot.docs.isEmpty) return null;
    for (final doc in snapshot.docs) {
      final comment = Comment.fromJson(mapFirestoreData(doc.data(), doc.id));
      if ((comment.rating ?? 0) > 0) return comment;
    }
    return null;
  }

  @override
  Future<String> upsertBookReview(Comment comment) async {
    final existing = await getUserBookReview(
      comment.bookId.toString(),
      comment.userId,
    );
    if (existing?.id == null) {
      return addComment(comment.copyWith(rating: comment.rating ?? 5));
    }

    final docRef = _firestore.collection('comments').doc(existing!.id);
    final data =
        comment
            .copyWith(
              id: null,
              rating: comment.rating ?? 5,
              replies: existing.replies,
              likes: existing.likes,
              isHighlighted: existing.isHighlighted,
              highlightedAt: existing.highlightedAt,
              highlightedByUserId: existing.highlightedByUserId,
            )
            .toJson()
          ..remove('id');
    for (final key in const [
      'audioUrl',
      'audioObjectKey',
      'audioDurationMs',
      'audioMimeType',
      'audioSizeBytes',
    ]) {
      if (data[key] == null) data[key] = FieldValue.delete();
    }
    data.removeWhere((key, value) => value == null);
    await docRef.update(data);
    return existing.id!;
  }

  @override
  Future<List<Comment>> getFeedPostComments(String postId) async {
    final itemsById = <String, Comment>{};

    final idAsInt = int.tryParse(postId);
    final ids = [postId, ?idAsInt];
    final snapshot = await _firestore
        .collection('comments')
        .where('feedPostId', whereIn: ids)
        .get();
    for (final doc in snapshot.docs) {
      final data = mapFirestoreData(doc.data(), doc.id);
      final comment = Comment.fromJson(data);
      itemsById[comment.id ?? doc.id] = comment;
    }
    final items = itemsById.values.toList();
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

  @override
  Future<void> toggleReviewHighlight({
    required String commentId,
    required String bookId,
    required String authorId,
    int maxHighlighted = 3,
  }) async {
    await _functions.httpsCallable('toggleReviewHighlight').call({
      'commentId': commentId,
      'bookId': bookId,
      'maxHighlighted': maxHighlighted,
    });
  }

  Query<Map<String, dynamic>> _bookCommentsQuery(String bookId) {
    final idAsInt = int.tryParse(bookId);
    final ids = [bookId, ?idAsInt];
    return _firestore.collection('comments').where('bookId', whereIn: ids);
  }

  int _compareBookComments(Comment a, Comment b) {
    final aHighlighted = a.isHighlighted == true && (a.rating ?? 0) > 0;
    final bHighlighted = b.isHighlighted == true && (b.rating ?? 0) > 0;
    if (aHighlighted != bHighlighted) return aHighlighted ? -1 : 1;
    if (aHighlighted && bHighlighted) {
      final highlightedCompare = (b.highlightedAt ?? 0).compareTo(
        a.highlightedAt ?? 0,
      );
      if (highlightedCompare != 0) return highlightedCompare;
    }
    return b.timestamp.compareTo(a.timestamp);
  }
}
