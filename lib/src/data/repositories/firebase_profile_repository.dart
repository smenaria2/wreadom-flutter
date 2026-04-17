import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

    final followersOnly =
        level == 'followers' ||
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
  Future<List<UserModel>> searchProfiles(String query, {int limit = 10}) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    final lowerTerm = term.toLowerCase();
    final searches = <Query<Map<String, dynamic>>>[
      _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: lowerTerm)
          .where('username', isLessThanOrEqualTo: '$lowerTerm\uf8ff')
          .limit(limit),
      _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: term)
          .where('displayName', isLessThanOrEqualTo: '$term\uf8ff')
          .limit(limit),
      _firestore
          .collection('users')
          .where('penName', isGreaterThanOrEqualTo: term)
          .where('penName', isLessThanOrEqualTo: '$term\uf8ff')
          .limit(limit),
    ];

    final byId = <String, UserModel>{};
    for (final search in searches) {
      try {
        final snapshot = await search.get();
        for (final doc in snapshot.docs) {
          final user = _userFromDoc(doc);
          if (user != null && _isSearchableUser(user)) {
            byId[user.id] = user;
          }
        }
      } catch (e) {
        debugPrint(
          '[FirebaseProfileRepository] Profile prefix search failed: $e',
        );
      }
    }

    if (byId.length < limit) {
      for (final user in await _fallbackSearchProfiles(term, limit: 100)) {
        byId[user.id] = user;
        if (byId.length >= limit) break;
      }
    }

    final results = byId.values.toList()
      ..sort((a, b) {
        final aName = (a.displayName ?? a.username).toLowerCase();
        final bName = (b.displayName ?? b.username).toLowerCase();
        final q = term.toLowerCase();
        final aStarts = aName.startsWith(q);
        final bStarts = bName.startsWith(q);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
        return aName.compareTo(bName);
      });
    return results.take(limit).toList();
  }

  UserModel? _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final normalized = normalizeUserMapForModel(doc.data(), doc.id);
      return UserModel.fromJson(normalized);
    } catch (e) {
      debugPrint(
        '[FirebaseProfileRepository] Error parsing user ${doc.id}: $e',
      );
      return null;
    }
  }

  bool _isSearchableUser(UserModel user) {
    if (user.isDeactivated == true) return false;
    return (user.privacyLevel ?? 'public').toLowerCase() != 'private';
  }

  bool _matchesProfile(UserModel user, String query) {
    final term = query.toLowerCase();
    if (term.isEmpty) return false;
    final values = [
      user.username,
      user.displayName,
      user.penName,
      user.bio,
    ].whereType<String>();
    return values.any((value) => value.toLowerCase().contains(term));
  }

  Future<List<UserModel>> _fallbackSearchProfiles(
    String query, {
    required int limit,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('username')
          .limit(limit)
          .get();

      return snapshot.docs
          .map(_userFromDoc)
          .whereType<UserModel>()
          .where(_isSearchableUser)
          .where((user) => _matchesProfile(user, query))
          .toList();
    } catch (e) {
      debugPrint(
        '[FirebaseProfileRepository] Profile fallback search failed: $e',
      );
      return [];
    }
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
