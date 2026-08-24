import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/book.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/leaf_attachment.dart';
import '../../domain/models/home_banner.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/homepage/compiled_homepage.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../../data/utils/firestore_utils.dart';
import '../../data/utils/firestore_cache_first.dart';
import '../../utils/book_collaboration_utils.dart';
import '../../utils/map_utils.dart';
import 'auth_providers.dart';
import 'book_providers.dart';
import 'featured_author_provider.dart';
import 'feed_providers.dart';
import 'theme_provider.dart';

import 'dart:math' as math;

const _homepageMetadataCacheKey = 'homepage_metadata_cache_v3';
const _homepageMetadataCacheUpdatedAtKey =
    'homepage_metadata_cache_updated_at_v3';
const _compiledHomepageCacheKey = 'homepage_compiled_cache_v1';
const _compiledHomepageCacheUpdatedAtKey =
    'homepage_compiled_cache_updated_at_v1';
const _homepageBooksCacheKey = 'homepage_books_cache_v3';
const _homepageAuthorWorksCacheKey = 'homepage_author_works_cache_v1';
const _homepageIABooksCacheKey = 'homepage_ia_books_cache_v3';
const _homepageBannersCacheKey = 'homepage_banners_cache_v1';
const _homepageAudioPostsCacheKey = 'homepage_audio_posts_cache_v1';
const _homepageGenreBooksCacheKeyPrefix = 'homepage_genre_books_cache_v1_';
const _homepageRequestTimeout = Duration(seconds: 4);
const _homepageCacheTtl = Duration(hours: 6);
const _compiledHomepageCacheTtl = Duration(hours: 1);
bool _homepageBackgroundRefreshQueued = false;
bool _publicHomepageWarmQueued = false;
String? _userHomepageWarmQueuedFor;

final homepageRefreshCounterProvider =
    NotifierProvider<HomepageRefreshCounter, int>(HomepageRefreshCounter.new);

class HomepageRefreshCounter extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

Future<void> refreshHomepage(WidgetRef ref) async {
  // Preserve the last good payload while the forced refresh is in flight.
  // This avoids turning a manual refresh into a full-screen loading state when
  // the server is slow or unavailable.
  ref.read(homepageRefreshCounterProvider.notifier).bump();
  ref.invalidate(compiledHomepageProvider);
  ref.invalidate(homepageMetadataProvider);
  ref.invalidate(homepageRecommendedBooksProvider);
  ref.invalidate(homepageBooksProvider);
  ref.invalidate(homepageAuthorWorksProvider);
  ref.invalidate(homepageFeaturedAuthorProvider);
  ref.invalidate(homepageIABooksProvider);
  ref.invalidate(homepageAuthorsProvider);
  ref.invalidate(homepageTrendingWorksProvider);
  ref.invalidate(homepageAudioPostsProvider);
  ref.invalidate(homepageDownloadedBooksProvider);
  ref.invalidate(readingHistoryBooksProvider);
  ref.invalidate(homepageOriginalsProvider);
  ref.invalidate(homepagePopularProvider);
  ref.invalidate(homepageRecentProvider);
  ref.invalidate(homepageGenreProvider);
  ref.invalidate(homeBannersProvider);
  ref.invalidate(rawBooksWithLeavesProvider);
  ref.invalidate(booksWithLeavesProvider);
  ref.invalidate(contentOnAgaazTopicsProvider);
}

void warmPublicHomepageCache(WidgetRef ref) {
  if (_publicHomepageWarmQueued) return;
  _publicHomepageWarmQueued = true;
  unawaited(
    ref
        .read(compiledHomepageProvider.future)
        .then<void>((_) {})
        .catchError((_) {}),
  );
}

Future<void> warmUserHomepageCache(
  WidgetRef ref, {
  Duration? deferDuration,
}) async {
  UserModel? initialUser;
  try {
    initialUser = await ref.read(currentUserProvider.future);
  } catch (_) {
    return;
  }
  if (initialUser == null || _userHomepageWarmQueuedFor == initialUser.id) {
    return;
  }
  _userHomepageWarmQueuedFor = initialUser.id;
  if (deferDuration != null && deferDuration > Duration.zero) {
    await Future.delayed(deferDuration);
  }
  UserModel? currentUser;
  try {
    currentUser = await ref.read(currentUserProvider.future);
  } catch (_) {
    return;
  }
  if (currentUser?.id != initialUser.id) {
    if (_userHomepageWarmQueuedFor == initialUser.id) {
      _userHomepageWarmQueuedFor = null;
    }
    return;
  }
  await Future.wait(<Future<Object?>>[
    ref.read(readingHistoryBooksProvider(5).future).then<Object?>((_) => null),
    ref.read(savedBooksProvider.future).then<Object?>((_) => null),
    ref.read(homepageDownloadedBooksProvider.future).then<Object?>((_) => null),
  ]).catchError((_) => <Object?>[]);
}

void clearUserHomepageWarmState(String userId) {
  if (_userHomepageWarmQueuedFor == userId) {
    _userHomepageWarmQueuedFor = null;
  }
}

void _queueHomepageBackgroundRefresh(Ref ref) {
  if (_homepageBackgroundRefreshQueued) return;
  _homepageBackgroundRefreshQueued = true;
  scheduleMicrotask(() async {
    final didRefresh = await _refreshHomepageCachesInBackground(ref);
    if (didRefresh) {
      ref.read(homepageRefreshCounterProvider.notifier).bump();
    }
    Timer(const Duration(seconds: 30), () {
      _homepageBackgroundRefreshQueued = false;
    });
  });
}

