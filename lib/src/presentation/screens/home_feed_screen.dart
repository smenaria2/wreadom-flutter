import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../utils/app_haptics.dart';
import '../providers/audio_post_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/local_posts_notifier.dart';
import '../components/feed_post_card.dart';
import '../components/create_post_sheet.dart';
import '../routing/app_routes.dart';
import '../widgets/glass_surface.dart';
import '../widgets/see_more_content_button.dart';
import '../widgets/audio_post_player.dart';
import '../widgets/reels_preview_carousel.dart';
import '../constants/layout_constants.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
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
    final lockScroll = ref.watch(lockScrollProvider);
    final miniPlayerVisible =
        ref.watch(activeAudioPostUrlProvider)?.isNotEmpty == true;
    final fabBottomPadding = bottomOverlayFabPadding(
      miniPlayerVisible: miniPlayerVisible,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: lockScroll
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: const GlassSurface(
              strong: true,
              borderRadius: BorderRadius.zero,
              child: SizedBox.expand(),
            ),
            title: Text(
              l10n.feed,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: 0,
              ),
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final unread = ref.watch(unreadNotificationCountProvider);
                  final btn = IconButton(
                    tooltip: l10n.notifications,
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.notifications),
                  );
                  if (unread <= 0) return btn;
                  return Badge(
                    label: Text(unread > 99 ? '99+' : '$unread'),
                    child: btn,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: l10n.searchBooks,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.discovery),
              ),
            ],
          ),
          SliverFillRemaining(
            child: PageView.builder(
              physics: lockScroll
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              controller: _pageController,
              itemCount: FeedFilter.values.length,
              onPageChanged: (index) {
                AppHaptics.selection();
              },
              itemBuilder: (context, index) {
                final filter = FeedFilter.values[index];
                return _FeedFilterPage(
                  filter: filter,
                  onFilterSelected: _selectFilter,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: GlassSurface(
          strong: true,
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            showCreatePostSheet(context);
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
      ),
    );
  }
}

class _FeedFilterPage extends ConsumerStatefulWidget {
  const _FeedFilterPage({required this.filter, required this.onFilterSelected});

  final FeedFilter filter;
  final ValueChanged<FeedFilter> onFilterSelected;

  @override
  ConsumerState<_FeedFilterPage> createState() => _FeedFilterPageState();
}

class _FeedFilterPageState extends ConsumerState<_FeedFilterPage> {
  String _selectedType = 'all';
  String? _randomQuestion;

  String? _questionPrompt(List<String> questions) {
    if (questions.isEmpty) return null;
    if (_randomQuestion != null && questions.contains(_randomQuestion)) {
      return _randomQuestion;
    }
    final pool = List<String>.from(questions)..shuffle(math.Random());
    _randomQuestion = pool.first;
    return _randomQuestion;
  }

  void _changeQuestion(List<String> questions) {
    if (questions.isEmpty) return;
    final alternatives = questions
        .where((question) => question != _randomQuestion)
        .toList();
    final pool = alternatives.isEmpty ? questions : alternatives;
    setState(() {
      _randomQuestion = pool[math.Random().nextInt(pool.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedState = ref.watch(pagedFeedPostsProvider(widget.filter));
    final feedController = ref.read(
      pagedFeedPostsProvider(widget.filter).notifier,
    );
    final lockScroll = ref.watch(lockScrollProvider);
    final l10n = AppLocalizations.of(context)!;
    final miniPlayerVisible =
        ref.watch(activeAudioPostUrlProvider)?.isNotEmpty == true;
    final listBottomPadding = bottomOverlayContentPadding(
      miniPlayerVisible: miniPlayerVisible,
    );
    final activeQuestions = widget.filter == FeedFilter.following
        ? (ref.watch(activeQuestionsProvider).value ?? const <String>[])
        : const <String>[];
    final questionPrompt =
        widget.filter == FeedFilter.following && _selectedType == 'all'
        ? _questionPrompt(activeQuestions)
        : null;

    Widget refreshable(Widget child) {
      return RefreshIndicator(onRefresh: feedController.refresh, child: child);
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
            label: l10n.feedTypeQuestion,
            icon: Icons.help_outline_rounded,
            selected: _selectedType == 'question',
            onSelected: () => setState(() => _selectedType = 'question'),
          ),
        ],
      ),
    );

    final feedHeaders = <Widget>[
      _FeedScopeSelector(
        selectedFilter: widget.filter,
        onFilterSelected: widget.onFilterSelected,
      ),
      const ReelsPreviewCarousel(),
      filterChips,
    ];

    Widget centeredScrollable(Widget child) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: lockScroll
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: listBottomPadding),
            children: [
              ...feedHeaders,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(child: child),
                ),
              ),
            ],
          );
        },
      );
    }

    if (feedState.isInitialLoading) {
      return refreshable(centeredScrollable(const CircularProgressIndicator()));
    }
    if (feedState.error != null && feedState.items.isEmpty) {
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

    final failedPostsToShow = ref.watch(failedPostsProvider).where((
      failedItem,
    ) {
      if (_selectedType == 'all') return true;
      if (_selectedType == 'review') return failedItem.post.type == 'review';
      return false;
    }).toList();
    final hasFailedPosts = failedPostsToShow.isNotEmpty;

    Widget body;
    if (feedState.items.isEmpty && !hasFailedPosts) {
      final emptyState = Column(
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
        ],
      );
      if (questionPrompt != null) {
        body = ListView(
          physics: lockScroll
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: listBottomPadding),
          children: [
            ...feedHeaders,
            _QuestionPromptCard(
              question: questionPrompt,
              onChangeQuestion: () => _changeQuestion(activeQuestions),
            ),
            SizedBox(height: 360, child: Center(child: emptyState)),
          ],
        );
      } else {
        body = centeredScrollable(emptyState);
      }
    } else if (items.isEmpty && !hasFailedPosts) {
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
              l10n.feedFilterEmptyTitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feedFilterEmptyBody,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            if (feedState.hasMore)
              SeeMoreContentButton(
                onPressed: feedState.isLoadingMore
                    ? null
                    : feedController.loadMore,
                loading: feedState.isLoadingMore,
              ),
          ],
        ),
      );
    } else {
      final leadingPromptCount = questionPrompt == null ? 0 : 1;
      final int failedCount = failedPostsToShow.length;
      body = ListView.builder(
        physics: lockScroll
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: listBottomPadding),
        itemCount: (items.length + 2 + leadingPromptCount + failedCount)
            .toInt(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: feedHeaders,
            );
          }
          final contentIndex = index - 1;
          if (questionPrompt != null && contentIndex == 0) {
            return _QuestionPromptCard(
              question: questionPrompt,
              onChangeQuestion: () => _changeQuestion(activeQuestions),
            );
          }
          final itemIndex = contentIndex - leadingPromptCount;

          if (itemIndex >= 0 && itemIndex < failedCount) {
            final failedItem = failedPostsToShow[itemIndex];
            return _FailedPostCard(failedItem: failedItem);
          }

          final realItemIndex = (itemIndex - failedCount).toInt();
          if (realItemIndex == items.length) {
            return _LoadMoreFeedButton(
              isLoading: feedState.isLoadingMore,
              hasMore: feedState.hasMore,
              onPressed: feedController.loadMore,
            );
          }
          return FeedPostCard(
            key: ValueKey(items[realItemIndex].id ?? ''),
            post: items[realItemIndex],
            onReplyToQuestion: (post) {
              showCreatePostSheet(
                context,
                initialQuestion: post.question,
                questionLeafId: post.questionLeafId,
                lockQuestion: post.bookId?.toString().trim().isNotEmpty == true,
                bookId: post.bookId?.toString(),
                bookTitle: post.bookTitle,
                bookAuthorName: post.bookAuthorName,
                bookCover: post.bookCover,
              );
            },
          );
        },
      );
    }

    return refreshable(body);
  }
}

