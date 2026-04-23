import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../../data/utils/firestore_utils.dart';
import '../../utils/map_utils.dart';
import 'book_providers.dart';

import 'dart:math' as math;

final homepageMetadataProvider = FutureProvider<HomepageMetadata>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('settings')
      .doc('homepage_metadata')
      .get();

  final data = asStringMap(doc.data());
  final authors = data['authors'];
  if (authors is List) {
    data['authors'] = authors.whereType<Map>().map((raw) {
      final userMap = asStringMap(raw);
      final id = userMap['id']?.toString() ?? '';
      return normalizeUserMapForModel(userMap, id);
    }).toList();
  }

  return HomepageMetadata.fromJson(data);
});

List<String> _positiveRecommendationIds(
  HomepageMetadata metadata, {
  int limit = 60,
}) {
  final entries = metadata.recommendationStats.entries.toList()
    ..sort((a, b) {
      final aScore = a.value.recommendationCount != 0
          ? a.value.recommendationCount
          : a.value.upvotes - a.value.downvotes;
      final bScore = b.value.recommendationCount != 0
          ? b.value.recommendationCount
          : b.value.upvotes - b.value.downvotes;
      return bScore.compareTo(aScore);
    });

  return entries
      .where((entry) {
        final stats = entry.value;
        return stats.recommendationCount > 0 || stats.upvotes > stats.downvotes;
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

final homepageBooksProvider = FutureProvider<List<Book>>((ref) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  final statsData = metadata.recommendationStats;
  final repo = ref.watch(bookRepositoryProvider);
  final communityIds = _positiveRecommendationIds(metadata, limit: 60);

  final results = await Future.wait([
    repo.getOriginalBooks(limit: 60),
    if (communityIds.isNotEmpty)
      repo.getBooksByIds(communityIds)
    else
      Future.value(<Book>[]),
  ]);
  final downloaded = ref.watch(offlineServiceProvider).getDownloadedBooks();

  final Map<String, Book> uniqueBooks = {};

  void addBooks(List<Book> books) {
    for (final book in books) {
      uniqueBooks[book.id] = book;
    }
  }

  addBooks(results[0]);
  addBooks(results[1]);
  addBooks(downloaded);

  final combinedBooks = uniqueBooks.values.toList();

  combinedBooks.sort((a, b) {
    double getScore(Book book) {
      final avgRating = book.averageRating ?? 0.0;
      final ratingsCount = book.ratingsCount ?? 0;
      final stats = statsData[book.id];

      final popularityScore =
          avgRating * math.log(ratingsCount + 1) / math.ln10 +
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
    return scoreB.compareTo(scoreA); // Descending
  });

  return combinedBooks;
});

final homepageAuthorsProvider = FutureProvider((ref) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  return metadata.authors;
});

enum HomeAuthorRanking { topRated, mostRead, mostPublished }

class RankedHomeAuthor {
  const RankedHomeAuthor({required this.author, required this.metricLabel});

  final UserModel author;
  final String metricLabel;
}

final homepageRankedAuthorsProvider =
    FutureProvider.family<List<RankedHomeAuthor>, HomeAuthorRanking>((
      ref,
      ranking,
    ) async {
      final metadata = await ref.watch(homepageMetadataProvider.future);
      final books = await ref.watch(homepageBooksProvider.future);
      final stats = <String, _AuthorStats>{};

      for (final book in books.where(_isPublishedOriginal)) {
        final authorId = book.authorId?.trim();
        if (authorId == null || authorId.isEmpty) continue;
        final authorStats = stats.putIfAbsent(authorId, _AuthorStats.new);
        authorStats.published += 1;
        authorStats.reads += book.viewCount ?? 0;
        final rating = book.averageRating ?? 0;
        final ratingsCount = book.ratingsCount ?? 0;
        if (rating > 0 && ratingsCount > 0) {
          authorStats.ratingWeight += ratingsCount;
          authorStats.ratingTotal += rating * ratingsCount;
        }
      }

      final authors = metadata.authors.where((author) {
        return stats.containsKey(author.id);
      }).toList();

      double score(UserModel author) {
        final authorStats = stats[author.id] ?? _AuthorStats();
        return switch (ranking) {
          HomeAuthorRanking.topRated => authorStats.weightedRatingScore,
          HomeAuthorRanking.mostRead => authorStats.reads.toDouble(),
          HomeAuthorRanking.mostPublished => authorStats.published.toDouble(),
        };
      }

      String metric(UserModel author) {
        final authorStats = stats[author.id] ?? _AuthorStats();
        return switch (ranking) {
          HomeAuthorRanking.topRated =>
            authorStats.ratingWeight == 0
                ? 'No ratings yet'
                : '${authorStats.averageRating.toStringAsFixed(1)} rating',
          HomeAuthorRanking.mostRead =>
            '${_compactCount(authorStats.reads)} reads',
          HomeAuthorRanking.mostPublished =>
            '${authorStats.published} ${authorStats.published == 1 ? 'work' : 'works'}',
        };
      }

      authors.sort((a, b) {
        final scoreCompare = score(b).compareTo(score(a));
        if (scoreCompare != 0) return scoreCompare;
        final followersA = a.followersCount ?? 0;
        final followersB = b.followersCount ?? 0;
        return followersB.compareTo(followersA);
      });

      return authors
          .take(20)
          .map(
            (author) =>
                RankedHomeAuthor(author: author, metricLabel: metric(author)),
          )
          .toList();
    });

final homepageTrendingWorksProvider = FutureProvider<List<Book>>((ref) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  final books = await ref.watch(homepageBooksProvider.future);
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

  final sorted = books.where(_isPublishedOriginal).toList()
    ..sort((a, b) => score(b).compareTo(score(a)));
  return sorted.take(20).toList();
});

bool _isPublishedOriginal(Book book) {
  if (book.isOriginal != true) return false;
  final status = book.status?.trim().toLowerCase();
  return status == null || status.isEmpty || status == 'published';
}

String _compactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

class _AuthorStats {
  int published = 0;
  int reads = 0;
  double ratingTotal = 0;
  int ratingWeight = 0;

  double get averageRating =>
      ratingWeight == 0 ? 0 : ratingTotal / ratingWeight;

  double get weightedRatingScore {
    if (ratingWeight == 0) return 0;
    return averageRating * math.log(ratingWeight + 1) / math.ln10;
  }
}

final homepageDownloadedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final service = ref.watch(offlineServiceProvider);
  await service.init();
  return service.getDownloadedBooks();
});