/// Returns true when the last successful homepage cache write is older than
/// [_homepageCacheTtl]. An absent timestamp is treated as stale so that a
/// fresh network fetch is always triggered on first run.
bool _isCacheStale(SharedPreferences prefs) {
  final updatedAt = prefs.getInt(_homepageMetadataCacheUpdatedAtKey);
  if (updatedAt == null) return true;
  final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAt;
  return ageMs > _homepageCacheTtl.inMilliseconds;
}

bool _isCompiledHomepageCacheStale(SharedPreferences prefs) {
  final updatedAt = prefs.getInt(_compiledHomepageCacheUpdatedAtKey);
  if (updatedAt == null) return true;
  final ageMs = DateTime.now().millisecondsSinceEpoch - updatedAt;
  return ageMs > _compiledHomepageCacheTtl.inMilliseconds;
}

bool _hasCompiledHomepageContent(CompiledHomepage? homepage) {
  return homepage != null && homepage.hasPublicContent;
}

CompiledHomepage? _readCompiledHomepageCache(SharedPreferences prefs) {
  return _readCachedValue<CompiledHomepage>(
    prefs,
    _compiledHomepageCacheKey,
    (json) => CompiledHomepage.fromJson(asStringMap(json)),
  );
}

T? _readCachedValue<T>(
  SharedPreferences prefs,
  String key,
  T Function(Object json) decoder,
) {
  final raw = prefs.getString(key);
  if (raw == null || raw.isEmpty) return null;
  try {
    return decoder(jsonDecode(raw));
  } catch (_) {
    return null;
  }
}

Future<bool> _writeCachedValue(
  SharedPreferences prefs,
  String key,
  Object json,
) async {
  try {
    return await prefs.setString(key, jsonEncode(json));
  } catch (e, stack) {
    debugPrint('[_writeCachedValue:$key] Error: $e\n$stack');
    return false;
  }
}

Future<void> _clearLegacyPublicHomepageCaches(SharedPreferences prefs) async {
  final genreCacheKeys = prefs.getKeys().where(
    (key) => key.startsWith(_homepageGenreBooksCacheKeyPrefix),
  );
  await Future.wait([
    prefs.remove(_homepageMetadataCacheKey),
    prefs.remove(_homepageMetadataCacheUpdatedAtKey),
    prefs.remove(_homepageBooksCacheKey),
    prefs.remove(_homepageAuthorWorksCacheKey),
    prefs.remove(_homepageIABooksCacheKey),
    prefs.remove(_homepageBannersCacheKey),
    prefs.remove(_homepageAudioPostsCacheKey),
    ...genreCacheKeys.map(prefs.remove),
  ]);
}

Future<List<Book>> _safeBookList(
  String label,
  Future<List<Book>> request,
) async {
  try {
    return await _withHomepageTimeout(request, label);
  } catch (e, stack) {
    debugPrint('[_safeBookList:$label] Error: $e\n$stack');
    return <Book>[];
  }
}

Future<T> _withHomepageTimeout<T>(Future<T> request, String label) async {
  final stopwatch = Stopwatch()..start();
  try {
    final value = await request.timeout(
      _homepageRequestTimeout,
      onTimeout: () => throw TimeoutException(
        '$label did not complete',
        _homepageRequestTimeout,
      ),
    );
    FirestoreCacheFirst.logDiagnostic(
      label,
      'server_success',
      stopwatch.elapsed,
    );
    return value;
  } on TimeoutException {
    FirestoreCacheFirst.logDiagnostic(
      label,
      'server_timeout',
      stopwatch.elapsed,
    );
    rethrow;
  } on FirebaseException catch (error) {
    FirestoreCacheFirst.logDiagnostic(
      label,
      'server_error',
      stopwatch.elapsed,
      error.code,
    );
    rethrow;
  } catch (_) {
    FirestoreCacheFirst.logDiagnostic(label, 'server_error', stopwatch.elapsed);
    rethrow;
  }
}

Future<CompiledHomepage?> _fetchAndCacheCompiledHomepage(
  SharedPreferences prefs,
) async {
  final doc = await _withHomepageTimeout(
    FirebaseFirestore.instance
        .collection('settings')
        .doc('homepage_compiled')
        .get(),
    'homepage_compiled',
  );
  final data = asStringMap(doc.data());
  if (data.isEmpty) return null;

  final homepage = CompiledHomepage.fromJson(data);
  if (!homepage.hasPublicContent) return null;
  await _clearLegacyPublicHomepageCaches(prefs);
  final cached = await _writeCachedValue(
    prefs,
    _compiledHomepageCacheKey,
    homepage.toJson(),
  );
  if (cached) {
    await prefs.setInt(
      _compiledHomepageCacheUpdatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
  return homepage;
}

final compiledHomepageProvider = FutureProvider<CompiledHomepage?>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cached = _readCompiledHomepageCache(prefs);

  if (_hasCompiledHomepageContent(cached)) {
    if (refreshTick > 0 || _isCompiledHomepageCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  try {
    final fresh = await _fetchAndCacheCompiledHomepage(prefs);
    if (_hasCompiledHomepageContent(fresh)) return fresh;
  } catch (e, stack) {
    debugPrint('[compiledHomepageProvider] Error: $e\n$stack');
  }

  return _hasCompiledHomepageContent(cached) ? cached : null;
});

Future<bool> _refreshHomepageCachesInBackground(Ref ref) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final compiled = await _fetchAndCacheCompiledHomepage(prefs);
    if (_hasCompiledHomepageContent(compiled)) return true;

    final metadata = await _fetchAndCacheHomepageMetadata(prefs);
    final recommendedBooks = await _fetchRecommendedBooks(ref, metadata);
    await _fetchAndCacheHomepageBooks(ref, prefs, metadata);
    await Future.wait([
      _fetchAndCacheHomeBanners(prefs),
      _fetchAndCacheHomepageAuthorWorks(ref, prefs),
      _fetchAndCacheHomepageIABooks(prefs, recommendedBooks),
    ]);
    return true;
  } catch (e, stack) {
    debugPrint('[_refreshHomepageCachesInBackground] Error: $e\n$stack');
    return false;
  }
}

