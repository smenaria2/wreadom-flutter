import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/paged_result.dart';
import '../../domain/repositories/follow_repository.dart';

class FirebaseFollowRepository implements FollowRepository {
  FirebaseFollowRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _followDocId(String followerId, String followingId) =>
      '${followerId}_$followingId';

  @override
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    final legacyExisting = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    if (legacyExisting.docs.isNotEmpty) return;

    await _firestore.runTransaction((transaction) async {
      final followRef = _firestore
          .collection('follows')
          .doc(_followDocId(followerId, followingId));
      final existing = await transaction.get(followRef);
      if (existing.exists) return;

      transaction.set(followRef, {
        'followerId': followerId,
        'followingId': followingId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
    final deterministic = await _firestore
        .collection('follows')
        .doc(_followDocId(followerId, followingId))
        .get();
    if (deterministic.exists) return true;

    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<List<String>> getFollowingList(String followerId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .get();
    return _uniqueIds(snapshot.docs, 'followingId');
  }

  @override
  Future<PagedResult<String>> getFollowingPage(
    String followerId, {
    int limit = 20,
    Object? cursor,
  }) {
    return _getRelationshipPage(
      matchField: 'followerId',
      matchValue: followerId,
      idField: 'followingId',
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<List<String>> getFollowersList(String followingId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followingId', isEqualTo: followingId)
        .get();
    return _uniqueIds(snapshot.docs, 'followerId');
  }

  @override
  Future<PagedResult<String>> getFollowersPage(
    String followingId, {
    int limit = 20,
    Object? cursor,
  }) {
    return _getRelationshipPage(
      matchField: 'followingId',
      matchValue: followingId,
      idField: 'followerId',
      limit: limit,
      cursor: cursor,
    );
  }

  Future<PagedResult<String>> _getRelationshipPage({
    required String matchField,
    required String matchValue,
    required String idField,
    required int limit,
    required Object? cursor,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('follows')
        .where(matchField, isEqualTo: matchValue)
        .limit(limit + 1);

    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final pageDocs = docs.take(limit).toList();
    return PagedResult(
      items: _uniqueIds(pageDocs, idField),
      hasMore: docs.length > limit,
      nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
    );
  }

  List<String> _uniqueIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String field,
  ) {
    final ids = <String>[];
    final seen = <String>{};
    for (final doc in docs) {
      final id = doc.data()[field]?.toString().trim();
      if (id == null ||
          id.isEmpty ||
          id == 'null' ||
          id == 'undefined' ||
          id.contains('/')) {
        continue;
      }
      if (seen.add(id)) ids.add(id);
    }
    return ids;
  }

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    final matching = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();

    await _firestore.runTransaction((transaction) async {
      final followRef = _firestore
          .collection('follows')
          .doc(_followDocId(followerId, followingId));
      final refs = <DocumentReference<Map<String, dynamic>>>{
        followRef,
        ...matching.docs.map((doc) => doc.reference),
      };

      for (final ref in refs) {
        final existing = await transaction.get(ref);
        if (!existing.exists) continue;
        transaction.delete(ref);
      }
    });
  }
}
