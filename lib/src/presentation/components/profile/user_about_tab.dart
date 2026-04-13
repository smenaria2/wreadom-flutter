import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/book_providers.dart';
import '../../../domain/models/user_model.dart';
import '../book_card.dart';

class UserAboutTab extends ConsumerWidget {
  final UserModel user;
  const UserAboutTab({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // ─── Bio ──────────────────────────────────────────
        const Text(
          'Bio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.bio ?? 'No bio yet.',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // ─── Pinned Works ─────────────────────────────────
        const Text(
          'Pinned Works',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _HorizontalBookSection(
          provider: pinnedBooksProvider,
        ),
      ],
    );
  }
}

class _HorizontalBookSection extends ConsumerWidget {
  final FutureProvider<List<dynamic>> provider;

  const _HorizontalBookSection({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(provider);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No pinned books.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => BookCard(book: books[i]),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