Future<Map<String, BookRecommendationStats>> _fetchLiveRecommendationStats({
  int limit = 200,
}) async {
  try {
    final snapshot = await _withHomepageTimeout(
      FirebaseFirestore.instance
          .collection('book_stats')
          .orderBy('upvotes', descending: true)
          .limit(limit)
          .get(),
      'book_stats by upvotes',
    );
    return {
      for (final doc in snapshot.docs)
        if (_hasPositiveRecommendationStats(doc.data()))
          doc.id: _statsFromMap(doc.data()),
    };
  } catch (e, stack) {
    debugPrint('[_fetchLiveRecommendationStats] Error: $e\n$stack');
    return const <String, BookRecommendationStats>{};
  }
}

bool _hasPositiveRecommendationStats(Map<String, dynamic> data) {
  final upvotes = (data['upvotes'] as num?)?.toInt() ?? 0;
  final recommendationCount =
      (data['recommendationCount'] as num?)?.toInt() ?? upvotes;
  return upvotes > 0 || recommendationCount > 0;
}

BookRecommendationStats _statsFromMap(Map<String, dynamic> data) {
  final upvotes = (data['upvotes'] as num?)?.toInt() ?? 0;
  final downvotes = (data['downvotes'] as num?)?.toInt() ?? 0;
  return BookRecommendationStats(
    upvotes: upvotes,
    downvotes: downvotes,
    recommendationCount:
        (data['recommendationCount'] as num?)?.toInt() ?? upvotes - downvotes,
    viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
  );
}

Map<String, BookRecommendationStats> _mergeRecommendationStats(
  Map<String, BookRecommendationStats> cached,
  Map<String, BookRecommendationStats> live,
) {
  if (live.isEmpty) return cached;
  return {...cached, ...live};
}

bool _hasHomepageMetadataContent(HomepageMetadata metadata) {
  return metadata.authors.isNotEmpty ||
      metadata.recommendationStats.isNotEmpty ||
      metadata.dailyTopics.isNotEmpty;
}

Future<HomepageMetadata> _fetchAndCacheHomepageMetadata(
  SharedPreferences prefs,
) async {
  final doc = await _withHomepageTimeout(
    FirebaseFirestore.instance
        .collection('settings')
        .doc('homepage_metadata')
        .get(),
    'homepage_metadata',
  );

  final data = asStringMap(doc.data());
  final authors = data['authors'];
  if (authors is List) {
    data['authors'] = authors.whereType<Map>().map((raw) {
      final userMap = asStringMap(raw);
      final id = userMap['id']?.toString() ?? '';
      return normalizeUserMapForModel(userMap, id);
    }).toList();
  }

  final metadata = HomepageMetadata.fromJson(data);
  final liveStats = await _fetchLiveRecommendationStats();
  final mergedMetadata = metadata.copyWith(
    recommendationStats: _mergeRecommendationStats(
      metadata.recommendationStats,
      liveStats,
    ),
  );
  await _writeCachedValue(
    prefs,
    _homepageMetadataCacheKey,
    mergedMetadata.toJson(),
  );
  await prefs.setInt(
    _homepageMetadataCacheUpdatedAtKey,
    DateTime.now().millisecondsSinceEpoch,
  );
  return mergedMetadata;
}

Future<List<HomeBanner>> _fetchAndCacheHomeBanners(
  SharedPreferences prefs,
) async {
  final byId = <String, HomeBanner>{};

  try {
    final metadataDoc = await _withHomepageTimeout(
      FirebaseFirestore.instance
          .collection('settings')
          .doc('homepage_metadata')
          .get(),
      'homepage_metadata_banners',
    );
    final rawBanners = asStringMap(metadataDoc.data())['homeBanners'];
    if (rawBanners is List) {
      for (final raw in rawBanners.whereType<Map>()) {
        final banner = HomeBanner.fromJson(asStringMap(raw));
        if (banner.id.isNotEmpty) byId[banner.id] = banner;
      }
    }
  } catch (e, stack) {
    debugPrint('[_fetchAndCacheHomeBanners:metadata] Error: $e\n$stack');
  }

  try {
    final snapshot = await _withHomepageTimeout(
      FirebaseFirestore.instance.collection('home-banners').limit(10).get(),
      'home-banners',
    );
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      final banner = HomeBanner.fromJson(data);
      byId[banner.id] = banner;
    }
  } catch (e, stack) {
    debugPrint('[_fetchAndCacheHomeBanners:collection] Error: $e\n$stack');
  }

  final banners =
      byId.values
          .where((banner) => banner.isEnabled && banner.title.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => b.sortTimestamp.compareTo(a.sortTimestamp));
  final cached = _readCachedValue<List<HomeBanner>>(
    prefs,
    _homepageBannersCacheKey,
    (json) => (json as List)
        .map((raw) => HomeBanner.fromJson(asStringMap(raw)))
        .toList(),
  );
  if (banners.isEmpty && cached != null && cached.isNotEmpty) return cached;
  if (banners.isNotEmpty) {
    await _writeCachedValue(
      prefs,
      _homepageBannersCacheKey,
      banners.map((banner) => banner.toJson()).toList(),
    );
  }
  return banners;
}

