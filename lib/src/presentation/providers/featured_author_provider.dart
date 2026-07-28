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

final homepageFeaturedAuthorProvider = FutureProvider<UserModel?>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);

  final raw = prefs.getString(homepageFeaturedAuthorCacheKey);
  final updatedAt = prefs.getInt(homepageFeaturedAuthorCacheUpdatedAtKey);
  final now = DateTime.now().millisecondsSinceEpoch;
  final isStale =
      updatedAt == null ||
      (now - updatedAt > const Duration(hours: 6).inMilliseconds);

  UserModel? cachedAuthor;
  if (raw != null && raw.isNotEmpty) {
    try {
      cachedAuthor = UserModel.fromJson(asStringMap(jsonDecode(raw)));
    } catch (e) {
      debugPrint('[homepageFeaturedAuthorProvider] Error decoding cache: $e');
    }
  }

  if (cachedAuthor != null && !isStale && refreshTick == 0) {
    return cachedAuthor;
  }

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

    try {
      await prefs.setString(
        homepageFeaturedAuthorCacheKey,
        jsonEncode(selectedAuthor.toJson()),
      );
      await prefs.setInt(homepageFeaturedAuthorCacheUpdatedAtKey, now);
    } catch (e) {
      debugPrint('[homepageFeaturedAuthorProvider] Error saving cache: $e');
    }

    return selectedAuthor;
  } catch (e, stack) {
    debugPrint
        ('[homepageFeaturedAuthorProvider] Error fetching featured author: $e\n$stack');
    return cachedAuthor;
  }
});
