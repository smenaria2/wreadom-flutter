import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_model.dart';
import '../../utils/map_utils.dart';
import 'homepage_providers.dart';
import 'theme_provider.dart';

const homepageFeaturedAuthorCacheKey = 'homepage_featured_author_cache_v1';
const homepageFeaturedAuthorCacheUpdatedAtKey =
    'homepage_featured_author_cache_updated_at_v1';

/// Notifier that holds the in-memory session featured author.
/// Cleared only on explicit homepage refresh.
class SessionFeaturedAuthorNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  // ignore: use_setters_to_change_properties
  void set(UserModel? author) => state = author;
}

final sessionFeaturedAuthorProvider =
    NotifierProvider<SessionFeaturedAuthorNotifier, UserModel?>(
  SessionFeaturedAuthorNotifier.new,
);

final homepageFeaturedAuthorProvider = FutureProvider<UserModel?>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Watch the counter so the provider re-runs on explicit refresh.
  ref.watch(homepageRefreshCounterProvider);

  // 1. Check in-memory session state first (ref.read — not a dep so it won't
  //    cause an infinite rebuild loop when we set it below).
  final sessionAuthor = ref.read(sessionFeaturedAuthorProvider);
  if (sessionAuthor != null) return sessionAuthor;

  // 2. Try disk cache.
  final raw = prefs.getString(homepageFeaturedAuthorCacheKey);
  UserModel? cachedAuthor;
  if (raw != null && raw.isNotEmpty) {
    try {
      cachedAuthor = UserModel.fromJson(asStringMap(jsonDecode(raw)));
    } catch (e) {
      debugPrint('[homepageFeaturedAuthorProvider] Error decoding cache: $e');
    }
  }

  if (cachedAuthor != null) {
    // Pin this author for the remainder of the session.
    ref.read(sessionFeaturedAuthorProvider.notifier).set(cachedAuthor);
    return cachedAuthor;
  }

  // 3. Fetch from network, pick a random eligible author.
  try {
    final rankedAuthors = await ref.watch(
      homepageRankedAuthorsProvider(HomeAuthorRanking.newAuthors).future,
    );

    final eligibleAuthors =
        rankedAuthors
            .where((ranked) => ranked.metrics.works > 0)
            .map((ranked) => ranked.author)
            .toList();

    if (eligibleAuthors.isEmpty) return cachedAuthor;

    final selectedAuthor =
        eligibleAuthors[math.Random().nextInt(eligibleAuthors.length)];

    // Persist to disk so the same author survives a cold restart.
    try {
      await prefs.setString(
        homepageFeaturedAuthorCacheKey,
        jsonEncode(selectedAuthor.toJson()),
      );
      await prefs.setInt(
        homepageFeaturedAuthorCacheUpdatedAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[homepageFeaturedAuthorProvider] Error saving cache: $e');
    }

    // Pin for this session.
    ref.read(sessionFeaturedAuthorProvider.notifier).set(selectedAuthor);
    return selectedAuthor;
  } catch (e, stack) {
    debugPrint(
      '[homepageFeaturedAuthorProvider] Error fetching featured author: $e\n$stack',
    );
    return cachedAuthor;
  }
});
