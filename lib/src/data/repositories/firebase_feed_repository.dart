import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/feed_repository.dart';
import '../services/cloudinary_upload_service.dart';
import '../utils/firestore_utils.dart';
import '../../utils/map_utils.dart';

class FirebaseFeedRepository implements FeedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'feed';
  static const int _maxBatchWrites = 450;
  static const int _followingFeedChunkSize = 30;
  static const int _followingFeedMaxParallelQueries = 10;
  static const Duration _followingFeedTimeout = Duration(seconds: 12);

  @override
  Future<List<FeedPost>> getFeedPosts({int limit = 10, dynamic lastDoc}) async {
    final page = await getFeedPostsPage(limit: limit, cursor: lastDoc);
    return page.items;
  }

  @override
  Future<PagedResult<FeedPost>> getFeedPostsPage({
    int limit = 10,
    Object? cursor,
  }) async {
    try {
      debugPrint('[FirebaseFeedRepository] Fetching feed posts...');
      Query query = _firestore
          .collection(_collection)
          .where('visibility', isEqualTo: 'public')
          .where('userIsDeactivated', isNotEqualTo: true)
          .orderBy('userIsDeactivated')
          .orderBy('timestamp', descending: true)
          .limit(limit + 1);

      if (cursor != null && cursor is DocumentSnapshot) {
        query = query.startAfterDocument(cursor);
      }

      debugPrint('[FirebaseFeedRepository] Running query...');
      final snapshot = await query.get();
      debugPrint(
        '[FirebaseFeedRepository] Received ${snapshot.docs.length} documents.',
      );

      final docs = snapshot.docs;
      final pageDocs = docs.take(limit).toList();
      final posts = pageDocs
          .map((doc) {
            try {
              final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
              return FeedPost.fromJson(data);
            } catch (e) {
              debugPrint(
                '[FirebaseFeedRepository] ERROR parsing document ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<FeedPost>()
          .toList();

      debugPrint(
        '[FirebaseFeedRepository] Successfully parsed ${posts.length} posts.',
      );
      return PagedResult(
        items: posts,
        hasMore: docs.length > limit,
        nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
      );
    } catch (e, stack) {
      debugPrint('[FirebaseFeedRepository] CRITICAL ERROR: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  @override
  Future<List<FeedPost>> getFollowingFeed(
    List<String> followedUserIds, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
    final page = await getFollowingFeedPage(
      followedUserIds,
      limit: limit,
      cursor: lastDoc,
    );
    return page.items;
  }

  @override
  Future<PagedResult<FeedPost>> getFollowingFeedPage(
    List<String> followedUserIds, {
    int limit = 10,
    Object? cursor,
  }) async {
    if (followedUserIds.isEmpty) {
      return const PagedResult(items: [], hasMore: false);
    }

    try {
      final chunks = _chunks(followedUserIds, _followingFeedChunkSize);
      final cursorTimestamp = cursor is int ? cursor : null;
      final queryResults =
          await _mapWithBoundedConcurrency<List<String>, List<FeedPost>>(
            chunks,
            _followingFeedMaxParallelQueries,
            (chunk) => _fetchFollowingFeedChunk(
              chunk,
              limit: limit,
              cursorTimestamp: cursorTimestamp,
            ),
          ).timeout(_followingFeedTimeout);

      final allPosts = queryResults.expand((posts) => posts).toList();

      allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final pageItems = allPosts.take(limit).toList();
      return PagedResult(
        items: pageItems,
        hasMore: allPosts.length > limit,
        nextCursor: pageItems.isEmpty ? cursor : pageItems.last.timestamp,
      );
    } catch (e) {
      debugPrint('[FirebaseFeedRepository] Error fetching following feed: $e');
      rethrow;
    }
  }

  Future<List<FeedPost>> _fetchFollowingFeedChunk(
    List<String> followedUserIds, {
    required int limit,
    required int? cursorTimestamp,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('userId', whereIn: followedUserIds)
        .where('visibility', isEqualTo: 'public');

    if (cursorTimestamp != null) {
      query = query.where('timestamp', isLessThan: cursorTimestamp);
    }

    query = query.orderBy('timestamp', descending: true).limit(limit + 1);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) {
          final raw = asStringMap(doc.data());
          if (raw['userIsDeactivated'] == true) return null;
          final data = mapFirestoreData(raw, doc.id);
          return FeedPost.fromJson(data);
        })
        .whereType<FeedPost>()
        .toList();
  }

  List<List<T>> _chunks<T>(List<T> values, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < values.length; i += size) {
      chunks.add(
        values.sublist(i, i + size > values.length ? values.length : i + size),
      );
    }
    return chunks;
  }

  Future<List<R>> _mapWithBoundedConcurrency<T, R>(
    List<T> values,
    int concurrency,
    Future<R> Function(T value) mapper,
  ) async {
    final results = <R>[];
    for (var i = 0; i < values.length; i += concurrency) {
      final window = values.sublist(
        i,
        i + concurrency > values.length ? values.length : i + concurrency,
      );
      results.addAll(await Future.wait(window.map(mapper)));
    }
    return results;
  }

  @override
  Future<List<FeedPost>> getUserFeedPosts(
    String userId, {
    int limit = 10,
    dynamic lastDoc,
  }) async {
    final page = await getUserFeedPostsPage(
      userId,
      limit: limit,
      cursor: lastDoc,
    );
    return page.items;
  }

  @override
  Future<PagedResult<FeedPost>> getUserFeedPostsPage(
    String userId, {
    int limit = 10,
    Object? cursor,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (cursor != null && cursor is DocumentSnapshot) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final pageDocs = docs.take(limit).toList();
    final posts = pageDocs
        .map((doc) {
          try {
            final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
            return FeedPost.fromJson(data);
          } catch (e) {
            debugPrint(
              '[FirebaseFeedRepository] ERROR parsing user post ${doc.id}: $e',
            );
            return null;
          }
        })
        .whereType<FeedPost>()
        .toList();
    return PagedResult(
      items: posts,
      hasMore: docs.length > limit,
      nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
    );
  }

  @override
  Future<void> createFeedPost(FeedPost post) async {
    final data = post.toJson();
    data.remove('id'); // ID is generated by Firestore
    data['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    data['likesCount'] = post.likesCount ?? post.likes.length;
    data['commentCount'] = post.commentCount ?? post.comments?.length ?? 0;
    await _firestore.collection(_collection).add(data);
  }

  @override
  Future<FeedPost?> findUserReviewPost({
    required String userId,
    required String bookId,
    String? chapterId,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'review')
        .orderBy('timestamp', descending: true)
        .limit(25)
        .get();

    for (final doc in snapshot.docs) {
      final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
      final post = FeedPost.fromJson(data);
      final matchesBook = '${post.bookId ?? ''}' == bookId;
      final matchesChapter =
          (post.chapterId ?? '').trim() == (chapterId ?? '').trim();
      if (matchesBook && matchesChapter) {
        return post;
      }
    }
    return null;
  }

  @override
  Future<void> updateFeedPost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection(_collection).doc(postId).update(updates);
  }

  @override
  Future<void> deleteFeedPost(String postId) async {
    final batches = <WriteBatch>[];
    var batch = _firestore.batch();
    var writeCount = 0;

    void queueDelete(DocumentReference<Map<String, dynamic>> reference) {
      if (writeCount >= _maxBatchWrites) {
        batches.add(batch);
        batch = _firestore.batch();
        writeCount = 0;
      }
      batch.delete(reference);
      writeCount++;
    }

    queueDelete(_firestore.collection(_collection).doc(postId));

    final comments = await _firestore
        .collection('comments')
        .where('feedPostId', isEqualTo: postId)
        .get();
    for (final comment in comments.docs) {
      queueDelete(comment.reference);
    }

    if (writeCount > 0) batches.add(batch);
    for (final batch in batches) {
      await batch.commit();
    }
  }

  @override
  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _firestore.collection(_collection).doc(postId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = asStringMap(doc.data());
      final likes = List<dynamic>.from(data['likes'] ?? const []);
      final liked = likes.contains(userId);
      transaction.update(docRef, {
        'likes': liked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(liked ? -1 : 1),
      });
    });
  }

  @override
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    final postRef = _firestore.collection(_collection).doc(postId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final commentRef = _firestore.collection('comments').doc();

    final postSnapshot = await postRef.get();
    if (!postSnapshot.exists) {
      throw StateError('Post not found');
    }

    await commentRef.set({
      ...comment,
      'feedPostId': postId,
      'timestamp': timestamp,
      'likes': const <String>[],
      'likesCount': 0,
      'replies': const <Map<String, dynamic>>[],
      'repliesCount': 0,
    });
  }

  @override
  Future<void> addCommentReply(
    String postId,
    String commentId,
    CommentReply reply,
  ) async {
    await _addTopLevelCommentReply(commentId, reply);
  }

  @override
  Future<void> updateCommentText(
    String postId,
    String commentId,
    String text,
  ) async {
    await _updateTopLevelCommentText(commentId, text);
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    await _deleteTopLevelComment(postId, commentId);
  }

  @override
  Future<void> updateReplyText(
    String postId,
    String commentId,
    String replyId,
    String text,
  ) async {
    await _updateTopLevelReplyText(commentId, replyId, text);
  }

  @override
  Future<void> deleteReply(
    String postId,
    String commentId,
    String replyId,
  ) async {
    await _deleteTopLevelReply(commentId, replyId);
  }

  @override
  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    String userId,
  ) async {
    await _toggleTopLevelCommentLike(commentId, userId);
  }

  @override
  Future<void> toggleReplyLike(
    String postId,
    String commentId,
    String replyId,
    String userId,
  ) async {
    await _toggleTopLevelReplyLike(commentId, replyId, userId);
  }

  @override
  Future<String> uploadPostImage(Uint8List bytes, String fileName) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      throw const CloudinaryUploadException(
        'Login is required to upload images.',
      );
    }

    return CloudinaryUploadService().uploadImageBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'feed_posts',
      userId: userId,
    );
  }

  @override
  Future<FeedPost?> getFeedPost(String postId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(postId).get();
      if (!doc.exists) return null;
      final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
      return FeedPost.fromJson(data);
    } catch (e) {
      debugPrint(
        '[FirebaseFeedRepository] Error fetching single post $postId: $e',
      );
      return null;
    }
  }

  Future<bool> _addTopLevelCommentReply(
    String commentId,
    CommentReply reply,
  ) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    final replyId =
        reply.id ?? '${DateTime.now().millisecondsSinceEpoch}_${reply.userId}';
    final replyData = reply
        .copyWith(id: replyId, likes: reply.likes ?? const [])
        .toJson();
    replyData.removeWhere((key, value) => value == null);

    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(commentRef);
      if (!snap.exists) return false;
      transaction.update(commentRef, {
        'replies': FieldValue.arrayUnion([replyData]),
        'repliesCount': FieldValue.increment(1),
      });
      return true;
    });
  }

  Future<bool> _updateTopLevelCommentText(String commentId, String text) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(commentRef);
      if (!snap.exists) return false;
      transaction.update(commentRef, {
        'text': text,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    });
  }

  Future<bool> _deleteTopLevelComment(String postId, String commentId) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    final snap = await commentRef.get();
    if (!snap.exists) return false;
    await commentRef.delete();
    return true;
  }

  Future<bool> _updateTopLevelReplyText(
    String commentId,
    String replyId,
    String text,
  ) async {
    return _updateTopLevelReplies(commentId, (reply) {
      final id = reply['id']?.toString();
      final timestamp = reply['timestamp']?.toString();
      if (id != replyId && timestamp != replyId) return false;
      reply['text'] = text;
      reply['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      return true;
    });
  }

  Future<bool> _deleteTopLevelReply(String commentId, String replyId) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(commentRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final replies = List<dynamic>.from(data['replies'] ?? const []);
      final updated = replies.where((replyRaw) {
        if (replyRaw is! Map) return true;
        final id = replyRaw['id']?.toString();
        final timestamp = replyRaw['timestamp']?.toString();
        return id != replyId && timestamp != replyId;
      }).toList();
      if (updated.length != replies.length) {
        transaction.update(commentRef, {
          'replies': updated,
          'repliesCount': FieldValue.increment(updated.length - replies.length),
        });
      }
      return true;
    });
  }

  Future<bool> _toggleTopLevelCommentLike(
    String commentId,
    String userId,
  ) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(commentRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final likes = List<dynamic>.from(data['likes'] ?? const []);
      transaction.update(commentRef, {
        'likes': likes.contains(userId)
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(likes.contains(userId) ? -1 : 1),
      });
      return true;
    });
  }

  Future<bool> _toggleTopLevelReplyLike(
    String commentId,
    String replyId,
    String userId,
  ) async {
    return _updateTopLevelReplies(commentId, (reply) {
      final id = reply['id']?.toString();
      final timestamp = reply['timestamp']?.toString();
      if (id != replyId && timestamp != replyId) return false;

      final likes = List<dynamic>.from(reply['likes'] ?? const []);
      if (likes.contains(userId)) {
        likes.removeWhere((id) => id == userId);
      } else {
        likes.add(userId);
      }
      reply['likes'] = likes;
      return true;
    });
  }

  Future<bool> _updateTopLevelReplies(
    String commentId,
    bool Function(Map<String, dynamic> reply) updateReply,
  ) async {
    final commentRef = _firestore.collection('comments').doc(commentId);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(commentRef);
      if (!snap.exists) return false;
      final data = snap.data() ?? {};
      final replies = List<dynamic>.from(data['replies'] ?? const []);
      var changed = false;
      final updated = replies.map((replyRaw) {
        if (replyRaw is! Map) return replyRaw;
        final reply = Map<String, dynamic>.from(replyRaw);
        if (!updateReply(reply)) return replyRaw;
        changed = true;
        return reply;
      }).toList();
      if (changed) transaction.update(commentRef, {'replies': updated});
      return true;
    });
  }
}
