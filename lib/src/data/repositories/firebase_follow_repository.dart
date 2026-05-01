import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<List<String>> getFollowersList(String followingId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followingId', isEqualTo: followingId)
        .get();
    return _uniqueIds(snapshot.docs, 'followerId');
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
