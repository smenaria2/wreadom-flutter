import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/author_support.dart';

/// Firestore access for the UPI "support the author" feature.
///
/// No money moves through Wreadom. This only stores the author's UPI ID and
/// the readers' "I supported" claims, which authors can verify.
class FirebaseSupportRepository {
  FirebaseSupportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _settingsRef(String authorId) =>
      _firestore.collection('author_support').doc(authorId);

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('support_claims');

  String claimId(String authorId, String supporterId) =>
      '${authorId}_$supporterId';

  Future<AuthorSupport?> getAuthorSupport(String authorId) async {
    final snapshot = await _settingsRef(authorId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AuthorSupport.fromMap(authorId, data);
  }

  Future<void> saveAuthorSupport({
    required String authorId,
    required String upiId,
    required bool enabled,
    String? message,
  }) async {
    final trimmedMessage = message?.trim() ?? '';
    await _settingsRef(authorId).set({
      'upiId': upiId,
      'enabled': enabled,
      if (trimmedMessage.isNotEmpty) 'message': trimmedMessage,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearAuthorSupport(String authorId) =>
      _settingsRef(authorId).delete();

  /// Claims for an author's supporter list (newest activity first).
  Future<List<SupportClaim>> getClaims(String authorId, {int limit = 100}) async {
    final snapshot = await _claims
        .where('authorId', isEqualTo: authorId)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => SupportClaim.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Records "I've paid". One claim per reader per author: a repeat claim
  /// refreshes an unconfirmed one and is ignored once verified or hidden.
  Future<void> submitClaim({
    required String authorId,
    required String supporterId,
    required String supporterName,
    String? supporterPhotoURL,
    String? utr,
    int? amount,
  }) async {
    final ref = _claims.doc(claimId(authorId, supporterId));
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await ref.get();
    if (existing.exists) {
      final status = existing.data()?['status'];
      if (status != SupportClaim.statusClaimed) return;
      await ref.update({
        'supporterName': supporterName,
        'supporterPhotoURL': supporterPhotoURL,
        'utr': ?utr,
        'amount': ?amount,
        'updatedAt': now,
      });
      return;
    }
    await ref.set({
      'authorId': authorId,
      'supporterId': supporterId,
      'supporterName': supporterName,
      'supporterPhotoURL': supporterPhotoURL,
      'status': SupportClaim.statusClaimed,
      'utr': ?utr,
      'amount': ?amount,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Author-only: mark a claim verified (green tick) or hidden.
  Future<void> setClaimStatus(SupportClaim claim, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _claims.doc(claim.id).update({
      'status': status,
      if (status == SupportClaim.statusVerified) 'verifiedAt': now,
      'updatedAt': now,
    });
  }

  Future<void> deleteClaim(String id) => _claims.doc(id).delete();
}
