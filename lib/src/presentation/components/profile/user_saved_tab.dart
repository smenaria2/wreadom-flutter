import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../../domain/models/book.dart';
import '../../providers/auth_providers.dart';
import '../../providers/book_providers.dart';
import '../book_card.dart';

class UserSavedTab extends ConsumerWidget {
  const UserSavedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(savedBooksProvider);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                l10n.noSavedBooksYet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.44,
            crossAxisSpacing: 12,
            mainAxisSpacing: 28,
          ),
          itemBuilder: (context, index) => _RemovableBookGridItem(
            book: books[index],
            onRemove: () => _removeSavedBook(context, ref, books[index].id),
          ),
          itemCount: books.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.failedToLoadSavedBooks(err.toString())),
        ),
      ),
    );
  }

  Future<void> _removeSavedBook(
    BuildContext context,
    WidgetRef ref,
    String bookId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeSavedBookTitle),
        content: Text(l10n.removeSavedBookBody),
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
    final next = List<dynamic>.from(user.savedBooks)
      ..removeWhere((id) => id?.toString() == bookId);
    await ref.read(authRepositoryProvider).updateUserSavedBooks(user.id, next);
    ref.invalidate(currentUserProvider);
    ref.invalidate(savedBooksProvider);
  }
}

class _RemovableBookGridItem extends StatelessWidget {
  const _RemovableBookGridItem({required this.book, required this.onRemove});

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
