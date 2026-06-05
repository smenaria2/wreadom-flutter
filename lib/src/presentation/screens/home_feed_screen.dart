import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../utils/app_haptics.dart';
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectFilter(FeedFilter filter) {
    setState(() => _selectedFilter = filter);
    _pageController.animateToPage(
      FeedFilter.values.indexOf(filter),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    AppHaptics.selection();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              l10n.feed,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                tooltip: l10n.notifications,
                icon: Consumer(
                  builder: (context, ref, _) {
                    final unread = ref.watch(unreadNotificationCountProvider);
                    const icon = Icon(Icons.notifications_none_rounded);
                    if (unread <= 0) return icon;
                    return Badge(
                      label: Text(unread > 99 ? '99+' : '$unread'),
                      child: icon,
                    );
                  },
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: l10n.searchBooks,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SegmentedButton<FeedFilter>(
                segments: [
                  ButtonSegment(
                    value: FeedFilter.following,
                    label: Text(l10n.following),
                    icon: const Icon(Icons.people_outline_rounded),
                  ),
                  ButtonSegment(
                    value: FeedFilter.public,
                    label: Text(l10n.public),
                    icon: const Icon(Icons.public_rounded),
                  ),
                  ButtonSegment(
                    value: FeedFilter.mine,
                    label: Text(l10n.mine),
                    icon: const Icon(Icons.person_outline_rounded),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (selection) {
                  _selectFilter(selection.first);
                },
              ),
            ),
          ),
          SliverFillRemaining(
            child: PageView.builder(
              controller: _pageController,
              itemCount: FeedFilter.values.length,
              onPageChanged: (index) {
                setState(() => _selectedFilter = FeedFilter.values[index]);
                AppHaptics.selection();
              },
              itemBuilder: (context, index) {
                final filter = FeedFilter.values[index];
                return _FeedFilterPage(filter: filter);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home-feed-create-post-fab',
        onPressed: () => showCreatePostSheet(context),
        icon: const Icon(Icons.edit_rounded),
        label: Text(l10n.post),
      ),
    );
  }
}

class _FeedFilterPage extends ConsumerWidget {
  const _FeedFilterPage({required this.filter});

  final FeedFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(pagedFeedPostsProvider(filter));
    final feedController = ref.read(pagedFeedPostsProvider(filter).notifier);
    final l10n = AppLocalizations.of(context)!;

    Widget refreshable(Widget child) {
      return RefreshIndicator(onRefresh: feedController.refresh, child: child);
    }

    Widget centeredScrollable(Widget child) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: Center(child: child),
              ),
            ],
          );
        },
      );
    }

    if (feedState.isInitialLoading) {
      return refreshable(centeredScrollable(const CircularProgressIndicator()));
    }
    if (feedState.error != null) {
      return refreshable(
        centeredScrollable(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.somethingWentWrong,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feedState.error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: feedController.refresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }
    if (feedState.items.isEmpty) {
      return refreshable(
        centeredScrollable(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.feed_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              Text(
                filter == FeedFilter.following
                    ? l10n.noFollowingPosts
                    : l10n.noPosts,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.beFirstToPost,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.createAPost),
                onPressed: () => showCreatePostSheet(context),
              ),
            ],
          ),
        ),
      );
    }
    return refreshable(
      ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 132),
        itemCount: feedState.items.length + 1,
        itemBuilder: (context, index) {
          if (index == feedState.items.length) {
            return _LoadMoreFeedButton(
              isLoading: feedState.isLoadingMore,
              hasMore: feedState.hasMore,
              onPressed: feedController.loadMore,
            );
          }
          return FeedPostCard(post: feedState.items[index]);
        },
      ),
    );
  }
}

class _LoadMoreFeedButton extends StatelessWidget {
  const _LoadMoreFeedButton({
    required this.isLoading,
    required this.hasMore,
    required this.onPressed,
  });

  final bool isLoading;
  final bool hasMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!hasMore) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
          label: Text(l10n.loadMore),
        ),
      ),
    );
  }
}
