import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/book.dart';
import '../../domain/models/user_model.dart';
import '../providers/book_providers.dart';
import '../providers/discovery_providers.dart';
import '../components/generated_book_cover.dart';
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
            title: Text(
              AppLocalizations.of(context)!.discover,
              style: const TextStyle(
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
                  textInputAction: TextInputAction.search,
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
                    labelText: AppLocalizations.of(context)!.searchBooksAuthors,
                    hintText: AppLocalizations.of(context)!.searchHint,
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
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in _genres)
                      FilterChip(
                        label: Text(_getLocalizedGenre(context, genre)),
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
                title: AppLocalizations.of(context)!.suggestedBooks,
                books: books,
                emptyText: AppLocalizations.of(context)!.noSuggestedBooks,
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(AppLocalizations.of(context)!.errorWithDetails(error.toString()))),
              ),
            )
          else if (hasGenre)
            genreAsync!.when(
              data: (books) => _BookListSliver(
                title: _getLocalizedGenre(context, _activeGenre!),
                books: books,
                emptyText: AppLocalizations.of(context)!.noBooksFoundIn(_getLocalizedGenre(context, _activeGenre!)),
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(AppLocalizations.of(context)!.errorWithDetails(error.toString()))),
              ),
            )
          else
            searchAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.noResultsFor(effectiveQuery)),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (results.authors.isNotEmpty)
                      _AuthorResultSection(authors: results.authors),
                    if (results.originals.isNotEmpty)
                      _ResultSection(
                        title: AppLocalizations.of(context)!.originalBooks,
                        books: results.originals,
                      ),
                    if (results.archiveBooks.isNotEmpty)
                      _ResultSection(
                        title: AppLocalizations.of(context)!.moreBooks,
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
                child: Center(child: Text(AppLocalizations.of(context)!.errorWithDetails(error.toString()))),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profiles,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: authors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _AuthorProfileCard(author: authors[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorProfileCard extends StatelessWidget {
  const _AuthorProfileCard({required this.author});

  final UserModel author;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = author.displayName ?? author.penName ?? author.username;
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : '?';

    return SizedBox(
      width: 128,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.publicProfile,
            arguments: PublicProfileArguments(userId: author.id),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      author.photoURL != null && author.photoURL!.isNotEmpty
                      ? CachedNetworkImageProvider(author.photoURL!)
                      : null,
                  child: author.photoURL == null || author.photoURL!.isEmpty
                      ? Text(initial)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Semantics(
        button: true,
        label:
            '${book.title} ${AppLocalizations.of(context)!.about} ${book.authors.isNotEmpty ? book.authors.map((a) => a.name).join(', ') : AppLocalizations.of(context)!.unknownAuthor}',
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
                              _MiniPlaceholder(book: book),
                        )
                      : _MiniPlaceholder(book: book),
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
                            : AppLocalizations.of(context)!.unknownAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      if (book.source == 'archive') ...[
                        const SizedBox(height: 6),
                        Text(
                          AppLocalizations.of(context)!.internetArchive,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  const _MiniPlaceholder({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return GeneratedBookCover(
      width: 56,
      height: 80,
      title: book.title,
      author: book.authors.isNotEmpty ? book.authors.first.name : null,
      seed: book.id,
      borderRadius: 8,
      compact: true,
    );
  }
}

String _getLocalizedGenre(BuildContext context, String genre) {
  final l10n = AppLocalizations.of(context)!;
  switch (genre) {
    case 'Fantasy':
      return l10n.genreFantasy;
    case 'Romance':
      return l10n.genreRomance;
    case 'Science Fiction':
      return l10n.genreSciFi;
    case 'Mystery':
      return l10n.genreMystery;
    case 'Horror':
      return l10n.genreHorror;
    case 'Historical':
      return l10n.genreHistorical;
    case 'Adventure':
      return l10n.genreAdventure;
    case 'Poetry':
      return l10n.genrePoetry;
    case 'Biography':
      return l10n.genreBiography;
    case 'Philosophy':
      return l10n.genrePhilosophy;
    default:
      return genre;
  }
}
