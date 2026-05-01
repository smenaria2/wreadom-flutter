import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../../domain/models/book.dart';
import '../../providers/auth_providers.dart';
import '../../providers/book_providers.dart';
import '../book_card.dart';

class UserHistoryTab extends ConsumerStatefulWidget {
  const UserHistoryTab({super.key});

  @override
  ConsumerState<UserHistoryTab> createState() => _UserHistoryTabState();
}

class _UserHistoryTabState extends ConsumerState<UserHistoryTab> {
  int _limit = 12;
  static const int _increment = 12;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(readingHistoryBooksProvider);
    final l10n = AppLocalizations.of(context)!;

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                l10n.noReadingHistoryYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final displayCount = (_limit < books.length) ? _limit : books.length;
        final hasMore = _limit < books.length;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.44,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 28,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RemovableHistoryGridItem(
                    book: books[index],
                    onRemove: () =>
                        _removeHistoryBook(context, ref, books[index].id),
                  ),
                  childCount: displayCount,
                ),
              ),
            ),
            if (hasMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _limit += _increment),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.loadMore),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.errorLoadingHistory(err.toString())),
        ),
      ),
    );
  }

  Future<void> _removeHistoryBook(
    BuildContext context,
    WidgetRef ref,
    String bookId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeReadingHistoryTitle),
        content: Text(l10n.removeReadingHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    final next = List<dynamic>.from(user.readingHistory)
      ..removeWhere((id) => id?.toString() == bookId);
    await ref
        .read(authRepositoryProvider)
        .updateUserReadingHistory(user.id, next);
    ref.invalidate(currentUserProvider);
    ref.invalidate(readingHistoryBooksProvider);
  }
}

class _RemovableHistoryGridItem extends StatelessWidget {
  const _RemovableHistoryGridItem({required this.book, required this.onRemove});

  final Book book;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: BookCard(book: book, width: double.infinity),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              tooltip: l10n.remove,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
