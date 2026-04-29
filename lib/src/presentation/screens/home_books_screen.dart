import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../../domain/models/user_model.dart';
import '../providers/notification_providers.dart';
import '../providers/homepage_providers.dart';
import '../../domain/models/book.dart';
import 'book_detail_screen.dart';
import 'category_books_screen.dart';
import 'daily_topic_screen.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/daily_topic_providers.dart';
import '../components/generated_book_cover.dart';

enum _HomeShelfDestination {
  communityClassics,
  originals,
  trending,
  popular,
  recent;

  String getLocalizedCategory(AppLocalizations l10n) {
    switch (this) {
      case _HomeShelfDestination.communityClassics:
        return l10n.shelfCommunityClassics;
      case _HomeShelfDestination.originals:
        return l10n.shelfOriginals;
      case _HomeShelfDestination.trending:
        return l10n.shelfTrending;
      case _HomeShelfDestination.popular:
        return l10n.shelfPopular;
      case _HomeShelfDestination.recent:
        return l10n.shelfRecentlyAdded;
    }
  }

  @Deprecated('Use getLocalizedCategory instead')
  String getCategory(AppLocalizations l10n) => getLocalizedCategory(l10n);

  String get sectionId {
    switch (this) {
      case _HomeShelfDestination.communityClassics:
        return 'community-classics';
      case _HomeShelfDestination.originals:
        return 'wreadom-originals';
      case _HomeShelfDestination.trending:
        return 'trending-works';
      case _HomeShelfDestination.popular:
        return 'popular-now';
      case _HomeShelfDestination.recent:
        return 'recently-added';
    }
  }
}

String? _initialForName(String value) {
  final trimmed = value.trim();
  if (trimmed.characters.isEmpty) return null;
  return trimmed.characters.first.toUpperCase();
}

void _openShelfDestination(
  BuildContext context,
  _HomeShelfDestination destination,
  AppLocalizations l10n,
) {
  Navigator.of(context).pushNamed(
    AppRoutes.category,
    arguments: CategoryBooksArguments(
      category: destination.sectionId,
      displayName: destination.getLocalizedCategory(l10n),
    ),
  );
}

void _openCategory(
  BuildContext context,
  String sectionId,
  String localizedName,
) {
  Navigator.of(context).pushNamed(
    AppRoutes.category,
    arguments: CategoryBooksArguments(
      category: sectionId,
      displayName: localizedName,
    ),
  );
}

class HomeBooksScreen extends ConsumerWidget {
  const HomeBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originalsAsync = ref.watch(homepageOriginalsProvider);
    final popularAsync = ref.watch(homepagePopularProvider);
    final trendingAsync = ref.watch(homepageTrendingWorksProvider);
    final recentAsync = ref.watch(homepageRecentProvider);
    final iaAsync = ref.watch(homepageIABooksProvider);
    final mysteryAsync = ref.watch(homepageGenreProvider('mystery'));
    final poetryAsync = ref.watch(homepageGenreProvider('poetry'));
    final classicsAsync = ref.watch(homepageGenreProvider('classic'));
    final romanceAsync = ref.watch(homepageGenreProvider('romance'));
    final socialAsync = ref.watch(homepageGenreProvider('social'));
    final historyAsync = ref.watch(homepageGenreProvider('history'));
    final storiesAsync = ref.watch(homepageGenreProvider('stories'));
    final competitionAsync = ref.watch(
      homepageGenreProvider('Wreadom Competition #1'),
    );
    final otherAsync = ref.watch(homepageGenreProvider('other'));

