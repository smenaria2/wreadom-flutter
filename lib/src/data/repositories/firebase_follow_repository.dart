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
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      transaction.set(_firestore.collection('users').doc(followerId), {
        'followingCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
      transaction.set(_firestore.collection('users').doc(followingId), {
        'followersCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<bool> isFollowing(String followerId, String followingId) async {
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
    return snapshot.docs
        .map((doc) => doc.data()['followingId'] as String)
        .toList();
  }

  @override
  Future<List<String>> getFollowersList(String followingId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followingId', isEqualTo: followingId)
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['followerId'] as String)
        .toList();
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

      var deletedCount = 0;
      for (final ref in refs) {
        final existing = await transaction.get(ref);
        if (!existing.exists) continue;
        transaction.delete(ref);
        deletedCount++;
      }
      if (deletedCount == 0) return;

      transaction.set(_firestore.collection('users').doc(followerId), {
        'followingCount': FieldValue.increment(-deletedCount),
      }, SetOptions(merge: true));
      transaction.set(_firestore.collection('users').doc(followingId), {
        'followersCount': FieldValue.increment(-deletedCount),
      }, SetOptions(merge: true));
    });
  }
}
