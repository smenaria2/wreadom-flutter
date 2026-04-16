import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/follow_repository.dart';

class FirebaseFollowRepository implements FollowRepository {
  FirebaseFollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> followUser({
    required String followerId,
    required String followingId,
  }) async {
    final existing = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _firestore.runTransaction((transaction) async {
      transaction.set(_firestore.collection('follows').doc(), {
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      transaction.set(
        _firestore.collection('users').doc(followerId),
        {
          'followingCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
      transaction.set(
        _firestore.collection('users').doc(followingId),
        {
          'followersCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
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
    return snapshot.docs.map((doc) => doc.data()['followingId'] as String).toList();
  }

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();

    await _firestore.runTransaction((transaction) async {
      for (final doc in snapshot.docs) {
        transaction.delete(doc.reference);
      }
      transaction.set(
        _firestore.collection('users').doc(followerId),
        {
          'followingCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );
      transaction.set(
        _firestore.collection('users').doc(followingId),
        {
          'followersCount': FieldValue.increment(-1),
        },
        SetOptions(merge: true),
      );
    });
  }
}
