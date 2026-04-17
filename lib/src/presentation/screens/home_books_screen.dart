import 'package:flutter/material.dart';
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
import '../providers/book_providers.dart';
import '../providers/daily_topic_providers.dart';

class HomeBooksScreen extends ConsumerWidget {
  const HomeBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originalsAsync = ref.watch(originalBooksProvider);
    final popularAsync = ref.watch(homepagePopularProvider);
    final recentAsync = ref.watch(homepageRecentProvider);
    final iaAsync = ref.watch(homepageIABooksProvider);
    final authorsAsync = ref.watch(homepageAuthorsProvider);
    final fantasyAsync = ref.watch(homepageGenreProvider('fantasy'));
    final romanceAsync = ref.watch(homepageGenreProvider('romance'));
    final sciFiAsync = ref.watch(homepageGenreProvider('sci-fi'));

    // Watch saved books for the new section

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Wreadom',
          style: TextStyle(
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
                tooltip: 'Notifications',
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
            tooltip: 'Search books',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.discovery),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homepageMetadataProvider);
          ref.invalidate(homepageBooksProvider);
          ref.invalidate(homepageIABooksProvider);
          ref.invalidate(homepageAuthorsProvider);
          ref.invalidate(homepageDownloadedBooksProvider);
          ref.invalidate(originalBooksProvider);
          ref.invalidate(popularBooksProvider);
          ref.invalidate(recentBooksProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero Banner (Daily Topics) ───────────────────────────
              const _HeroBanner(),
              const SizedBox(height: 12),

              // ─── Saved Books (Local & Remote) ─────────────────────────
              const _SavedBooksSection(),
              const SizedBox(height: 28),

              // ─── Wreadom Originals ────────────────────────────────────
              _BookshelfSection(
                title: 'Community Classics',
                booksAsync: iaAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(
                  AppRoutes.category,
                  arguments: const CategoryBooksArguments(
                    category: 'Community Classics',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              _BookshelfSection(
                title: 'Wreadom Originals',
                booksAsync: originalsAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(
                  AppRoutes.category,
                  arguments: const CategoryBooksArguments(
                    category: 'Wreadom Originals',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Popular Books ────────────────────────────────────────
              _BookshelfSection(
                title: 'Popular Now',
                booksAsync: popularAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(
                  AppRoutes.category,
                  arguments: const CategoryBooksArguments(
                    category: 'Popular Now',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Recently Added ───────────────────────────────────────
              _BookshelfSection(
                title: 'Recently Added',
                booksAsync: recentAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(
                  AppRoutes.category,
                  arguments: const CategoryBooksArguments(
                    category: 'Recently Added',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Genre Sections (Filtered) ─────────────────────────────
              _GenreSection(
                title: 'Fantasy',
                booksAsync: fantasyAsync,
                genre: 'Fantasy',
                sectionId: 'fantasy',
              ),
              _AuthorsSection(authorsAsync: authorsAsync),
              const SizedBox(height: 28),
              _GenreSection(
                title: 'Romance',
                booksAsync: romanceAsync,
                genre: 'Romance',
                sectionId: 'romance',
              ),
              _GenreSection(
                title: 'Sci-Fi',
                booksAsync: sciFiAsync,
                genre: 'Sci-Fi',
                sectionId: 'sci-fi',
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
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _pageController,
                itemCount: topics.length,
                onPageChanged: (index) {
                  setState(() {}); // For indicator update
                  if (index >= topics.length - 1) {
                    ref.read(dailyTopicsProvider.notifier).fetchMore();
                  }
                },
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return _DailyTopicCard(topic: topic);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                topics.length,
                (index) => _buildIndicator(index, topics.length),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _buildDefaultBanner(context),
    );
  }

  Widget _buildIndicator(int index, int total) {
    bool isActive = false;
    try {
      if (_pageController.hasClients) {
        // Use the actual page index from state/controller
        isActive =
            (_pageController.page?.round() ?? _pageController.initialPage) ==
            index;
      } else {
        isActive = (index == 0);
      }
    } catch (_) {
      isActive = (index == 0);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildDefaultBanner(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'Keep Reading',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thousands of free books and original stories, curated for you.',
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
            child: const Text(
              'Explore Now',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              child: const Text(
                'Daily Topic',
                style: TextStyle(
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
              child: const Text(
                'Read More',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              onSeeAll: () => Navigator.of(context).pushNamed(
                AppRoutes.category,
                arguments: CategoryBooksArguments(category: genre),
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
      loading: () => Column(
        children: [
          _BookshelfSection(title: title, booksAsync: booksAsync),
          const SizedBox(height: 28),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Saved Books Section (Top Shelf) ──────────────────────────────────────────
class _SavedBooksSection extends ConsumerWidget {
  const _SavedBooksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteSavedAsync = ref.watch(homepageDownloadedBooksProvider);

    return remoteSavedAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();

        return _BookshelfSection(
          title: 'Your Shelf',
          booksAsync: remoteSavedAsync,
          sectionId: 'saved',
          onSeeAll: () {
            Navigator.of(context).pushNamed(AppRoutes.savedBooks);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Bookshelf Row ────────────────────────────────────────────────────────────
class _AuthorsSection extends StatelessWidget {
  const _AuthorsSection({required this.authorsAsync});

  final AsyncValue<List<UserModel>> authorsAsync;

  @override
  Widget build(BuildContext context) {
    return authorsAsync.when(
      data: (authors) {
        if (authors.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Writers to Follow',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: authors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final author = authors[index];
                  final displayName = author.displayName;
                  final penName = author.penName;
                  final name = (displayName != null && displayName.isNotEmpty)
                      ? displayName
                      : (penName != null && penName.isNotEmpty)
                          ? penName
                          : author.username;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.publicProfile,
                      arguments: PublicProfileArguments(userId: author.id),
                    ),
                    child: SizedBox(
                      width: 86,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: author.photoURL != null && author.photoURL!.isNotEmpty
                                ? CachedNetworkImageProvider(author.photoURL!)
                                : null,
                            child: (author.photoURL == null || author.photoURL!.isEmpty) && name.isNotEmpty
                                ? Text(name.characters.first.toUpperCase())
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _BookshelfSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<Book>> booksAsync;
  final String? sectionId;
  final VoidCallback? onSeeAll;

  const _BookshelfSection({
    required this.title,
    required this.booksAsync,
    this.sectionId,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
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
                  TextButton(onPressed: onSeeAll, child: const Text('See All')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) => _BookCard(
                  book: books[index],
                  sectionId:
                      sectionId ?? title.replaceAll(' ', '-').toLowerCase(),
                ),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
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
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Book book;
  final String sectionId;
  const _BookCard({required this.book, required this.sectionId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final tag = 'book-cover-$sectionId-${book.id}';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              preloadedBook: book,
              heroTag: tag,
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
                        tag: 'book-cover-$sectionId-${book.id}',
                        child: CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
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
                              _CoverPlaceholder(title: book.title),
                        ),
                      )
                    : _CoverPlaceholder(title: book.title),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            // Author
            Text(
              book.authors.isNotEmpty
                  ? book.authors.first.name
                  : 'Unknown Author',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 12, width: 100, color: Colors.grey[200]),
          const SizedBox(height: 4),
          Container(height: 10, width: 70, color: Colors.grey[100]),
        ],
      ),
    );
  }
}
