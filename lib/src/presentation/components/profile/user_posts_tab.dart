import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_providers.dart';
import '../feed_post_card.dart';

class UserPostsTab extends ConsumerWidget {
  final String userId;
  const UserPostsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userFeedPostsProvider(userId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                'No posts yet.\nStart sharing your reading journey!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
          itemBuilder: (context, index) => FeedPostCard(post: posts[index]),
          itemCount: posts.length,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading posts: $err'),
        ),
      ),
    );
  }
}
