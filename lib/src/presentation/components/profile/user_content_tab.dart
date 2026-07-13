import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/book_providers.dart';
import '../../components/book_card.dart';
import '../../widgets/themed_empty_state.dart';
import '../../widgets/see_more_content_button.dart';
import '../collections/horizontal_collections_list.dart';

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

    return booksAsync.when(
      data: (books) {
        final visibleBooks = _showAll ? books : books.take(_pageSize).toList();
        final hasMore = !_showAll && books.length > _pageSize;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HorizontalCollectionsList(userId: widget.userId, canCreate: true),
              if (books.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48, left: 16, right: 16),
                  child: ThemedEmptyState(
                    icon: Icons.auto_stories_outlined,
                    message: l10n.noPublishedBooksYet,
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
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
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SeeMoreContentButton(
                        onPressed: () => setState(() => _showAll = true),
                      ),
                    ),
                  ),
              ],
            ],
          ),
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

