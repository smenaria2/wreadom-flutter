import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import '../providers/feed_providers.dart';
import '../components/feed_post_card.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;
  final FeedPost? preloadedPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.preloadedPost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(singlePostProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        elevation: 0,
      ),
      body: postAsync.when(
        data: (post) {
          final effectivePost = post ?? preloadedPost;
          if (effectivePost == null) {
            return const Center(child: Text('Post not found or deleted'));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                FeedPostCard(post: effectivePost),
                const SizedBox(height: 100), // Space for bottom interactions
              ],
            ),
          );
        },
        loading: () => preloadedPost != null
            ? SingleChildScrollView(child: FeedPostCard(post: preloadedPost!))
            : const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load post: $err'),
            ],
          ),
        ),
      ),
    );
  }
}
