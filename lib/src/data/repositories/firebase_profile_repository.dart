import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  UserModel _stripPrivateFields(UserModel user) {
    return user.copyWith(
      email: '',
      bio: null,
      penName: null,
      readingHistory: [],
      savedBooks: [],
      bookmarks: [],
      pinnedWorks: [],
      totalPoints: null,
      tier: null,
      pointsLastUpdatedAt: null,
    );
  }

  Future<bool> _isFollowing(String followerId, String followingId) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> deactivateProfile(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isDeactivated': true,
    });
  }

  @override
  Future<UserModel?> getPublicProfile(
    String userId, {
    String? viewerUserId,
  }) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;

    final normalized = normalizeUserMapForModel(snapshot.data()!, snapshot.id);
    final user = UserModel.fromJson(normalized);

    final isSelf = viewerUserId != null && viewerUserId == userId;
    if (user.isDeactivated == true && !isSelf) {
      return null;
    }

    if (isSelf) {
      return user;
    }

    final level = (user.privacyLevel ?? 'public').toLowerCase();
    if (level == 'private') {
      return _stripPrivateFields(user);
    }

    final followersOnly = level == 'followers' ||
        level == 'followersonly' ||
        level == 'followers_only';
    if (followersOnly) {
      if (viewerUserId == null) {
        return _stripPrivateFields(user);
      }
      final follows = await _isFollowing(viewerUserId, userId);
      if (!follows) {
        return _stripPrivateFields(user);
      }
    }

    return user;
  }

  @override
  Future<void> reactivateProfile(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isDeactivated': false,
    });
  }

  @override
  Future<void> updatePrivacyLevel(String userId, String privacyLevel) async {
    await _firestore.collection('users').doc(userId).update({
      'privacyLevel': privacyLevel,
    });
  }

  @override
  Future<void> updateProfileDetails({
    required String userId,
    String? bio,
    String? penName,
    String? displayName,
  }) async {
    final updates = <String, dynamic>{};
    if (bio != null) updates['bio'] = bio;
    if (penName != null) updates['penName'] = penName;
    if (displayName != null) updates['displayName'] = displayName;
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }
}
