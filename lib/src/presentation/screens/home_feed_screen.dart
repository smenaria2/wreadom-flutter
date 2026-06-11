import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../utils/app_haptics.dart';
import '../providers/feed_providers.dart';
import '../providers/notification_providers.dart';
import '../components/feed_post_card.dart';
import '../components/create_post_sheet.dart';
import '../routing/app_routes.dart';
import '../widgets/glass_surface.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(
              l10n.feed,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: 0,
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
              child: GlassControlSurface(
                borderRadius: BorderRadius.circular(26),
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
      floatingActionButton: GlassSurface(
        strong: true,
        borderRadius: BorderRadius.circular(24),
        onTap: () async {
          // Pick a random active question to prompt the user
          String? question;
          try {
            final questions = await ref.read(activeQuestionsProvider.future);
            if (questions.isNotEmpty) {
              questions.shuffle();
              question = questions.first;
            }
          } catch (_) {
            // Silently ignore — sheet opens without a question
          }
          if (context.mounted) {
            showCreatePostSheet(context, initialQuestion: question);
          }
        },
        semanticButton: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.post,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedFilterPage extends ConsumerStatefulWidget {
  const _FeedFilterPage({required this.filter});

  final FeedFilter filter;

  @override
  ConsumerState<_FeedFilterPage> createState() => _FeedFilterPageState();
}

class _FeedFilterPageState extends ConsumerState<_FeedFilterPage> {
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(pagedFeedPostsProvider(widget.filter));
    final feedController = ref.read(
      pagedFeedPostsProvider(widget.filter).notifier,
    );
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

    final items = feedState.items.where((post) {
      if (_selectedType == 'all') return true;
      if (_selectedType == 'question') {
        return post.question != null && post.question!.isNotEmpty;
      }
      return post.type.toLowerCase() == _selectedType;
    }).toList();

    final filterChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TypeChip(
            label: l10n.feedTypeAll,
            icon: Icons.public_rounded,
            selected: _selectedType == 'all',
            onSelected: () => setState(() => _selectedType = 'all'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: l10n.feedTypeComment,
            icon: Icons.chat_bubble_outline_rounded,
            selected: _selectedType == 'comment',
            onSelected: () => setState(() => _selectedType = 'comment'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: l10n.feedTypeQuote,
            icon: Icons.format_quote_rounded,
            selected: _selectedType == 'quote',
            onSelected: () => setState(() => _selectedType = 'quote'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: l10n.feedTypeReview,
            icon: Icons.star_outline_rounded,
            selected: _selectedType == 'review',
            onSelected: () => setState(() => _selectedType = 'review'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: l10n.feedTypeTestimony,
            icon: Icons.favorite_border_rounded,
            selected: _selectedType == 'testimony',
            onSelected: () => setState(() => _selectedType = 'testimony'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: l10n.feedTypeQuestion,
            icon: Icons.help_outline_rounded,
            selected: _selectedType == 'question',
            onSelected: () => setState(() => _selectedType = 'question'),
          ),
        ],
      ),
    );

    if (feedState.isInitialLoading) {
      return refreshable(
        Column(
          children: [
            filterChips,
            Expanded(
              child: centeredScrollable(const CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }
    if (feedState.error != null) {
      return refreshable(
        Column(
          children: [
            filterChips,
            Expanded(
              child: centeredScrollable(
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
            ),
          ],
        ),
      );
    }

    Widget body;
    if (feedState.items.isEmpty) {
      body = centeredScrollable(
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
              widget.filter == FeedFilter.following
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
      );
    } else if (items.isEmpty) {
      body = centeredScrollable(
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              "No posts found for this filter",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try loading more posts or choosing another filter.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            if (feedState.hasMore)
              FilledButton.icon(
                icon: feedState.isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(l10n.loadMore),
                onPressed: feedState.isLoadingMore
                    ? null
                    : feedController.loadMore,
              ),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 132),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _LoadMoreFeedButton(
              isLoading: feedState.isLoadingMore,
              hasMore: feedState.hasMore,
              onPressed: feedController.loadMore,
            );
          }
          return FeedPostCard(
            post: items[index],
            onReplyToQuestion: (question) {
              showCreatePostSheet(context, initialQuestion: question);
            },
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        filterChips,
        Expanded(child: refreshable(body)),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassSurface(
      strong: selected,
      borderRadius: BorderRadius.circular(24),
      onTap: onSelected,
      semanticButton: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.82)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
