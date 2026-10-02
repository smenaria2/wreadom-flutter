import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages private user account data in `users/{userId}/private/account`.
///
/// Holds sensitive personal info (email, readingHistory, savedBooks, bookmarks,
/// notificationSettings, readingProgress, fcmTokens, newsletterOptOut) isolated
/// from public user profile data in `users/{userId}`.
class UserPrivateAccountService {
  UserPrivateAccountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _accountRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('private')
        .doc('account');
  }

  /// Fetches private account data for [userId]. Returns null if not found.
  Future<Map<String, dynamic>?> getPrivateAccount(String userId) async {
    if (userId.trim().isEmpty) return null;
    try {
      final snap = await _accountRef(userId).get();
      if (!snap.exists || snap.data() == null) return null;
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Overwrites or merges private account data.
  Future<void> setPrivateAccount(
    String userId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (userId.trim().isEmpty) return;
    await _accountRef(userId).set(data, SetOptions(merge: merge));
  }

  /// Updates specific fields in `users/{userId}/private/account`.
  Future<void> updatePrivateAccount(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    if (userId.trim().isEmpty) return;
    await _accountRef(userId).set(updates, SetOptions(merge: true));
  }

  /// Listens to real-time changes of `users/{userId}/private/account`.
  Stream<Map<String, dynamic>?> watchPrivateAccount(String userId) {
    if (userId.trim().isEmpty) return Stream.value(null);
    return _accountRef(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return snap.data();
    });
  }

  /// Merges public profile map with private account map for the active user session.
  static Map<String, dynamic> mergeUserWithPrivate(
    Map<String, dynamic> publicData,
    Map<String, dynamic>? privateData,
  ) {
    final merged = Map<String, dynamic>.from(publicData);
    if (privateData == null || privateData.isEmpty) {
      return merged;
    }

    if (privateData['email'] != null &&
        privateData['email'].toString().isNotEmpty) {
      merged['email'] = privateData['email'];
    }
    if (privateData['readingHistory'] is List) {
      merged['readingHistory'] = privateData['readingHistory'];
    }
    if (privateData['savedBooks'] is List) {
      merged['savedBooks'] = privateData['savedBooks'];
    }
    if (privateData['bookmarks'] is List) {
      merged['bookmarks'] = privateData['bookmarks'];
    }
    if (privateData['notificationSettings'] != null) {
      merged['notificationSettings'] = privateData['notificationSettings'];
    }
    if (privateData['readingProgress'] is Map) {
      merged['readingProgress'] = privateData['readingProgress'];
    }
    if (privateData['fcmTokens'] is List) {
      merged['fcmTokens'] = privateData['fcmTokens'];
    }
    if (privateData['newsletterOptOut'] != null) {
      merged['newsletterOptOut'] = privateData['newsletterOptOut'];
    }
    if (privateData['lastLogin'] != null) {
      merged['lastLogin'] = privateData['lastLogin'];
    }

    return merged;
  }
}