final homepageIABooksProvider = FutureProvider<List<Book>>((ref) async {
  final metadata = await ref.watch(homepageMetadataProvider.future);
  final repo = ref.watch(bookRepositoryProvider);
  final ids = _positiveRecommendationIds(metadata, limit: 80);

  var books = <Book>[];
  if (ids.isNotEmpty) {
    books = (await repo.getBooksByIds(ids)).where(_isArchiveBook).toList();
  }
  if (books.isEmpty) {
    books = await repo.getUpvotedIABooks(limit: 20);
  }
  return books.take(20).toList();
});

// Category Providers powered by the Homepage combined list
final homepageOriginalsProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.where((b) => b.isOriginal ?? false).toList();
});

final homepagePopularProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.take(20).toList();
});

final homepageRecentProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  final sorted = List<Book>.from(books)
    ..sort((a, b) {
      final tA = a.createdAt ?? 0;
      final tB = b.createdAt ?? 0;
      return tB.compareTo(tA);
    });
  return sorted.take(20).toList();
});

final homepageGenreProvider = FutureProvider.family<List<Book>, String>((
  ref,
  genre,
) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.where((book) {
    final categories = book.topics ?? book.subjects;
    if (categories.isEmpty) return false;
    return categories.any((c) => c.toLowerCase() == genre.toLowerCase());
  }).toList();
});
