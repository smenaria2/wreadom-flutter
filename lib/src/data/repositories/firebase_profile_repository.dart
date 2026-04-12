import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> deactivateProfile(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isDeactivated': true,
    });
  }

  @override
  Future<UserModel?> getPublicProfile(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = mapFirestoreData(snapshot.data()!, snapshot.id);
    return UserModel.fromJson(data);
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