Future<List<Book>> _fetchRecommendedBooks(
  Ref ref,
  HomepageMetadata metadata, {
  int limit = 80,
}) {
  final communityIds = _positiveRecommendationIds(metadata, limit: limit);
  if (communityIds.isEmpty) return Future.value(<Book>[]);
  return _safeBookList(
    'recommended books by id',
    ref.read(bookRepositoryProvider).getBooksByIds(communityIds),
  );
}

Future<List<Book>> _fetchAndCacheHomepageBooks(
  Ref ref,
  SharedPreferences prefs,
  HomepageMetadata metadata,
) async {
  final statsData = metadata.recommendationStats;
  final repo = ref.read(bookRepositoryProvider);
  final communityIds = _positiveRecommendationIds(metadata, limit: 60);
  final recommendedBookIds = communityIds.toSet();

  final results = await Future.wait([
    _safeBookList('homepage original books', repo.getOriginalBooks(limit: 120)),
    _fetchRecommendedBooks(ref, metadata),
    _safeBookList('homepage popular books', repo.getPopularBooks(limit: 80)),
  ]);
  final downloaded = ref.read(offlineServiceProvider).getDownloadedBooks();

  final uniqueBooks = <String, Book>{};

  void addBooks(List<Book> books) {
    for (final book in books) {
      uniqueBooks[book.id] = book;
    }
  }

  addBooks(results[0]);
  addBooks(results[1]);
  addBooks(results[2]);
  addBooks(downloaded);

  final combinedBooks = _homepageAllowedBooks(
    uniqueBooks.values,
    recommendedBookIds,
  );

  combinedBooks.sort((a, b) {
    double getScore(Book book) {
      final avgRating = book.averageRating ?? 0.0;
      final ratingsCount = book.ratingsCount ?? 0;
      final stats = statsData[book.id];

      final popularityScore =
          avgRating * math.log(ratingsCount + 1) / math.ln10 +
          (stats?.upvotes ?? 0) * 0.6 +
          (stats?.recommendationCount ?? 0) * 0.1;

      final weekInMs = 7 * 24 * 60 * 60 * 1000;
      final ageInWeeks = book.createdAt != null
          ? (DateTime.now().millisecondsSinceEpoch - book.createdAt!) / weekInMs
          : 0;

      final recencyScore = math.exp(-math.max(0, ageInWeeks) * 0.1);
      return popularityScore * (1 + recencyScore);
    }

    final scoreA = getScore(a);
    final scoreB = getScore(b);
    return scoreB.compareTo(scoreA);
  });

  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageBooksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (combinedBooks.isEmpty && cached != null && cached.isNotEmpty) {
    return cached;
  }

  if (combinedBooks.isNotEmpty) {
    await _writeCachedValue(
      prefs,
      _homepageBooksCacheKey,
      combinedBooks.map((book) => book.toJson()).toList(),
    );
  }
  return combinedBooks;
}

Future<List<Book>> _fetchAndCacheHomepageAuthorWorks(
  Ref ref,
  SharedPreferences prefs,
) async {
  final repo = ref.read(bookRepositoryProvider);
  final works = await _safeBookList(
    'homepage author works',
    repo.getOriginalBooks(limit: 240),
  );
  final unique = <String, Book>{};
  for (final book in works.where(_isPublishedOriginal)) {
    unique[book.id] = book;
  }
  final result = unique.values.toList();
  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageAuthorWorksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (result.isEmpty && cached != null && cached.isNotEmpty) return cached;
  if (result.isNotEmpty) {
    await _writeCachedValue(
      prefs,
      _homepageAuthorWorksCacheKey,
      result.map((book) => book.toJson()).toList(),
    );
  }
  return result;
}

Future<List<Book>> _fetchAndCacheHomepageIABooks(
  SharedPreferences prefs,
  List<Book> recommendedBooks,
) async {
  final result = recommendedBooks.where(_isArchiveBook).take(20).toList();
  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageIABooksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (result.isEmpty && cached != null && cached.isNotEmpty) return cached;
  if (result.isNotEmpty) {
    await _writeCachedValue(
      prefs,
      _homepageIABooksCacheKey,
      result.map((book) => book.toJson()).toList(),
    );
  }
  return result;
}

List<Book> _uniqueBooks(Iterable<Book> books) {
  final byId = <String, Book>{};
  for (final book in books) {
    byId.putIfAbsent(book.id, () => book);
  }
  return byId.values.toList();
}

List<Book> _withoutIds(List<Book> books, Set<String> ids, {int limit = 20}) {
  final result = <Book>[];
  final seen = <String>{};
  for (final book in books) {
    if (ids.contains(book.id) || !seen.add(book.id)) continue;
    result.add(book);
    if (result.length >= limit) break;
  }
  if (result.length >= limit) return result;

  for (final book in books) {
    if (!seen.add(book.id)) continue;
    result.add(book);
    if (result.length >= limit) break;
  }
  return result;
}

List<Book> _homepageAllowedBooks(
  Iterable<Book> books,
  Set<String> recommendedBookIds,
) {
  return books.where((book) {
    if (!_isArchiveBook(book)) return true;
    return recommendedBookIds.contains(book.id);
  }).toList();
}

