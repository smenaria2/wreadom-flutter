import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                'No reading history yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
                  (context, index) =>
                      BookCard(book: books[index], width: double.infinity),
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
                      label: const Text('Load More'),
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
          child: Text('Error loading history: $err'),
        ),
      ),
    );
  }
}
