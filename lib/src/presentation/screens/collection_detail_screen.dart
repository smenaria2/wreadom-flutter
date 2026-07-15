import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/book_collection.dart';
import '../../utils/app_haptics.dart';
import '../../utils/app_link_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/book_card.dart';
import '../components/generated_book_cover.dart';
import '../components/collections/collection_form_sheet.dart';
import '../components/collections/collection_widgets.dart';

import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/collection_providers.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    this.heroScope = 'default',
  });

  final String collectionId;
  final String heroScope;

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  bool _savingOrder = false;
  bool _isReordering = false;
  List<Book>? _optimisticBooks;

  Future<void> _delete(BookCollection collection) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCollectionQuestion),
        content: Text(l10n.deleteCollectionWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(collectionMutationProvider(collection.id).notifier)
          .run((repo) => repo.deleteCollection(collection.id));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString()),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.retry,
        onPressed: () {},
      ),
    ),
  );

  Future<void> _reorder(int oldIndex, int newIndex, List<Book> source) async {
    if (_savingOrder) return;
    if (oldIndex == newIndex) return;
    final before = List<Book>.of(source);
    final next = List<Book>.of(source);
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    setState(() {
      _optimisticBooks = next;
      _savingOrder = true;
    });
    await AppHaptics.light();
    try {
      await ref
          .read(collectionMutationProvider(widget.collectionId).notifier)
          .run(
            (repo) => repo.reorderBooks(
              widget.collectionId,
              next.map((book) => book.id).toList(),
            ),
          );
      ref.invalidate(resolvedCollectionBooksProvider(widget.collectionId));
    } catch (error) {
      if (mounted) {
        setState(() => _optimisticBooks = before);
        _showError(error);
      }
    } finally {
      if (mounted) setState(() => _savingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collectionAsync = ref.watch(
      collectionDetailProvider(widget.collectionId),
    );
    final booksAsync = ref.watch(
      resolvedCollectionBooksProvider(widget.collectionId),
    );
    final userId = ref.watch(currentUserProvider).asData?.value?.id;
    return collectionAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.collectionLoadFailed(error.toString()))),
      ),
      data: (collection) {
        if (collection == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.collectionNotFound)),
          );
        }
        final isOwner = userId == collection.ownerId;
        final mutation = ref.watch(collectionMutationProvider(collection.id));
        final theme = Theme.of(context);
        return Scaffold(
          floatingActionButton: isOwner && _isReordering
              ? FloatingActionButton.extended(
                  onPressed: () => setState(() => _isReordering = false),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done reordering'),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                actions: [
                  if (isOwner)
                    IconButton(
                      tooltip: l10n.addBooks,
                      onPressed: mutation.isLoading
                          ? null
                          : () => _showAddBooks(context, collection),
                      icon: const Icon(Icons.playlist_add_rounded),
                    ),
                  IconButton(
                    tooltip: l10n.shareCollection,
                    onPressed: () => Share.share(
                      AppLinkHelper.collection(collection.id),
                      subject: collection.title,
                    ),
                    icon: const Icon(Icons.share_outlined),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _delete(collection);
                        } else if (value == 'reorder') {
                          setState(() => _isReordering = !_isReordering);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'reorder',
                          child: Text(
                            _isReordering ? 'Done reordering' : 'Reorder books',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: _CollectionAppBarTitle(title: collection.title),
                  background: _CollectionAppBarBackground(
                    collection: collection,
                    isOwner: isOwner,
                    heroScope: widget.heroScope,
                  ),
                ),
              ),
              booksAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l10n.collectionBooksLoadFailed(error.toString()),
                    ),
                  ),
                ),
                data: (streamBooks) {
                  final books = _optimisticBooks ?? streamBooks;
                  if (books.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l10n.collectionEmpty)),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.44,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 28,
                          ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final baseCard = Stack(
                          clipBehavior: Clip.none,
                          children: [
                            BookCard(book: book, width: double.infinity),
                            if (_isReordering)
                              Positioned(
                                left: 8,
                                top: 8,
                                child: Material(
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: 0.92,
                                  ),
                                  shape: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            if (isOwner)
                              Positioned(
                                top: -8,
                                right: -8,
                                child: Material(
                                  color: theme.colorScheme.surface,
                                  shape: const CircleBorder(),
                                  elevation: 2,
                                  child: IconButton(
                                    tooltip: l10n.remove,
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 18,
                                    onPressed: mutation.isLoading
                                        ? null
                                        : () async {
                                            try {
                                              await ref
                                                  .read(
                                                    collectionMutationProvider(
                                                      collection.id,
                                                    ).notifier,
                                                  )
                                                  .run(
                                                    (repo) => repo.removeBook(
                                                      collection.id,
                                                      book.id,
                                                    ),
                                                  );
                                              ref.invalidate(
                                                resolvedCollectionBooksProvider(
                                                  collection.id,
                                                ),
                                              );
                                            } catch (error) {
                                              if (context.mounted) {
                                                _showError(error);
                                              }
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );

                        if (isOwner && _isReordering) {
                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) =>
                                details.data != index,
                            onAcceptWithDetails: (details) {
                              final oldIndex = details.data;
                              _reorder(oldIndex, index, books);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isHovered = candidateData.isNotEmpty;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isHovered
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: LongPressDraggable<int>(
                                  data: index,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Transform.scale(
                                      scale: 1.05,
                                      child: Opacity(
                                        opacity: 0.8,
                                        child: SizedBox(
                                          width: 120,
                                          height: 180,
                                          child: BookCard(
                                            book: book,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: BookCard(
                                      book: book,
                                      width: double.infinity,
                                    ),
                                  ),
                                  child: baseCard,
                                ),
                              );
                            },
                          );
                        }

                        return baseCard;
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddBooks(
    BuildContext context,
    BookCollection collection,
  ) async {
    final added = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddBooksSheet(collection: collection),
    );
    if (added == null || added.isEmpty) return;
    try {
      await ref
          .read(collectionMutationProvider(collection.id).notifier)
          .run((repo) => repo.addBooks(collection.id, added));
      ref.invalidate(resolvedCollectionBooksProvider(collection.id));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }
}

class _AddBooksSheet extends ConsumerStatefulWidget {
  const _AddBooksSheet({required this.collection});
  final BookCollection collection;

  @override
  ConsumerState<_AddBooksSheet> createState() => _AddBooksSheetState();
}

class _AddBooksSheetState extends ConsumerState<_AddBooksSheet> {
  String _query = '';
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final results = _query.trim().isEmpty
        ? (currentUser == null
              ? const AsyncValue<List<Book>>.data([])
              : ref.watch(userBooksProvider(currentUser.id)))
        : ref.watch(bookSearchProvider(_query.trim()));
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addBooks,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SearchBar(
              hintText: l10n.searchBooksForCollection,
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.when(
                data: (books) => ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (_, index) {
                    final book = books[index];
                    return CheckboxListTile(
                      value: _selected.contains(book.id),
                      title: Text(book.title),
                      subtitle: Text(
                        book.authors.map((author) => author.name).join(', '),
                      ),
                      secondary: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 36,
                          height: 54,
                          child:
                              book.coverUrl != null && book.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: book.coverUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      GeneratedBookCover(
                                        title: book.title,
                                        author: book.authors.isNotEmpty
                                            ? book.authors.first.name
                                            : null,
                                        seed: book.id,
                                        borderRadius: 6,
                                        compact: true,
                                      ),
                                )
                              : GeneratedBookCover(
                                  title: book.title,
                                  author: book.authors.isNotEmpty
                                      ? book.authors.first.name
                                      : null,
                                  seed: book.id,
                                  borderRadius: 6,
                                  compact: true,
                                ),
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        value == true
                            ? _selected.add(book.id)
                            : _selected.remove(book.id);
                      }),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected.toList()),
              child: Text(l10n.addSelectedBooks(_selected.length)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionAppBarTitle extends StatelessWidget {
  const _CollectionAppBarTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

    double opacity = 0.0;
    if (settings != null) {
      final delta = settings.maxExtent - settings.minExtent;
      final collapseProgress =
          ((settings.maxExtent - settings.currentExtent) / delta).clamp(
            0.0,
            1.0,
          );
      // Fade in the title in the last 30% of scroll progress
      opacity = ((collapseProgress - 0.7) / 0.3).clamp(0.0, 1.0);
    }

    return Opacity(
      opacity: opacity,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CollectionAppBarBackground extends StatelessWidget {
  const _CollectionAppBarBackground({
    required this.collection,
    required this.isOwner,
    required this.heroScope,
  });

  final BookCollection collection;
  final bool isOwner;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final settings = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double opacity = 1.0;
    if (settings != null) {
      final delta = settings.maxExtent - settings.minExtent;
      final collapseProgress =
          ((settings.maxExtent - settings.currentExtent) / delta).clamp(
            0.0,
            1.0,
          );
      // Fade out the expanded header completely by 60% of scroll progress
      opacity = (1.0 - collapseProgress / 0.6).clamp(0.0, 1.0);
    }

    return Opacity(
      opacity: opacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CollectionCoverCollage(collection: collection, borderRadius: 0),
          if (!reduceMotion)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: const ColoredBox(color: Color(0x52000000)),
            )
          else
            const ColoredBox(color: Color(0x66000000)),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox.square(
                  dimension: 120,
                  child: Hero(
                    tag: collectionHeroTag(collection.id, heroScope),
                    child: ClipOval(
                      child: CollectionCoverCollage(
                        collection: collection,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          collection.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => showCollectionFormSheet(
                            context,
                            collection: collection,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Description row
                if (collection.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            collection.description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.collectionBookCount(collection.bookCount),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
