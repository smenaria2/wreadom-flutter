import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_providers.dart';
import '../providers/notification_providers.dart';
import '../components/feed_post_card.dart';
import '../components/create_post_sheet.dart';
import '../routing/app_routes.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  FeedFilter _selectedFilter = FeedFilter.following;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(filteredFeedPostsProvider(_selectedFilter));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(filteredFeedPostsProvider(_selectedFilter)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text(
                'Feed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: Consumer(
                    builder: (context, ref, _) {
                      final unreadCount = ref.watch(
                        unreadNotificationCountProvider,
                      );
                      return Badge(
                        label: Text('$unreadCount'),
                        isLabelVisible: unreadCount > 0,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.notifications_none_rounded),
                      );
                    },
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search books',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.discovery),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SegmentedButton<FeedFilter>(
                  segments: const [
                    ButtonSegment(
                      value: FeedFilter.following,
                      label: Text('Following'),
                      icon: Icon(Icons.people_outline_rounded),
                    ),
                    ButtonSegment(
                      value: FeedFilter.public,
                      label: Text('Public'),
                      icon: Icon(Icons.public_rounded),
                    ),
                    ButtonSegment(
                      value: FeedFilter.mine,
                      label: Text('Mine'),
                      icon: Icon(Icons.person_outline_rounded),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedFilter = selection.first);
                  },
                ),
              ),
            ),
            feedAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == FeedFilter.following
                                ? 'No posts from people you follow yet'
                                : 'No posts yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to post something!',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Create a Post'),
                            onPressed: () => showCreatePostSheet(context),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FeedPostCard(post: posts[index]),
                    childCount: posts.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(
                            filteredFeedPostsProvider(_selectedFilter),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreatePostSheet(context),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Post'),
      ),
    );
  }
}