class _FeedScopeSelector extends StatelessWidget {
  const _FeedScopeSelector({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final FeedFilter selectedFilter;
  final ValueChanged<FeedFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: GlassControlSurface(
        borderRadius: BorderRadius.circular(26),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
            selected: {selectedFilter},
            onSelectionChanged: (selection) {
              onFilterSelected(selection.first);
            },
          ),
        ),
      ),
    );
  }
}

class _QuestionPromptCard extends StatelessWidget {
  const _QuestionPromptCard({
    required this.question,
    required this.onChangeQuestion,
  });

  final String question;
  final VoidCallback onChangeQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: GlassSurface(
        strong: true,
        borderRadius: BorderRadius.circular(18),
        onTap: () => showCreatePostSheet(
          context,
          initialQuestion: question,
          lockQuestion: false,
        ),
        semanticButton: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.help_outline_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      question,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.tapToAnswerQuestion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: AppLocalizations.of(context)!.viewAllAnswers,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.questionAnswers,
                  arguments: QuestionLeafAnswersQuery(
                    bookId: '',
                    leafId: '',
                    question: question,
                  ),
                ),
                icon: const Icon(Icons.forum_outlined, size: 18),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                tooltip: AppLocalizations.of(context)!.changeQuestion,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                onPressed: onChangeQuestion,
                icon: const Icon(Icons.shuffle_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
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
    if (!hasMore) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SeeMoreContentButton(
          onPressed: isLoading ? null : onPressed,
          loading: isLoading,
        ),
      ),
    );
  }
}

class _FailedPostCard extends ConsumerWidget {
  const _FailedPostCard({required this.failedItem});
  final FailedPost failedItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final post = failedItem.post;

    if (failedItem.isPending) {
      return FeedPostCard(
        key: ValueKey('pending-post-${failedItem.localId}'),
        post: post,
        openOnTap: false,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.failedToPost,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: l10n.close,
                  onPressed: () {
                    ref
                        .read(failedPostsProvider.notifier)
                        .removeFailedPost(failedItem.localId);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (post.bookCover != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      post.bookCover!,
                      width: 32,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.book_rounded, size: 32),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.bookTitle ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post.bookAuthorName ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.rating != null) ...[
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < post.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  post.text,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.errorWithDetails(failedItem.error),
                  style: TextStyle(
                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.retry, style: const TextStyle(fontSize: 12)),
                onPressed: () async {
                  try {
                    await ref
                        .read(failedPostsProvider.notifier)
                        .retryPost(failedItem.localId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.retryFailed(e.toString()))),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