int _recommendationRankScore(BookRecommendationStats stats) {
  if (stats.upvotes > 0) return stats.upvotes;
  return stats.recommendationCount;
}

double _bookPopularityScore(
  Book book,
  Map<String, BookRecommendationStats> statsData,
) {
  final avgRating = book.averageRating ?? 0.0;
  final ratingsCount = book.ratingsCount ?? 0;
  final stats = statsData[book.id];
  final reads = math.log((book.viewCount ?? 0) + 1) / math.ln10;
  return reads +
      avgRating * math.log(ratingsCount + 1) / math.ln10 +
      (stats?.upvotes ?? 0) * 0.6 +
      (stats?.recommendationCount ?? 0) * 0.2 +
      ((stats?.upvotes ?? 0) - (stats?.downvotes ?? 0)) * 0.05;
}

final homepageMetadataProvider = FutureProvider<HomepageMetadata>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null &&
      cachedCompiled.metadata.value.authors.isNotEmpty) {
    return cachedCompiled.metadata.value;
  }
  final cached = _readCachedValue<HomepageMetadata>(
    prefs,
    _homepageMetadataCacheKey,
    (json) => HomepageMetadata.fromJson(asStringMap(json)),
  );

  if (cached != null && _hasHomepageMetadataContent(cached)) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.metadata.value.authors.isNotEmpty) {
    return compiled.metadata.value;
  }

  try {
    return _fetchAndCacheHomepageMetadata(prefs);
  } catch (e, stack) {
    debugPrint('[homepageMetadataProvider] Error: $e\n$stack');
    return const HomepageMetadata();
  }
});

final homeBannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null &&
      cachedCompiled.metadata.homeBanners.isNotEmpty) {
    return cachedCompiled.metadata.homeBanners;
  }
  final cached = _readCachedValue<List<HomeBanner>>(
    prefs,
    _homepageBannersCacheKey,
    (json) => (json as List)
        .map((raw) => HomeBanner.fromJson(asStringMap(raw)))
        .toList(),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.metadata.homeBanners.isNotEmpty) {
    return compiled.metadata.homeBanners;
  }

  try {
    return _fetchAndCacheHomeBanners(prefs);
  } catch (e, stack) {
    debugPrint('[homeBannersProvider] Error: $e\n$stack');
    return const <HomeBanner>[];
  }
});

List<String> _positiveRecommendationIds(
  HomepageMetadata metadata, {
  int limit = 60,
}) {
  final entries = metadata.recommendationStats.entries.toList()
    ..sort((a, b) {
      final scoreCompare = _recommendationRankScore(
        b.value,
      ).compareTo(_recommendationRankScore(a.value));
      if (scoreCompare != 0) return scoreCompare;
      final netA = a.value.upvotes - a.value.downvotes;
      final netB = b.value.upvotes - b.value.downvotes;
      return netB.compareTo(netA);
    });

  return entries
      .where((entry) {
        final stats = entry.value;
        return stats.upvotes > 0 || stats.recommendationCount > 0;
      })
      .map((entry) => entry.key)
      .take(limit)
      .toList();
}

bool _isArchiveBook(Book book) {
  return book.source == 'archive' ||
      (book.source == null &&
          !(book.id.length == 20 &&
              RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(book.id)));
}

final homepageRecommendedBooksProvider = FutureProvider<List<Book>>((
  ref,
) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  return _fetchRecommendedBooks(ref, metadata);
});

final homepageBooksProvider = FutureProvider<List<Book>>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null && cachedCompiled.shelves.allBooks.isNotEmpty) {
    return cachedCompiled.shelves.allBooks;
  }
  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageBooksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.shelves.allBooks.isNotEmpty) {
    return compiled.shelves.allBooks;
  }

  try {
    final metadata = await ref.watch(homepageMetadataProvider.future);
    return _fetchAndCacheHomepageBooks(ref, prefs, metadata);
  } catch (e, stack) {
    debugPrint('[homepageBooksProvider] Error: $e\n$stack');
    return const <Book>[];
  }
});

final homepageAuthorsProvider = FutureProvider((ref) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  return metadata.authors;
});

enum HomeAuthorRanking { newAuthors, mostRead, mostPublished }

final homepageAuthorWorksProvider = FutureProvider<List<Book>>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null && cachedCompiled.shelves.authorWorks.isNotEmpty) {
    return cachedCompiled.shelves.authorWorks;
  }
  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageAuthorWorksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.shelves.authorWorks.isNotEmpty) {
    return compiled.shelves.authorWorks;
  }

  try {
    return _fetchAndCacheHomepageAuthorWorks(ref, prefs);
  } catch (e, stack) {
    debugPrint('[homepageAuthorWorksProvider] Error: $e\n$stack');
    return const <Book>[];
  }
});

final homepageAuthorBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  authorId,
) async {
  final normalizedAuthorId = authorId.trim();
  if (normalizedAuthorId.isEmpty) return const <Book>[];

  final works = await ref.watch(homepageAuthorWorksProvider.future);
  var books = works.where((book) {
    if (!_isPublishedOriginal(book)) return false;
    return acceptedAuthorIdsFor(book).contains(normalizedAuthorId);
  }).toList();

  if (books.isEmpty) {
    final allHomeBooks = await ref.watch(homepageBooksProvider.future);
    books = allHomeBooks.where((book) {
      if (!_isPublishedOriginal(book)) return false;
      return acceptedAuthorIdsFor(book).contains(normalizedAuthorId);
    }).toList();
  }

  if (books.isEmpty) {
    try {
      final userBooks = await ref.watch(
        userBooksProvider(normalizedAuthorId).future,
      );
      books = userBooks.where(_isPublishedOriginal).toList();
    } catch (e, stack) {
      debugPrint(
        '[homepageAuthorBooksProvider:$normalizedAuthorId] Error: $e\n$stack',
      );
    }
  }

  books.sort((a, b) {
    final aTime = a.updatedAt ?? a.createdAt ?? 0;
    final bTime = b.updatedAt ?? b.createdAt ?? 0;
    return bTime.compareTo(aTime);
  });

  return books;
});

