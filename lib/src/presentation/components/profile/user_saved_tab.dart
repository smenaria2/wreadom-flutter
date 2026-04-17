import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/book_providers.dart';
import '../book_card.dart';

class UserSavedTab extends ConsumerWidget {
  const UserSavedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(savedBooksProvider);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                'No saved books yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
          itemBuilder: (context, index) =>
              BookCard(book: books[index], width: double.infinity),
          itemCount: books.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading saved books: $err'),
        ),
      ),
    );
  }
}
