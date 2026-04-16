import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/book_providers.dart';
import '../providers/discovery_providers.dart';
import '../../domain/models/book.dart';
import 'book_detail_screen.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _activeGenre;
  bool _initialized = false;
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('query')) {
        final query = args['query'] as String;
        if (query.startsWith('subject:')) {
          _activeGenre = query.split(':').last;
          _query = '';
        } else if (query.startsWith('topic:')) {
          _query = query;
          _searchController.text = query.split(':').last;
        } else {
          _query = query;
          _searchController.text = _query;
        }
      }
    }
  }

  String get effectiveQuery {
    if (_activeGenre != null && _query.isEmpty) return 'subject:$_activeGenre';
    return _query;
  }

  static const _genres = [
    'Fantasy', 'Romance', 'Science Fiction', 'Mystery', 'Horror',
    'Historical', 'Adventure', 'Poetry', 'Biography', 'Philosophy',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Choose the provider based on current state (Genre vs Search)
    final searchAsync = (_activeGenre != null && _query.isEmpty)
        ? ref.watch(booksByGenreProvider(_activeGenre!))
        : ref.watch(bookSearchProvider(effectiveQuery));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar + Search ──────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Discover',
              style:
                  TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      setState(() {
                        _query = val.trim();
                        if (_query.isNotEmpty) _activeGenre = null;
                      });
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search books, authors…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),

          // ─── Context Title (Topic/Genre) ───────────────────────────
          if (_activeGenre != null || (effectiveQuery.isNotEmpty && effectiveQuery != _searchController.text))
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                 child: Row(
                   children: [
                     Icon(
                       _activeGenre != null ? Icons.category_rounded : Icons.topic_rounded,
                       size: 18,
                       color: theme.colorScheme.primary,
                     ),
                     const SizedBox(width: 8),
                     Text(
                       _activeGenre != null 
                           ? 'Category: $_activeGenre' 
                           : 'Topic: $effectiveQuery',
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                         color: theme.colorScheme.primary,
                       ),
                     ),
                     const Spacer(),
                     TextButton(
                       onPressed: () {
                         setState(() {
                           _activeGenre = null;
                           _query = '';
                           _searchController.clear();
                         });
                       },
                       child: const Text('Clear Filter'),
                     ),
                   ],
                 ),
               ),
             ),

          // ─── Genre chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Browse by Genre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _genres.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final genre = _genres[i];
                      final active = _activeGenre == genre;
                      return FilterChip(
                        label: Text(genre),
                        selected: active,
                        onSelected: (_) {
                          setState(() {
                            _activeGenre = active ? null : genre;
                            if (!active) {
                              _searchController.clear();
                              _query = '';
                            }
                          });
                        },
                        showCheckmark: false,
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: active
                              ? theme.colorScheme.onPrimary
                              : null,
                          fontWeight:
                              active ? FontWeight.bold : null,
                        ),
                        side: BorderSide(
                          color: active
                              ? Colors.transparent
                              : Colors.grey[300]!,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ─── Results or Default Browse ─────────────────────────────
          if (effectiveQuery.isEmpty)
            ..._buildDefaultBrowse(context, theme)
          else
            searchAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$effectiveQuery"',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _SearchResultTile(book: books[index]),
                      childCount: books.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $err')),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the default Discovery browse view with trending books and
  /// genre previews when no search is active.
  List<Widget> _buildDefaultBrowse(BuildContext context, ThemeData theme) {
    final trendingAsync = ref.watch(archiveTrendingProvider);

    return [
      // ─── Trending Section ─────────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Trending Now',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: trendingAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return const Center(
                  child: Text('No trending books found',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, i) =>
                    _TrendingBookCard(book: books[i]),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error: $err')),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 24)),

      // ─── Genre Preview Sections ───────────────────────────────
      ..._genres.take(4).map((genre) {
        final genreAsync = ref.watch(archiveGenrePreviewProvider(genre));
        return SliverToBoxAdapter(
          child:
          genreAsync.when(
            data: (books) {
              if (books.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          genre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _activeGenre = genre;
                              _searchController.clear();
                              _query = '';
                            });
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      itemBuilder: (context, i) =>
                          _TrendingBookCard(book: books[i]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
        );
      }),

      // Bottom padding
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ];
  }
}

// ─── Trending Book Card ───────────────────────────────────────────────────────
class _TrendingBookCard extends StatelessWidget {
  final Book book;
  const _TrendingBookCard({required this.book});

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
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _CoverPlaceholder(title: book.title),
                          )
                        : _CoverPlaceholder(title: book.title),
                    // Source badge
                    if (book.source == 'archive')
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
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
                  : 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Result Tile ───────────────────────────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final Book book;
  const _SearchResultTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              preloadedBook: book,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 56,
                          height: 80,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) =>
                            _MiniPlaceholder(title: book.title),
                      )
                    : _MiniPlaceholder(title: book.title),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authors.isNotEmpty
                          ? book.authors.map((a) => a.name).join(', ')
                          : 'Unknown Author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (book.source == 'archive')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Internet Archive',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (book.subjects.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              children: book.subjects.take(2).map((s) {
                                return Chip(
                                  label: Text(s,
                                      style: const TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide.none,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.4),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  final String title;
  const _MiniPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            title,
            maxLines: 3,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 9,
            ),
          ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
