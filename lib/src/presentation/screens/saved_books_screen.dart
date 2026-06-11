import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../components/book_card.dart';
import '../providers/book_providers.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class SavedBooksScreen extends ConsumerWidget {
  const SavedBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(savedBooksProvider);
    final l10n = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(l10n.savedBooksTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(savedBooksProvider),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return _SavedBooksMessage(
              icon: Icons.bookmark_border_rounded,
              message: l10n.noSavedOrDownloadedBooksYet,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.56,
              crossAxisSpacing: 12,
              mainAxisSpacing: 18,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) => BookCard(book: books[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SavedBooksMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.failedToLoadSavedBooks(error.toString()),
        ),
      ),
    );
  }
}

class _SavedBooksMessage extends StatelessWidget {
  const _SavedBooksMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
