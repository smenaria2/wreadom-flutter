import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/book_providers.dart';
import '../../components/book_card.dart';

class UserContentTab extends ConsumerStatefulWidget {
  final String userId;
  const UserContentTab({super.key, required this.userId});

  @override
  ConsumerState<UserContentTab> createState() => _UserContentTabState();
}

class _UserContentTabState extends ConsumerState<UserContentTab> {
  bool _showAll = false;
  static const int _pageSize = 9;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(userBooksProvider(widget.userId));
    final theme = Theme.of(context);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                l10n.noPublishedBooksYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final visibleBooks = _showAll ? books : books.take(_pageSize).toList();
        final hasMore = !_showAll && books.length > _pageSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.44,
                crossAxisSpacing: 12,
                mainAxisSpacing: 28,
              ),
              itemCount: visibleBooks.length,
              itemBuilder: (context, index) =>
                  BookCard(book: visibleBooks[index], width: double.infinity),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showAll = true),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(
                      l10n.seeMoreContent,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 100),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.failedToLoadBooks(error.toString())),
        ),
      ),
    );
  }
}
