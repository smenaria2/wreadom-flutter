import '../../../data/utils/firestore_utils.dart';
import '../../../utils/map_utils.dart';
import '../book.dart';
import '../feed_post.dart';
import '../home_banner.dart';
import 'homepage_metadata.dart';

class CompiledHomepage {
  const CompiledHomepage({
    required this.schemaVersion,
    required this.generatedAt,
    required this.ttlSeconds,
    required this.metadata,
    required this.shelves,
  });

  final int schemaVersion;
  final int generatedAt;
  final int ttlSeconds;
  final CompiledHomepageMetadata metadata;
  final CompiledHomepageShelves shelves;

  factory CompiledHomepage.fromJson(Map<String, dynamic> json) {
    return CompiledHomepage(
      schemaVersion: _intValue(json['schemaVersion']),
      generatedAt: _intValue(json['generatedAt']),
      ttlSeconds: _intValue(json['ttlSeconds'], fallback: 3600),
      metadata: CompiledHomepageMetadata.fromJson(
        asStringMap(json['metadata']),
      ),
      shelves: CompiledHomepageShelves.fromJson(asStringMap(json['shelves'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt,
    'ttlSeconds': ttlSeconds,
    'metadata': metadata.toJson(),
    'shelves': shelves.toJson(),
  };

  bool get hasPublicContent =>
      metadata.hasContent ||
      shelves.allBooks.isNotEmpty ||
      shelves.originals.isNotEmpty ||
      shelves.audioPosts.isNotEmpty ||
      shelves.genres.values.any((books) => books.isNotEmpty);
}

class CompiledHomepageMetadata {
  const CompiledHomepageMetadata({
    required this.value,
    required this.homeBanners,
  });

  final HomepageMetadata value;
  final List<HomeBanner> homeBanners;

  factory CompiledHomepageMetadata.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    final authors = data['authors'];
    if (authors is List) {
      data['authors'] = authors.whereType<Map>().map((raw) {
        final userMap = asStringMap(raw);
        final id = userMap['id']?.toString() ?? '';
        return normalizeUserMapForModel(userMap, id);
      }).toList();
    }

    return CompiledHomepageMetadata(
      value: HomepageMetadata.fromJson(data),
      homeBanners: _bannerList(data['homeBanners']),
    );
  }

  Map<String, dynamic> toJson() => {
    ...value.toJson(),
    'homeBanners': homeBanners.map((banner) => banner.toJson()).toList(),
  };

  bool get hasContent =>
      value.authors.isNotEmpty ||
      value.recommendationStats.isNotEmpty ||
      value.dailyTopics.isNotEmpty ||
      homeBanners.isNotEmpty;
}

class CompiledHomepageShelves {
  const CompiledHomepageShelves({
    required this.allBooks,
    required this.authorWorks,
    required this.originals,
    required this.trending,
    required this.popular,
    required this.recent,
    required this.communityClassics,
    required this.series,
    required this.audioPosts,
    required this.genres,
  });

  final List<Book> allBooks;
  final List<Book> authorWorks;
  final List<Book> originals;
  final List<Book> trending;
  final List<Book> popular;
  final List<Book> recent;
  final List<Book> communityClassics;
  final List<Book> series;
  final List<FeedPost> audioPosts;
  final Map<String, List<Book>> genres;

  factory CompiledHomepageShelves.fromJson(Map<String, dynamic> json) {
    final rawGenres = asStringMap(json['genres']);
    return CompiledHomepageShelves(
      allBooks: _bookList(json['allBooks']),
      authorWorks: _bookList(json['authorWorks']),
      originals: _bookList(json['originals']),
      trending: _bookList(json['trending']),
      popular: _bookList(json['popular']),
      recent: _bookList(json['recent']),
      communityClassics: _bookList(json['communityClassics']),
      series: _bookList(json['series']),
      audioPosts: _feedPostList(json['audioPosts']),
      genres: {
        for (final entry in rawGenres.entries)
          entry.key: _bookList(entry.value),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'allBooks': allBooks.map((book) => book.toJson()).toList(),
    'authorWorks': authorWorks.map((book) => book.toJson()).toList(),
    'originals': originals.map((book) => book.toJson()).toList(),
    'trending': trending.map((book) => book.toJson()).toList(),
    'popular': popular.map((book) => book.toJson()).toList(),
    'recent': recent.map((book) => book.toJson()).toList(),
    'communityClassics': communityClassics
        .map((book) => book.toJson())
        .toList(),
    'series': series.map((book) => book.toJson()).toList(),
    'audioPosts': audioPosts.map((post) => post.toJson()).toList(),
    'genres': {
      for (final entry in genres.entries)
        entry.key: entry.value.map((book) => book.toJson()).toList(),
    },
  };

  List<Book> genreBooks(String genre) {
    final normalized = genre.trim();
    if (normalized.isEmpty) return const <Book>[];
    return genres[normalized] ??
        genres[normalized.toLowerCase()] ??
        const <Book>[];
  }
}

List<Book> _bookList(dynamic raw) {
  if (raw is! List) return const <Book>[];
  return raw
      .whereType<Map>()
      .map((item) {
        final data = normalizeBookMapForModel(
          asStringMap(item),
          asStringMap(item)['id']?.toString() ?? '',
        );
        return Book.fromJson(data);
      })
      .toList(growable: false);
}

List<FeedPost> _feedPostList(dynamic raw) {
  if (raw is! List) return const <FeedPost>[];
  return raw
      .whereType<Map>()
      .map((item) {
        final map = asStringMap(item);
        final data = mapFirestoreData(map, map['id']?.toString() ?? '');
        return FeedPost.fromJson(data);
      })
      .toList(growable: false);
}

List<HomeBanner> _bannerList(dynamic raw) {
  if (raw is! List) return const <HomeBanner>[];
  return raw
      .whereType<Map>()
      .map((item) => HomeBanner.fromJson(asStringMap(item)))
      .where((banner) => banner.id.isNotEmpty)
      .toList(growable: false);
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