class HomeAuthorMetrics {
  const HomeAuthorMetrics({
    required this.works,
    required this.reads,
    required this.averageRating,
    required this.ratingWeight,
  });

  final int works;
  final int reads;
  final double averageRating;
  final int ratingWeight;
}

class RankedHomeAuthor {
  const RankedHomeAuthor({required this.author, required this.metrics});

  final UserModel author;
  final HomeAuthorMetrics metrics;
}

HomeAuthorMetrics homeAuthorMetricsFor(String authorId, Iterable<Book> books) {
  final normalizedAuthorId = authorId.trim();
  final byId = <String, Book>{};
  for (final book in books) {
    if (!_isPublishedOriginal(book)) continue;
    if (!acceptedAuthorIdsFor(book).contains(normalizedAuthorId)) continue;
    byId[book.id] = book;
  }

  final stats = _AuthorStats();
  for (final book in byId.values) {
    stats.works += 1;
    stats.reads += book.viewCount ?? 0;
    final rating = book.averageRating ?? 0;
    final ratingsCount = book.ratingsCount ?? 0;
    if (rating > 0 && ratingsCount > 0) {
      stats.ratingWeight += ratingsCount;
      stats.ratingTotal += rating * ratingsCount;
    }
  }
  return stats.toMetrics();
}

final homepageRankedAuthorsProvider =
    FutureProvider.family<List<RankedHomeAuthor>, HomeAuthorRanking>((
      ref,
      ranking,
    ) async {
      final metadata = await ref.watch(homepageMetadataProvider.future);
      final metricsEntries = await Future.wait(
        metadata.authors.map((author) async {
          try {
            final books = await ref.watch(userBooksProvider(author.id).future);
            return MapEntry(author.id, homeAuthorMetricsFor(author.id, books));
          } catch (error, stack) {
            debugPrint(
              '[homepageRankedAuthorsProvider:${author.id}] Error: '
              '$error\n$stack',
            );
            return MapEntry(author.id, _emptyHomeAuthorMetrics);
          }
        }),
      );
      final metricsByAuthorId = Map<String, HomeAuthorMetrics>.fromEntries(
        metricsEntries,
      );

      final authors = metadata.authors.where((author) {
        return (metricsByAuthorId[author.id]?.works ?? 0) >= 1;
      }).toList();

      double score(UserModel author) {
        final metrics = metricsByAuthorId[author.id] ?? _emptyHomeAuthorMetrics;
        return switch (ranking) {
          HomeAuthorRanking.newAuthors =>
            (_normalizedEpochMillis(author.createdAt) ?? 0).toDouble(),
          HomeAuthorRanking.mostRead => metrics.reads.toDouble(),
          HomeAuthorRanking.mostPublished => metrics.works.toDouble(),
        };
      }

      authors.sort((a, b) {
        final createdA = _normalizedEpochMillis(a.createdAt) ?? 0;
        final createdB = _normalizedEpochMillis(b.createdAt) ?? 0;
        if (ranking == HomeAuthorRanking.newAuthors) {
          final createdCompare = createdB.compareTo(createdA);
          if (createdCompare != 0) return createdCompare;
          final worksA = metricsByAuthorId[a.id]?.works ?? 0;
          final worksB = metricsByAuthorId[b.id]?.works ?? 0;
          return worksA.compareTo(worksB);
        }

        final scoreCompare = score(b).compareTo(score(a));
        if (scoreCompare != 0) return scoreCompare;
        return createdB.compareTo(createdA);
      });

      return authors
          .take(20)
          .map(
            (author) => RankedHomeAuthor(
              author: author,
              metrics: metricsByAuthorId[author.id] ?? _emptyHomeAuthorMetrics,
            ),
          )
          .toList();
    });

const _emptyHomeAuthorMetrics = HomeAuthorMetrics(
  works: 0,
  reads: 0,
  averageRating: 0,
  ratingWeight: 0,
);

final homepageTrendingWorksProvider = FutureProvider<List<Book>>((ref) async {
  final cachedCompiled = _readCompiledHomepageCache(
    ref.watch(sharedPreferencesProvider),
  );
  if (cachedCompiled != null && cachedCompiled.shelves.trending.isNotEmpty) {
    return cachedCompiled.shelves.trending;
  }

  final metadata = await ref.watch(homepageMetadataProvider.future);
  final books = await ref.watch(homepageBooksProvider.future);
  final refreshedCompiled = _readCompiledHomepageCache(
    ref.read(sharedPreferencesProvider),
  );
  if (refreshedCompiled != null &&
      refreshedCompiled.shelves.trending.isNotEmpty) {
    return refreshedCompiled.shelves.trending;
  }
  final statsData = metadata.recommendationStats;
  final now = DateTime.now().millisecondsSinceEpoch;
  final weekInMs = 7 * 24 * 60 * 60 * 1000;

  double score(Book book) {
    final ageWeeks = book.createdAt != null
        ? (now - book.createdAt!) / weekInMs
        : 8.0;
    final recency = math.exp(-math.max(0, ageWeeks) * 0.25);
    final reads = math.log((book.viewCount ?? 0) + 1) / math.ln10;
    final rating =
        (book.averageRating ?? 0) *
        math.log((book.ratingsCount ?? 0) + 1) /
        math.ln10;
    final recommendations =
        (statsData[book.id]?.recommendationCount ?? 0) * 0.15;
    return recency * 2.0 + reads + rating + recommendations;
  }

  final originals = books.where(_isPublishedOriginal).take(10).toList();
  final excluded = originals.map((book) => book.id).toSet();
  final sorted = _withoutIds(books, excluded, limit: books.length)
    ..sort((a, b) => score(b).compareTo(score(a)));
  return sorted.take(24).toList();
});

