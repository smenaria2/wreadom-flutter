import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../providers/homepage_providers.dart';
import '../../domain/models/book.dart';
import 'book_detail_screen.dart';
import '../routing/app_routes.dart';
import '../providers/book_providers.dart';

class HomeBooksScreen extends ConsumerWidget {
  const HomeBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final originalsAsync = ref.watch(homepageOriginalsProvider);
    final popularAsync = ref.watch(homepagePopularProvider);
    final recentAsync = ref.watch(homepageRecentProvider);
    final fantasyAsync = ref.watch(homepageGenreProvider('fantasy'));
    final romanceAsync = ref.watch(homepageGenreProvider('romance'));
    final sciFiAsync = ref.watch(homepageGenreProvider('sci-fi'));

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
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homepageMetadataProvider);
          ref.invalidate(homepageBooksProvider);
          ref.invalidate(originalBooksProvider);
          ref.invalidate(popularBooksProvider);
          ref.invalidate(recentBooksProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hero Banner ─────────────────────────────────────────
              _HeroBanner(onExplore: () => Navigator.of(context).pushNamed(AppRoutes.discovery)),
              const SizedBox(height: 28),

              // ─── Wreadom Originals ────────────────────────────────────
              _BookshelfSection(
                title: '✨ Wreadom Originals',
                booksAsync: originalsAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
              const SizedBox(height: 28),

              // ─── Popular ─────────────────────────────────────────────
              _BookshelfSection(
                title: '🔥 Popular Right Now',
                booksAsync: popularAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
              const SizedBox(height: 28),

              // ─── Recently Added ───────────────────────────────────────
              _BookshelfSection(
                title: '🆕 Recently Added',
                booksAsync: recentAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
              const SizedBox(height: 28),

              // ─── Fantasy ────────────────────────────────────────────────
              _BookshelfSection(
                title: '🧙 Fantasy',
                booksAsync: fantasyAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
              const SizedBox(height: 28),

              // ─── Romance ────────────────────────────────────────────────
              _BookshelfSection(
                title: '💖 Romance',
                booksAsync: romanceAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
              const SizedBox(height: 28),

              // ─── Sci-Fi ──────────────────────────────────────────────────
              _BookshelfSection(
                title: '🚀 Sci-Fi',
                booksAsync: sciFiAsync,
                onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.discovery),
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
class _HeroBanner extends ConsumerWidget {
  final VoidCallback? onExplore;
  const _HeroBanner({this.onExplore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataAsync = ref.watch(homepageMetadataProvider);

    return metadataAsync.when(
      data: (metadata) {
        final activeTopics = metadata.dailyTopics.where((t) => t.isEnabled).toList();
        if (activeTopics.isEmpty) return _buildDefaultBanner(context);

        final topic = activeTopics.first;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(topic.coverImageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.3),
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
                    child: const Text('Daily Topic', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.topicName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onExplore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Read More',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _buildDefaultBanner(context),
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
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
              color: Theme.of(context)
                  .colorScheme
                  .onPrimary
                  .withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onExplore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Explore Now',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Bookshelf Row ────────────────────────────────────────────────────────────
class _BookshelfSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<Book>> booksAsync;
  final VoidCallback? onSeeAll;

  const _BookshelfSection({
    required this.title,
    required this.booksAsync,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
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
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 210,
          child: booksAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    'No books found',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) =>
                    _BookCard(book: books[index]),
              );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, _) => const _BookCardSkeleton(),
            ),
            error: (err, _) => Center(
              child: Text('Failed to load',
                  style: TextStyle(color: Colors.grey[500])),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Book Card ────────────────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
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
                        tag: 'book-cover-${book.id}',
                        child: Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) =>
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
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
          Container(
              height: 12, width: 100, color: Colors.grey[200]),
          const SizedBox(height: 4),
          Container(height: 10, width: 70, color: Colors.grey[100]),
        ],
      ),
    );
  }
}
