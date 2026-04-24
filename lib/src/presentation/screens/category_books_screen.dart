import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/book_card.dart';
import '../providers/book_providers.dart';
import '../providers/homepage_providers.dart';

class CategoryBooksArguments {
  const CategoryBooksArguments({required this.category, this.displayName});

  final String category;
  final String? displayName;
}

class CategoryBooksScreen extends ConsumerWidget {
  const CategoryBooksScreen({
    super.key,
    required this.category,
    this.displayName,
  });

  final String category;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = category.toLowerCase();
    void refresh() => refreshHomepage(ref);

    final booksAsync = switch (normalized) {
      'wreadom originals' ||
      'originals' ||
      'wreadom-originals' =>
        ref.watch(homepageOriginalsProvider),
      'trending works' ||
      'trending' ||
      'trending-works' =>
        ref.watch(homepageTrendingWorksProvider),
      'popular now' || 'popular' || 'popular-now' =>
        ref.watch(homepagePopularProvider),
      'recently added' ||
      'recent' ||
      'recently-added' =>
        ref.watch(homepageRecentProvider),
      'community classics' ||
      'archive' ||
      'community-classics' =>
        ref.watch(homepageIABooksProvider),
      _ => ref.watch(booksByGenreProvider(category)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName ?? category),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: refresh,
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Text(
                l10n.noBooksFoundIn(displayName ?? category),
              ),
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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.errorWithDetails(error.toString()),
            ),
          ),
        ),
      ),
    );
  }
}
