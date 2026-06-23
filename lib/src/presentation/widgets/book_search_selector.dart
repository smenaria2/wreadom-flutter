import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/book.dart';
import '../providers/book_providers.dart';
import 'glass_surface.dart';

Future<Book?> showBookSearchSelector(BuildContext context) {
  return showModalBottomSheet<Book>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: const BookSearchSelector(),
    ),
  );
}

class BookSearchSelector extends ConsumerStatefulWidget {
  const BookSearchSelector({super.key});

  @override
  ConsumerState<BookSearchSelector> createState() => _BookSearchSelectorState();
}

class _BookSearchSelectorState extends ConsumerState<BookSearchSelector> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _query = value.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Watch book search results
    final searchAsync = ref.watch(bookSearchProvider(_query));

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Title row
            Row(
              children: [
                Text(
                  'Refer a Book',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search input
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),

            // Search Results List
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Type to search for books',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : searchAsync.when(
                      data: (books) {
                        if (books.isEmpty) {
                          return Center(
                            child: Text(
                              l10n.noResultsFound,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: books.length,
                          separatorBuilder: (_, _) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            final authorsStr = book.authors
                                .map((a) => a.name.trim())
                                .where((name) => name.isNotEmpty)
                                .join(', ');

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: book.coverUrl!,
                                        width: 44,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          width: 44,
                                          height: 64,
                                          child: const Icon(Icons.book, size: 20),
                                        ),
                                        errorWidget: (_, _, _) => Container(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          width: 44,
                                          height: 64,
                                          child: const Icon(Icons.book, size: 20),
                                        ),
                                      )
                                    : Container(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        width: 44,
                                        height: 64,
                                        child: const Icon(Icons.book, size: 20),
                                      ),
                              ),
                              title: Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                authorsStr.isNotEmpty ? authorsStr : 'Unknown Author',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => Navigator.pop(context, book),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(
                        child: Text(
                          l10n.errorWithDetails(err.toString()),
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
