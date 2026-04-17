import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import '../providers/book_providers.dart';
import '../providers/discovery_providers.dart';
import '../providers/homepage_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import 'book_detail_screen.dart';
import '../../utils/map_utils.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _activeGenre;
  bool _initialized = false;

  static const _genres = [
    'Fantasy',
    'Romance',
    'Science Fiction',
    'Mystery',
    'Horror',
    'Historical',
    'Adventure',
    'Poetry',
    'Biography',
    'Philosophy',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = asStringMap(ModalRoute.of(context)?.settings.arguments);
    final query = args['query']?.toString();
    if (query == null || query == 'archive:') return;
    if (query.startsWith('subject:')) {
      _activeGenre = query.split(':').last;
    } else {
      _query = query;
      _searchController.text = query.startsWith('topic:')
          ? query.split(':').last
          : query;
    }
  }

  String get effectiveQuery {
    if (_activeGenre != null && _query.isEmpty) return 'subject:$_activeGenre';
    return _query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGenre = _activeGenre != null && _query.isEmpty;
    final genreAsync = hasGenre
        ? ref.watch(booksByGenreProvider(_activeGenre!))
        : null;
    final searchAsync = ref.watch(discoverySearchProvider(_query));
    final defaultAsync = ref.watch(discoveryDefaultBooksProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text(
              'Discover',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      setState(() {
                        _query = value.trim();
                        if (_query.isNotEmpty) _activeGenre = null;
                      });
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search books, authors...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
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
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in _genres)
                    FilterChip(
                      label: Text(genre),
                      selected: _activeGenre == genre,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _activeGenre = _activeGenre == genre ? null : genre;
                          _query = '';
                          _searchController.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          if (_query.isEmpty && !hasGenre)
            defaultAsync.when(
              data: (books) => _BookListSliver(
                title: 'Suggested Books',
                books: books,
                emptyText: 'No suggested books found.',
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $error')),
              ),
            )
          else if (hasGenre)
            genreAsync!.when(
              data: (books) => _BookListSliver(
                title: _activeGenre!,
                books: books,
                emptyText: 'No books found in $_activeGenre.',
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $error')),
              ),
            )
          else
            searchAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No results for "$effectiveQuery"'),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (results.originals.isNotEmpty)
                      _ResultSection(
                        title: 'Original Books',
                        books: results.originals,
                      ),
                    if (results.authors.isNotEmpty)
                      _AuthorResultSection(authors: results.authors),
                    if (results.archiveBooks.isNotEmpty)
                      _ResultSection(
                        title: 'More Books',
                        books: results.archiveBooks,
                      ),
                    const SizedBox(height: 32),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $error')),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookListSliver extends StatelessWidget {
  const _BookListSliver({
    required this.title,
    required this.books,
    required this.emptyText,
  });

  final String title;
  final List<Book> books;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(emptyText)),
      );
    }
    return SliverList(
      delegate: SliverChildListDelegate([
        _ResultSection(title: title, books: books),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.books});

  final String title;
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          for (final book in books) _SearchResultTile(book: book),
        ],
      ),
    );
  }
}

class _AuthorResultSection extends StatelessWidget {
  const _AuthorResultSection({required this.authors});

  final List<UserModel> authors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Authors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          for (final author in authors)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: author.photoURL != null
                      ? CachedNetworkImageProvider(author.photoURL!)
                      : null,
                  child: author.photoURL == null
                      ? Text(
                          (author.displayName ?? author.username)
                              .characters
                              .first
                              .toUpperCase(),
                        )
                      : null,
                ),
                title: Text(
                  author.displayName ?? author.penName ?? author.username,
                ),
                subtitle: Text('@${author.username}'),
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.publicProfile,
                  arguments: PublicProfileArguments(userId: author.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.book});

  final Book book;

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
            builder: (_) =>
                BookDetailScreen(bookId: book.id, preloadedBook: book),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        width: 56,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (book.source == 'archive') ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Internet Archive',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
  const _MiniPlaceholder({required this.title});

  final String title;

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