    // Watch saved books for the new section

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          Builder(
            builder: (context) {
              final unread = ref.watch(unreadNotificationCountProvider);
              final btn = IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: l10n.notifications,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              );
              if (unread <= 0) return btn;
              return Badge(
                label: Text(unread > 99 ? '99+' : '$unread'),
                child: btn,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: l10n.searchBooks,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.discovery),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshHomepage(ref);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuthorSpotlight(),
              const SizedBox(height: 16),

              const _HeroBanner(),
              const SizedBox(height: 28),

              const _ContinueReadingSection(),
              const SizedBox(height: 28),

              // ─── Saved Books (Local & Remote) ─────────────────────────
              const _SavedBooksSection(),
              const SizedBox(height: 28),

              // ─── Wreadom Originals ────────────────────────────────────
              _BookshelfSection(
                title: _HomeShelfDestination.originals.getLocalizedCategory(
                  l10n,
                ),
                booksAsync: originalsAsync,
                sectionId: _HomeShelfDestination.originals.sectionId,
                onRetry: () => refreshHomepage(ref),
                onSeeAll: () => _openShelfDestination(
                  context,
                  _HomeShelfDestination.originals,
                  l10n,
                ),
              ),
              const SizedBox(height: 28),

              _BookshelfSection(
                title: _HomeShelfDestination.trending.getLocalizedCategory(
                  l10n,
                ),
                booksAsync: trendingAsync,
                sectionId: _HomeShelfDestination.trending.sectionId,
                onRetry: () => refreshHomepage(ref),
                onSeeAll: () => _openShelfDestination(
                  context,
                  _HomeShelfDestination.trending,
                  l10n,
                ),
              ),
              const SizedBox(height: 28),

              // ─── Popular Books ────────────────────────────────────────
              _BookshelfSection(
                title: _HomeShelfDestination.popular.getLocalizedCategory(l10n),
                booksAsync: popularAsync,
                sectionId: _HomeShelfDestination.popular.sectionId,
                onRetry: () => refreshHomepage(ref),
                onSeeAll: () => _openShelfDestination(
                  context,
                  _HomeShelfDestination.popular,
                  l10n,
                ),
              ),
              const SizedBox(height: 28),

              // ─── Recently Added ───────────────────────────────────────
              _BookshelfSection(
                title: _HomeShelfDestination.recent.getLocalizedCategory(l10n),
                booksAsync: recentAsync,
                sectionId: _HomeShelfDestination.recent.sectionId,
                onRetry: () => refreshHomepage(ref),
                onSeeAll: () => _openShelfDestination(
                  context,
                  _HomeShelfDestination.recent,
                  l10n,
                ),
              ),
              const SizedBox(height: 28),

              // ─── Genre Sections (Filtered) ─────────────────────────────
              _GenreSection(
                title: l10n.genreMystery,
                booksAsync: mysteryAsync,
                genre: 'Mystery',
                sectionId: 'mystery',
              ),
              const _AuthorsSection(),
              const SizedBox(height: 28),
              _GenreSection(
                title: l10n.genrePoetry,
                booksAsync: poetryAsync,
                genre: 'Poetry',
                sectionId: 'poetry',
              ),
              _GenreSection(
                title: 'Classic',
                booksAsync: classicsAsync,
                genre: 'Classic',
                sectionId: 'classic',
              ),
              _GenreSection(
                title: l10n.genreRomance,
                booksAsync: romanceAsync,
                genre: 'Romance',
                sectionId: 'romance',
              ),
              _GenreSection(
                title: 'Social',
                booksAsync: socialAsync,
                genre: 'Social',
                sectionId: 'social',
              ),
              _GenreSection(
                title: 'History',
                booksAsync: historyAsync,
                genre: 'History',
                sectionId: 'history',
              ),
              _GenreSection(
                title: 'Stories',
                booksAsync: storiesAsync,
                genre: 'Stories',
                sectionId: 'stories',
              ),
              _GenreSection(
                title: 'Wreadom Competition #1',
                booksAsync: competitionAsync,
                genre: 'Wreadom Competition #1',
                sectionId: 'wreadom-competition-1',
              ),
              _GenreSection(
                title: 'Other',
                booksAsync: otherAsync,
                genre: 'Other',
                sectionId: 'other',
              ),
              _BookshelfSection(
                title: _HomeShelfDestination.communityClassics
                    .getLocalizedCategory(l10n),
                booksAsync: iaAsync,
                sectionId: _HomeShelfDestination.communityClassics.sectionId,
                onRetry: () => refreshHomepage(ref),
                onSeeAll: () => _openShelfDestination(
                  context,
                  _HomeShelfDestination.communityClassics,
                  l10n,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────
class _HeroBanner extends ConsumerStatefulWidget {
  const _HeroBanner();

  @override
  ConsumerState<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<_HeroBanner> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(dailyTopicsProvider);

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty) return _buildDefaultBanner(context);

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final height = (constraints.maxWidth * 0.62).clamp(
                  210.0,
                  280.0,
                );
                return SizedBox(
                  height: height,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: topics.length,
                    onPageChanged: (index) {
                      if (index >= topics.length - 1) {
                        ref.read(dailyTopicsProvider.notifier).fetchMore();
                      }
                    },
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _DailyTopicCard(topic: topic);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final page = _pageController.hasClients
                    ? _pageController.page ?? _pageController.initialPage
                    : _pageController.initialPage.toDouble();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    topics.length,
                    (index) => _buildIndicator(index, page.toDouble()),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => LayoutBuilder(
        builder: (context, constraints) {
          final height = (constraints.maxWidth * 0.46).clamp(160.0, 220.0);
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
      error: (_, _) => _buildDefaultBanner(context),
    );
  }

  Widget _buildIndicator(int index, double page) {
    final distance = (page - index).abs().clamp(0.0, 1.0);
    final strength = 1.0 - distance;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: 6 + (14 * strength),
      decoration: BoxDecoration(
        color: Color.lerp(
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          Theme.of(context).colorScheme.primary,
          strength,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildDefaultBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: (MediaQuery.sizeOf(context).width * 0.42).clamp(
          172.0,
          230.0,
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.keepReading,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.heroBannerSubtitle,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.discovery),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.exploreNow,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTopicCard extends StatelessWidget {
  final DailyTopic topic;

  const _DailyTopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        image: DecorationImage(
          image: CachedNetworkImageProvider(topic.coverImageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.2),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.dailyTopic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              topic.topicName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              topic.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.dailyTopic,
                  arguments: DailyTopicArguments(
                    topicId: topic.id,
                    topic: topic,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                l10n.readMore,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreSection extends ConsumerWidget {
  final String title;
  final AsyncValue<List<Book>> booksAsync;
  final String genre;
  final String sectionId;
  const _GenreSection({
    required this.title,
    required this.booksAsync,
    required this.genre,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _BookshelfSection(
              title: title,
              booksAsync: booksAsync,
              sectionId: sectionId,
              onRetry: () => refreshHomepage(ref),
              onSeeAll: () => _openCategory(context, sectionId, title),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
      loading: () => Column(
        children: [
          _BookshelfSection(
            title: title,
            booksAsync: booksAsync,
            sectionId: sectionId,
          ),
          const SizedBox(height: 28),
        ],
      ),
      error: (_, _) =>
          _SectionError(title: title, onRetry: () => refreshHomepage(ref)),
    );
  }
}

// ─── Saved Books Section (Top Shelf) ──────────────────────────────────────────
class _ContinueReadingSection extends ConsumerWidget {
  const _ContinueReadingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(readingHistoryBooksProvider);
    final user = ref.watch(currentUserProvider).asData?.value;

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();
        final visibleBooks = books.take(12).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.continueReading,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: visibleBooks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final book = visibleBooks[index];
                  final progress = _progressFor(user, book.id);
                  return _ContinueReadingCard(
                    book: book,
                    chapterIndex: progress.chapterIndex,
                    position: progress.position,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _SectionError(
        title: l10n.continueReading,
        onRetry: () => ref.invalidate(readingHistoryBooksProvider),
      ),
    );
  }

  _ReadingProgress _progressFor(UserModel? user, String bookId) {
    final raw = user?.readingProgress?[bookId];
    if (raw is! Map) return const _ReadingProgress();
    final progress = Map<String, dynamic>.from(raw);
    return _ReadingProgress(
      chapterIndex: (progress['chapterIndex'] as num?)?.toInt() ?? 0,
      position: ((progress['position'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }
}

class _ReadingProgress {
  const _ReadingProgress({this.chapterIndex = 0, this.position = 0});

  final int chapterIndex;
  final double position;
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.book,
    required this.chapterIndex,
    required this.position,
  });

  final Book book;
  final int chapterIndex;
  final double position;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authors = book.authors
        .map((author) => author.name)
        .where((name) => name.isNotEmpty)
        .join(', ');
    final percent = (position * 100).round().clamp(0, 100);

    return SizedBox(
      width: 260,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.reader,
          arguments: ReaderArguments(
            book: book,
            initialChapterIndex: chapterIndex,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 82,
                height: 124,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              _CoverPlaceholder(book: book),
                        )
                      : _CoverPlaceholder(book: book),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authors.isEmpty ? l10n.unknownAuthor : authors,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.chapterNumber(chapterIndex + 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: position,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      percent > 0
                          ? l10n.percentComplete(percent)
                          : l10n.readyToResume,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedBooksSection extends ConsumerWidget {
  const _SavedBooksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remoteSavedAsync = ref.watch(homepageDownloadedBooksProvider);

    return remoteSavedAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();

        return _BookshelfSection(
          title: l10n.yourShelf,
          booksAsync: remoteSavedAsync,
          sectionId: 'saved',
          onRetry: () => ref.invalidate(homepageDownloadedBooksProvider),
          onSeeAll: () {
            Navigator.of(context).pushNamed(AppRoutes.savedBooks);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _SectionError(
        title: l10n.yourShelf,
        onRetry: () => ref.invalidate(homepageDownloadedBooksProvider),
      ),
    );
  }
}

// ─── Bookshelf Row ────────────────────────────────────────────────────────────
class _AuthorsSection extends ConsumerStatefulWidget {
  const _AuthorsSection();

  @override
  ConsumerState<_AuthorsSection> createState() => _AuthorsSectionState();
}

class _AuthorsSectionState extends ConsumerState<_AuthorsSection> {
  HomeAuthorRanking _ranking = HomeAuthorRanking.topRated;

  String _rankingLabel(HomeAuthorRanking ranking, AppLocalizations l10n) {
    return switch (ranking) {
      HomeAuthorRanking.topRated => l10n.topRatedAuthors,
      HomeAuthorRanking.mostRead => l10n.mostReadAuthors,
      HomeAuthorRanking.mostPublished => l10n.mostPublishedAuthors,
    };
  }

  String _compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  String _metricLabel(RankedHomeAuthor ranked, AppLocalizations l10n) {
    final metrics = ranked.metrics;
    return switch (_ranking) {
      HomeAuthorRanking.topRated =>
        metrics.ratingWeight == 0
            ? l10n.noRatingsYet
            : l10n.ratingMetric(metrics.averageRating.toStringAsFixed(1)),
      HomeAuthorRanking.mostRead => l10n.readsMetric(
        _compactCount(metrics.reads),
      ),
      HomeAuthorRanking.mostPublished => l10n.worksMetric(metrics.works),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authorsAsync = ref.watch(homepageRankedAuthorsProvider(_ranking));
    return authorsAsync.when(
      data: (rankedAuthors) {
        if (rankedAuthors.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.authorsToFollow,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<HomeAuthorRanking>(
                    tooltip: _rankingLabel(_ranking, l10n),
                    initialValue: _ranking,
                    onSelected: (value) => setState(() => _ranking = value),
                    itemBuilder: (context) => HomeAuthorRanking.values
                        .map(
                          (ranking) => PopupMenuItem(
                            value: ranking,
                            child: Text(_rankingLabel(ranking, l10n)),
                          ),
                        )
                        .toList(),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 156),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _rankingLabel(_ranking, l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 146,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: rankedAuthors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final ranked = rankedAuthors[index];
                  final author = ranked.author;
                  final displayName = author.displayName;
                  final penName = author.penName;
                  final name = (displayName != null && displayName.isNotEmpty)
                      ? displayName
                      : (penName != null && penName.isNotEmpty)
                      ? penName
                      : author.username;
                  final initial = _initialForName(name);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.publicProfile,
                      arguments: PublicProfileArguments(userId: author.id),
                    ),
                    child: SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                author.photoURL != null &&
                                    author.photoURL!.isNotEmpty
                                ? CachedNetworkImageProvider(author.photoURL!)
                                : null,
                            child:
                                (author.photoURL == null ||
                                    author.photoURL!.isEmpty)
                                ? initial != null
                                      ? Text(initial)
                                      : const Icon(Icons.person_rounded)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _metricLabel(ranked, l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _SectionError(
        title: l10n.authorsToFollow,
        onRetry: () => refreshHomepage(ref),
      ),
    );
  }
}

class _BookshelfSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<Book>> booksAsync;
  final String? sectionId;
  final VoidCallback? onSeeAll;
  final VoidCallback? onRetry;

  const _BookshelfSection({
    required this.title,
    required this.booksAsync,
    this.sectionId,
    this.onSeeAll,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final shelfHeight = (MediaQuery.sizeOf(context).width * 0.54).clamp(
      190.0,
      232.0,
    );
    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text(AppLocalizations.of(context)!.seeAll),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: shelfHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final book = books[index];
                  final shelfId =
                      sectionId ?? title.replaceAll(' ', '-').toLowerCase();
                  return _BookCard(
                    book: book,
                    heroTag: 'book-cover-$shelfId-${book.id}',
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 24,
              width: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: shelfHeight,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, _) => const _BookCardSkeleton(),
            ),
          ),
        ],
      ),
      error: (_, _) => _SectionError(title: title, onRetry: onRetry),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.title, this.onRetry});

  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.couldNotLoad(title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Book book;
  final String heroTag;
  const _BookCard({required this.book, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.bookByAuthor(
        book.title,
        book.authors.isNotEmpty ? book.authors.first.name : l10n.unknownAuthor,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(
                bookId: book.id,
                preloadedBook: book,
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.coverUrl != null
                      ? Hero(
                          tag: heroTag,
                          child: CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _CoverPlaceholder(book: book),
                          ),
                        )
                      : _CoverPlaceholder(book: book),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              // Author
              Text(
                book.authors.isNotEmpty
                    ? book.authors.first.name
                    : AppLocalizations.of(context)!.unknownAuthor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final Book book;
  const _CoverPlaceholder({required this.book});

  @override
  Widget build(BuildContext context) {
    return GeneratedBookCover(
      width: double.infinity,
      height: double.infinity,
      title: book.title,
      author: book.authors.isNotEmpty ? book.authors.first.name : null,
      seed: book.id,
      borderRadius: 12,
      compact: true,
    );
  }
}

// ─── Skeleton placeholder ─────────────────────────────────────────────────────
class _BookCardSkeleton extends StatelessWidget {
  const _BookCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 100,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 70,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }
}

// ─── Author Spotlight ────────────────────────────────────────────────────────
class _AuthorSpotlight extends ConsumerStatefulWidget {
  const _AuthorSpotlight();

  @override
  ConsumerState<_AuthorSpotlight> createState() => _AuthorSpotlightState();
}

class _AuthorSpotlightState extends ConsumerState<_AuthorSpotlight> {
  int? _randomIndex;

  String _authorName(UserModel author) {
    final displayName = author.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final penName = author.penName;
    if (penName != null && penName.trim().isNotEmpty) {
      return penName.trim();
    }

    return author.username;
  }

  void _openAuthorProfile(BuildContext context, UserModel author) {
    Navigator.of(context).pushNamed(
      AppRoutes.publicProfile,
      arguments: PublicProfileArguments(userId: author.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authorsAsync = ref.watch(
      homepageRankedAuthorsProvider(HomeAuthorRanking.topRated),
    );

    return authorsAsync.when(
      data: (rankedAuthors) {
        final eligibleAuthors = rankedAuthors
            .where((ranked) => ranked.metrics.works > 0)
            .map((ranked) => ranked.author)
            .toList();

        if (eligibleAuthors.isEmpty) return const SizedBox.shrink();

        _randomIndex ??= math.Random().nextInt(eligibleAuthors.length);
        if (_randomIndex! >= eligibleAuthors.length) _randomIndex = 0;
        final author = eligibleAuthors[_randomIndex!];
        final authorBooksAsync = ref.watch(
          homepageAuthorBooksProvider(author.id),
        );
        final authorName = _authorName(author);
        final authorInitial = _initialForName(authorName);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A0A0F),
                const Color(0xFF16131D),
                const Color(0xFF241D16),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.star_rounded,
                  size: 120,
                  color: const Color(0xFFFFD166).withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _openAuthorProfile(context, author),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD166),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD166,
                                  ).withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF2D2A35),
                              backgroundImage:
                                  author.photoURL != null &&
                                      author.photoURL!.isNotEmpty
                                  ? CachedNetworkImageProvider(author.photoURL!)
                                  : null,
                              child:
                                  (author.photoURL == null ||
                                      author.photoURL!.isEmpty)
                                  ? authorInitial != null
                                        ? Text(
                                            authorInitial,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFFD166),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            color: Color(0xFFFFD166),
                                          )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () =>
                                    _openAuthorProfile(context, author),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD166),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                author.bio ?? l10n.featuredWreadomAuthor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    authorBooksAsync.when(
                      data: (books) {
                        if (books.isEmpty) return const SizedBox.shrink();
                        // Only show first 5 books
                        final displayBooks = books.take(5).toList();
                        return SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayBooks.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final book = displayBooks[index];
                              return GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BookDetailScreen(
                                      bookId: book.id,
                                      preloadedBook: book,
                                    ),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 76,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.28,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child:
                                              book.coverUrl != null &&
                                                  book.coverUrl!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: book.coverUrl!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorWidget: (_, _, _) =>
                                                      _CoverPlaceholder(
                                                        book: book,
                                                      ),
                                                )
                                              : _CoverPlaceholder(book: book),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          height: 1.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      error: (_, _) => _SectionError(
                        title: l10n.authorBooks(authorName),
                        onRetry: () => ref.invalidate(
                          homepageAuthorBooksProvider(author.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _SectionError(
        title: l10n.authorSpotlight,
        onRetry: () => ref.invalidate(
          homepageRankedAuthorsProvider(HomeAuthorRanking.topRated),
        ),
      ),
    );
  }
}
