/// An author's opt-in UPI support settings (`author_support/{authorId}`).
class AuthorSupport {
  const AuthorSupport({
    required this.authorId,
    required this.upiId,
    required this.enabled,
    this.message,
    this.updatedAt,
  });

  final String authorId;
  final String upiId;
  final bool enabled;
  final String? message;
  final int? updatedAt;

  bool get isActive => enabled && upiId.isNotEmpty;

  factory AuthorSupport.fromMap(String authorId, Map<String, dynamic> map) {
    final message = (map['message'] as String?)?.trim();
    return AuthorSupport(
      authorId: authorId,
      upiId: (map['upiId'] as String?)?.trim() ?? '',
      enabled: map['enabled'] == true,
      message: message == null || message.isEmpty ? null : message,
      updatedAt: (map['updatedAt'] as num?)?.toInt(),
    );
  }
}

/// A reader's claim that they supported an author
/// (`support_claims/{authorId}_{supporterId}`).
///
/// UPI gives the app no payment callback, so a claim starts as [claimed]
/// and only becomes [verified] when the author confirms it.
class SupportClaim {
  const SupportClaim({
    required this.id,
    required this.authorId,
    required this.supporterId,
    required this.supporterName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.supporterPhotoURL,
    this.utr,
    this.amount,
    this.verifiedAt,
  });

  static const statusClaimed = 'claimed';
  static const statusVerified = 'verified';
  static const statusHidden = 'hidden';

  /// Unconfirmed claims disappear from the public list after this long.
  static const claimedLifetime = Duration(days: 14);

  final String id;
  final String authorId;
  final String supporterId;
  final String supporterName;
  final String? supporterPhotoURL;
  final String status;
  final String? utr;
  final int? amount;
  final int createdAt;
  final int updatedAt;
  final int? verifiedAt;

  SupportClaim withStatus(String newStatus) => SupportClaim(
    id: id,
    authorId: authorId,
    supporterId: supporterId,
    supporterName: supporterName,
    supporterPhotoURL: supporterPhotoURL,
    status: newStatus,
    utr: utr,
    amount: amount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    verifiedAt: verifiedAt,
  );

  bool get isVerified => status == statusVerified;
  bool get isHidden => status == statusHidden;

  factory SupportClaim.fromMap(String id, Map<String, dynamic> map) {
    return SupportClaim(
      id: id,
      authorId: (map['authorId'] as String?) ?? '',
      supporterId: (map['supporterId'] as String?) ?? '',
      supporterName: (map['supporterName'] as String?) ?? '',
      supporterPhotoURL: map['supporterPhotoURL'] as String?,
      status: (map['status'] as String?) ?? statusClaimed,
      utr: map['utr'] as String?,
      amount: (map['amount'] as num?)?.toInt(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? 0,
      verifiedAt: (map['verifiedAt'] as num?)?.toInt(),
    );
  }

  /// Claims to show in the supporters list: verified first (newest first),
  /// then unconfirmed ones (newest first). Hidden claims are dropped, and
  /// unconfirmed claims older than [claimedLifetime] are dropped unless
  /// [forAuthor] is true, so the author can still confirm late payments.
  static List<SupportClaim> visibleSorted(
    Iterable<SupportClaim> claims, {
    required bool forAuthor,
    DateTime? now,
  }) {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final cutoff = nowMs - claimedLifetime.inMilliseconds;
    final list = claims.where((claim) {
      if (claim.isHidden || claim.supporterName.isEmpty) return false;
      if (claim.isVerified) return true;
      return forAuthor || claim.updatedAt >= cutoff;
    }).toList();
    list.sort((a, b) {
      if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
      final aTime = a.isVerified ? (a.verifiedAt ?? a.updatedAt) : a.updatedAt;
      final bTime = b.isVerified ? (b.verifiedAt ?? b.updatedAt) : b.updatedAt;
      return bTime.compareTo(aTime);
    });
    return list;
  }
}
