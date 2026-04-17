import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/book_card.dart';
import '../providers/book_providers.dart';
import '../providers/homepage_providers.dart';

class CategoryBooksArguments {
  const CategoryBooksArguments({required this.category});

  final String category;
}

class CategoryBooksScreen extends ConsumerWidget {
  const CategoryBooksScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = category.toLowerCase();
    void refresh() {
      switch (normalized) {
        case 'wreadom originals':
        case 'originals':
          ref.invalidate(originalBooksProvider);
          break;
        case 'popular now':
        case 'popular':
          ref.invalidate(homepagePopularProvider);
          break;
        case 'recently added':
        case 'recent':
          ref.invalidate(homepageRecentProvider);
          break;
        case 'community classics':
        case 'archive':
          ref.invalidate(homepageIABooksProvider);
          break;
        default:
          ref.invalidate(booksByGenreProvider(category));
      }
    }

    final booksAsync = switch (normalized) {
      'wreadom originals' || 'originals' => ref.watch(originalBooksProvider),
      'popular now' || 'popular' => ref.watch(homepagePopularProvider),
      'recently added' || 'recent' => ref.watch(homepageRecentProvider),
      'community classics' || 'archive' => ref.watch(homepageIABooksProvider),
      _ => ref.watch(booksByGenreProvider(category)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
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
            return Center(child: Text('No books found in $category yet.'));
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
            child: Text('Failed to load $category books: $error'),
          ),
        ),
      ),
    );
  }
}
