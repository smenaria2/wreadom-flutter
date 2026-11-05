import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_support_repository.dart';
import '../../domain/models/author_support.dart';

final supportRepositoryProvider = Provider<FirebaseSupportRepository>((ref) {
  return FirebaseSupportRepository();
});

/// The author's UPI support settings, or null when not set up.
final authorSupportProvider =
    FutureProvider.family<AuthorSupport?, String>((ref, authorId) {
      return ref.read(supportRepositoryProvider).getAuthorSupport(authorId);
    });

/// All claims for an author (filtering/sorting happens in the UI layer via
/// [SupportClaim.visibleSorted]).
final supportClaimsProvider =
    FutureProvider.family<List<SupportClaim>, String>((ref, authorId) {
      return ref.read(supportRepositoryProvider).getClaims(authorId);
    });