int? _normalizedEpochMillis(int? value) {
  if (value == null || value <= 0) return null;
  return value < 100000000000 ? value * 1000 : value;
}

bool _isPublicFeedPost(FeedPost post) {
  final visibility = post.visibility.trim().toLowerCase();
  final privacy = post.privacy?.trim().toLowerCase();
  return visibility == 'public' && (privacy == null || privacy == 'public');
}

bool _hasCertificateLeaf(Book book) {
  return book.leaves?.any((leaf) => leaf.type == LeafType.certificate) == true;
}

bool _isPublishedOriginal(Book book) {
  if (book.isOriginal != true) return false;
  final status = book.status?.trim().toLowerCase();
  return status == null || status.isEmpty || status == 'published';
}

class _AuthorStats {
  int works = 0;
  int reads = 0;
  double ratingTotal = 0;
  int ratingWeight = 0;

  double get averageRating =>
      ratingWeight == 0 ? 0 : ratingTotal / ratingWeight;

  double get weightedRatingScore {
    if (ratingWeight == 0) return 0;
    return averageRating * math.log(ratingWeight + 1) / math.ln10;
  }

  HomeAuthorMetrics toMetrics() {
    return HomeAuthorMetrics(
      works: works,
      reads: reads,
      averageRating: averageRating,
      ratingWeight: ratingWeight,
    );
  }
}

final homepageDownloadedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final service = ref.watch(offlineServiceProvider);
  await service.init();
  return service.getDownloadedBooks();
});

final homepageIABooksProvider = FutureProvider<List<Book>>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null &&
      cachedCompiled.shelves.communityClassics.isNotEmpty) {
    return cachedCompiled.shelves.communityClassics;
  }
  final cached = _readCachedValue<List<Book>>(
    prefs,
    _homepageIABooksCacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.shelves.communityClassics.isNotEmpty) {
    return compiled.shelves.communityClassics;
  }

  try {
    final books = await ref.watch(homepageRecommendedBooksProvider.future);
    return _fetchAndCacheHomepageIABooks(prefs, books);
  } catch (e, stack) {
    debugPrint('[homepageIABooksProvider] Error: $e\n$stack');
    return const <Book>[];
  }
});

// Category Providers powered by the Homepage combined list
final homepageOriginalsProvider = FutureProvider<List<Book>>((ref) async {
  final cachedCompiled = _readCompiledHomepageCache(
    ref.watch(sharedPreferencesProvider),
  );
  if (cachedCompiled != null && cachedCompiled.shelves.originals.isNotEmpty) {
    return cachedCompiled.shelves.originals;
  }

  final books = await ref.watch(homepageBooksProvider.future);
  final refreshedCompiled = _readCompiledHomepageCache(
    ref.read(sharedPreferencesProvider),
  );
  if (refreshedCompiled != null &&
      refreshedCompiled.shelves.originals.isNotEmpty) {
    return refreshedCompiled.shelves.originals;
  }
  final originals =
      books
          .where(
            (book) => _isPublishedOriginal(book) && !_hasCertificateLeaf(book),
          )
          .toList()
        ..sort((a, b) {
          final aTime = a.updatedAt ?? a.createdAt ?? 0;
          final bTime = b.updatedAt ?? b.createdAt ?? 0;
          return bTime.compareTo(aTime);
        });
  return originals.take(24).toList();
});

final homepageAudioPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final stopwatch = Stopwatch()..start();
  final prefs = ref.watch(sharedPreferencesProvider);
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  if (cachedCompiled != null && cachedCompiled.shelves.audioPosts.isNotEmpty) {
    return cachedCompiled.shelves.audioPosts
        .where(_isPublicFeedPost)
        .toList(growable: false);
  }
  final cached = _readCachedValue<List<FeedPost>>(
    prefs,
    _homepageAudioPostsCacheKey,
    (json) => (json as List)
        .map((raw) => FeedPost.fromJson(asStringMap(raw)))
        .where(_isPublicFeedPost)
        .toList(growable: false),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  if (compiled != null && compiled.shelves.audioPosts.isNotEmpty) {
    return compiled.shelves.audioPosts
        .where(_isPublicFeedPost)
        .toList(growable: false);
  }

  final remaining =
      FirestoreCacheFirst.defaultServerTimeout - stopwatch.elapsed;
  if (remaining <= Duration.zero) return const <FeedPost>[];
  try {
    final posts = await ref
        .watch(feedRepositoryProvider)
        .getAudioFeedPosts(limit: 12)
        .timeout(remaining);
    final publicPosts = posts.where(_isPublicFeedPost).toList(growable: false);
    await _writeCachedValue(
      prefs,
      _homepageAudioPostsCacheKey,
      publicPosts.map((post) => post.toJson()).toList(),
    );
    return publicPosts;
  } catch (_) {
    return const <FeedPost>[];
  }
});
final homepagePopularProvider = FutureProvider<List<Book>>((ref) async {
  final cachedCompiled = _readCompiledHomepageCache(
    ref.watch(sharedPreferencesProvider),
  );
  if (cachedCompiled != null && cachedCompiled.shelves.popular.isNotEmpty) {
    return cachedCompiled.shelves.popular;
  }

  final metadata = await ref.watch(homepageMetadataProvider.future);
  final books = await ref.watch(homepageBooksProvider.future);
  final refreshedCompiled = _readCompiledHomepageCache(
    ref.read(sharedPreferencesProvider),
  );
  if (refreshedCompiled != null &&
      refreshedCompiled.shelves.popular.isNotEmpty) {
    return refreshedCompiled.shelves.popular;
  }
  final originals = await ref.watch(homepageOriginalsProvider.future);
  final trending = await ref.watch(homepageTrendingWorksProvider.future);
  final excluded = {
    ...originals.take(10).map((book) => book.id),
    ...trending.take(10).map((book) => book.id),
  };
  final sorted = List<Book>.from(books)
    ..sort(
      (a, b) => _bookPopularityScore(
        b,
        metadata.recommendationStats,
      ).compareTo(_bookPopularityScore(a, metadata.recommendationStats)),
    );
  return _withoutIds(sorted, excluded, limit: 24);
});

final homepageRecentProvider = FutureProvider<List<Book>>((ref) async {
  final cachedCompiled = _readCompiledHomepageCache(
    ref.watch(sharedPreferencesProvider),
  );
  if (cachedCompiled != null && cachedCompiled.shelves.recent.isNotEmpty) {
    return cachedCompiled.shelves.recent;
  }

  final books = await ref.watch(homepageBooksProvider.future);
  final refreshedCompiled = _readCompiledHomepageCache(
    ref.read(sharedPreferencesProvider),
  );
  if (refreshedCompiled != null &&
      refreshedCompiled.shelves.recent.isNotEmpty) {
    return refreshedCompiled.shelves.recent;
  }
  final originals = await ref.watch(homepageOriginalsProvider.future);
  final trending = await ref.watch(homepageTrendingWorksProvider.future);
  final excluded = {
    ...originals.take(8).map((book) => book.id),
    ...trending.take(8).map((book) => book.id),
  };
  final sorted = List<Book>.from(books)
    ..sort((a, b) {
      final tA = a.createdAt ?? 0;
      final tB = b.createdAt ?? 0;
      return tB.compareTo(tA);
    });
  return _withoutIds(sorted, excluded, limit: 24);
});

final homepageGenreProvider = FutureProvider.family<List<Book>, String>((
  ref,
  genre,
) async {
  final refreshTick = ref.watch(homepageRefreshCounterProvider);
  final repo = ref.watch(bookRepositoryProvider);
  final normalized = genre.trim();
  if (normalized.isEmpty) return <Book>[];
  final cacheKey =
      '$_homepageGenreBooksCacheKeyPrefix${normalized.toLowerCase()}';
  final prefs = ref.watch(sharedPreferencesProvider);
  final cachedCompiled = _readCompiledHomepageCache(prefs);
  final compiledBooks = cachedCompiled?.shelves.genreBooks(normalized);
  if (compiledBooks != null && compiledBooks.isNotEmpty) {
    return compiledBooks;
  }
  final cached = _readCachedValue<List<Book>>(
    prefs,
    cacheKey,
    (json) =>
        (json as List).map((raw) => Book.fromJson(asStringMap(raw))).toList(),
  );
  if (cached != null && cached.isNotEmpty) {
    if (refreshTick > 0 || _isCacheStale(prefs)) {
      _queueHomepageBackgroundRefresh(ref);
    }
    return cached;
  }

  final compiled = await ref.watch(compiledHomepageProvider.future);
  final freshCompiledBooks = compiled?.shelves.genreBooks(normalized);
  if (freshCompiledBooks != null && freshCompiledBooks.isNotEmpty) {
    return freshCompiledBooks;
  }

  final metadata = await ref.watch(homepageMetadataProvider.future);
  final recommendedBookIds = _positiveRecommendationIds(
    metadata,
    limit: 120,
  ).toSet();

  final books = await ref.watch(homepageBooksProvider.future);
  final localMatches = books.where((book) {
    final categories = [...book.subjects, ...?book.topics, ...book.bookshelves];
    return categories.any(
      (category) => category.toLowerCase().contains(normalized.toLowerCase()),
    );
  }).toList();

  final remoteMatches = await Future.wait([
    _safeBookList(
      'homepage genre books: $normalized',
      repo.getBooksByGenre(normalized, limit: 36),
    ),
    _safeBookList(
      'homepage topic originals: $normalized',
      repo.getOriginalBooksByTopic(normalized, limit: 24),
    ),
  ]);

  final combined = _uniqueBooks(
    _homepageAllowedBooks([
      ...localMatches,
      ...remoteMatches.expand((books) => books),
    ], recommendedBookIds),
  );
  combined.sort(
    (a, b) => _bookPopularityScore(
      b,
      metadata.recommendationStats,
    ).compareTo(_bookPopularityScore(a, metadata.recommendationStats)),
  );
  final result = combined.take(36).toList();
  if (result.isNotEmpty) {
    await _writeCachedValue(
      prefs,
      cacheKey,
      result.map((book) => book.toJson()).toList(),
    );
  }
  return result;
});
