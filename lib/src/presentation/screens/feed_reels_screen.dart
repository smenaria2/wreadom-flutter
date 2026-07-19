import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/services/analytics_service.dart';
import '../../domain/models/feed_post.dart';
import '../../localization/generated/app_localizations.dart';
import '../../utils/app_haptics.dart';
import '../../utils/app_link_helper.dart';
import '../../utils/image_proxy_utils.dart';
import '../components/feed_post_card.dart';
import '../components/reel_post_content.dart';
import '../providers/theme_provider.dart';
import '../utils/optimistic_mutation.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import '../widgets/audio_post_player.dart';
import '../widgets/report_dialog.dart';

final Set<String> _reelGuideShownForSession = <String>{};

class FeedReelsScreen extends ConsumerStatefulWidget {
  const FeedReelsScreen({super.key});

  @override
  ConsumerState<FeedReelsScreen> createState() => _FeedReelsScreenState();
}

class _FeedReelsScreenState extends ConsumerState<FeedReelsScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  int _activeIndex = 0;

  bool _showSwipeGuide = false;
  String? _guideSessionKey;
  final Map<String, bool> _liked = <String, bool>{};
  final Map<String, int> _likeCounts = <String, int>{};
  final Set<String> _liking = <String>{};
  String? _heartPostId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: .96);
    AnalyticsService.logEvent('feed_reel_open');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPlayback();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stopPlayback();
  }

  void _stopPlayback() {
    ref.read(activeAudioPostUrlProvider.notifier).setActiveUrl(null);
  }

  void _syncSwipeGuideFor(String sessionKey) {
    if (_guideSessionKey == sessionKey) return;
    _guideSessionKey = sessionKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _guideSessionKey != sessionKey) return;
      setState(() {
        _showSwipeGuide = _reelGuideShownForSession.add(sessionKey);
      });
    });
  }

  void _onPageChanged(int index, List<FeedPost> posts) {
    _stopPlayback();
    setState(() {
      _activeIndex = index;
    });
    AppHaptics.selection();
    if (index < posts.length) {
      AnalyticsService.logEvent(
        'feed_reel_view',
        parameters: {'post_id': posts[index].id ?? '', 'position': index},
      );
    }
    if (index >= posts.length - 3) {
      ref.read(pagedFeedPostsProvider(FeedFilter.public).notifier).loadMore();
    }
  }

  Future<void> _toggleLike(FeedPost post, {bool showHeart = false}) async {
    final postId = post.id;
    if (postId == null || _liking.contains(postId)) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.signInToContinueAction),
          ),
        );
      }
      return;
    }

    final wasLiked = _liked[postId] ?? post.likes.contains(user.id);
    final oldCount =
        _likeCounts[postId] ?? post.likesCount ?? post.likes.length;
    setState(() {
      _liking.add(postId);
      _liked[postId] = !wasLiked;
      _likeCounts[postId] = math.max(0, oldCount + (wasLiked ? -1 : 1));
      if (showHeart && !wasLiked) _heartPostId = postId;
    });
    if (showHeart && !wasLiked) {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (mounted && _heartPostId == postId) {
          setState(() => _heartPostId = null);
        }
      });
    }

    try {
      await runOptimisticMutation(
        ref.read(feedRepositoryProvider).toggleLike(postId, user.id),
      );
      AnalyticsService.logEvent(
        wasLiked ? 'feed_reel_unlike' : 'feed_reel_like',
        parameters: {'post_id': postId},
      );
      await AppHaptics.light();
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked[postId] = wasLiked;
          _likeCounts[postId] = oldCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.somethingWentWrong),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _liking.remove(postId));
    }
  }

  Future<void> _share(FeedPost post) async {
    if (post.id == null) return;
    AnalyticsService.logEvent(
      'feed_reel_share',
      parameters: {'post_id': post.id!},
    );
    await Share.share(AppLinkHelper.post(post.id!));
  }

  Future<void> _showMoreActions(
    BuildContext context,
    WidgetRef ref,
    FeedPost post,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.read(currentUserProvider).asData?.value;
    final isOwner = currentUser?.id == post.userId;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.editPost),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (post.id == null) return;
                  Navigator.of(context).pushNamed(
                    AppRoutes.postDetail,
                    arguments: PostDetailArguments(
                      postId: post.id!,
                      post: post,
                    ),
                  );
                },
              ),
            if (isOwner)
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(l10n.deletePostTitle),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.deletePostTitle),
                      content: Text(l10n.deletePostContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || post.id == null) return;
                  await ref
                      .read(feedRepositoryProvider)
                      .deleteFeedPost(post.id!);
                  for (final filter in FeedFilter.values) {
                    ref
                        .read(pagedFeedPostsProvider(filter).notifier)
                        .removePost(post.id!);
                  }
                },
              )
            else
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.redAccent,
                ),
                title: Text(
                  l10n.reportPost,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (post.id == null) return;
                  showDialog<void>(
                    context: context,
                    builder: (_) =>
                        ReportDialog(targetId: post.id!, targetType: 'post'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pagedFeedPostsProvider(FeedFilter.public));
    final controller = ref.read(
      pagedFeedPostsProvider(FeedFilter.public).notifier,
    );
    final posts = state.items;
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    _syncSwipeGuideFor(currentUser?.id ?? 'guest');

    return PopScope(
      onPopInvokedWithResult: (_, _) => _stopPlayback(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: _BookBackdrop()),
            if (state.isInitialLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null && posts.isEmpty)
              _ReelMessage(
                icon: Icons.cloud_off_rounded,
                title: l10n.somethingWentWrong,
                actionLabel: l10n.tryAgain,
                onAction: controller.refresh,
              )
            else if (posts.isEmpty)
              _ReelMessage(
                icon: Icons.auto_stories_outlined,
                title: l10n.noPosts,
                actionLabel: l10n.tryAgain,
                onAction: controller.refresh,
              )
            else
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index) => _onPageChanged(index, posts),
                itemCount: posts.length,
                itemBuilder: (context, index) => AnimatedSlide(
                  offset: index == _activeIndex
                      ? Offset.zero
                      : const Offset(0, .045),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: index == _activeIndex ? 1 : .935,
                    duration: const Duration(milliseconds: 560),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: index == _activeIndex ? 1 : .68,
                      duration: const Duration(milliseconds: 360),
                      child: _ReelPage(
                        key: PageStorageKey('reel-${posts[index].id}'),
                        post: posts[index],
                        isActive: index == _activeIndex,
                        liked:
                            _liked[posts[index].id] ??
                            (ref.watch(currentUserProvider).asData?.value !=
                                    null &&
                                posts[index].likes.contains(
                                  ref
                                      .watch(currentUserProvider)
                                      .asData!
                                      .value!
                                      .id,
                                )),
                        likeCount:
                            _likeCounts[posts[index].id] ??
                            posts[index].likesCount ??
                            posts[index].likes.length,
                        liking: false,
                        showHeart: _heartPostId == posts[index].id,
                        onLike: () => _toggleLike(posts[index]),
                        onDoubleTap: () =>
                            _toggleLike(posts[index], showHeart: true),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showSwipeGuide && _activeIndex == 0 && posts.isNotEmpty)
              Positioned(
                left: 30,
                right: 30,
                bottom: MediaQuery.paddingOf(context).bottom + 205,
                child: _SwipeGuide(
                  onDismiss: () {
                    setState(() {
                      _showSwipeGuide = false;
                    });
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    _TopButton(
                      icon: Icons.close_rounded,
                      label: l10n.closeReelFeed,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (posts.isNotEmpty && _activeIndex < posts.length) ...[
                      _TopButton(
                        icon: Icons.share_outlined,
                        label: l10n.share,
                        onPressed: () => _share(posts[_activeIndex]),
                      ),
                      const SizedBox(width: 8),
                      _TopButton(
                        icon: Icons.more_horiz_rounded,
                        label: l10n.moreActions,
                        onPressed: () =>
                            _showMoreActions(context, ref, posts[_activeIndex]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends ConsumerWidget {
  const _ReelPage({
    super.key,
    required this.post,
    required this.isActive,
    required this.liked,
    required this.likeCount,
    required this.liking,
    required this.showHeart,
    required this.onLike,
    required this.onDoubleTap,
  });

  final FeedPost post;
  final bool isActive;
  final bool liked;
  final int likeCount;
  final bool liking;
  final bool showHeart;
  final VoidCallback onLike;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final postId = post.id;
    final latestComment = isActive && postId != null
        ? ref.watch(latestFeedPostCommentProvider(postId))
        : const AsyncValue.data(null);
    final commentCount = post.commentCount ?? post.comments?.length ?? 0;

    return Semantics(
      label:
          '${post.displayName ?? post.penName ?? post.username}. ${l10n.reelSwipeHint}',
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.paddingOf(context).top + 58,
          8,
          8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, const Color(0xFF080808)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ReelPostContent(
                    key: ValueKey('reel-content-${post.id}-$isActive'),
                    post: post,
                    isActive: isActive,
                    onDoubleTapLike: onDoubleTap,
                    onBookTap: post.bookId == null
                        ? null
                        : () => Navigator.of(context).pushNamed(
                            AppRoutes.bookDetail,
                            arguments: BookDetailArguments(
                              bookId: post.bookId.toString(),
                            ),
                          ),
                    onQuestionTap: post.question?.trim().isNotEmpty == true
                        ? () => Navigator.of(context).pushNamed(
                            AppRoutes.questionAnswers,
                            arguments: QuestionLeafAnswersQuery(
                              bookId: post.bookId?.toString() ?? '',
                              leafId: post.questionLeafId ?? '',
                              question: post.question!,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ReelOverlay(
                    post: post,
                    latestComment: latestComment,
                    liked: liked,
                    likeCount: likeCount,
                    commentCount: commentCount,
                    liking: liking,
                    onLike: onLike,
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: AnimatedScale(
                      scale: showHeart ? 1 : .4,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: AnimatedOpacity(
                        opacity: showHeart ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.redAccent,
                          size: 104,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: scheme.primary.withValues(alpha: .18),
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

class _ReelOverlay extends ConsumerWidget {
  const _ReelOverlay({
    required this.post,
    required this.latestComment,
    required this.liked,
    required this.likeCount,
    required this.commentCount,
    required this.liking,
    required this.onLike,
  });
  final FeedPost post;
  final AsyncValue<dynamic> latestComment;
  final bool liked;
  final int likeCount;
  final int commentCount;
  final bool liking;
  final VoidCallback onLike;

  void _comments(BuildContext context) {
    AnalyticsService.logEvent(
      'feed_reel_comments_open',
      parameters: {'post_id': post.id ?? ''},
    );
    showFeedPostCommentsSheet(context, post, darkReel: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final comment = latestComment.asData?.value;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 30, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: .94),
            Colors.black,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _comments(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        comment == null
                            ? l10n.beFirstToComment
                            : '${comment.displayName ?? comment.penName ?? comment.username}: ${comment.text}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors
                              .white70, // Explicitly styled for legibility on dark backdrop
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.publicProfile,
                      arguments: PublicProfileArguments(userId: post.userId),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: post.userPhotoURL == null
                                ? null
                                : CachedNetworkImageProvider(
                                    optimizedImageUrl(
                                      post.userPhotoURL!,
                                      width: 100,
                                      height: 100,
                                      fit: 'cover',
                                    ),
                                  ),
                            child: post.userPhotoURL == null
                                ? Text(
                                    post.username.isEmpty
                                        ? '?'
                                        : post.username[0].toUpperCase(),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              post.displayName ?? post.penName ?? post.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors
                                    .white, // Explicitly styled for legibility on dark backdrop
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _OverlayAction(
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.redAccent : null,
                  label: '$likeCount',
                  loading: liking,
                  onTap: onLike,
                ),
                _OverlayAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$commentCount',
                  onTap: () => _comments(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayAction extends StatelessWidget {
  const _OverlayAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 52,
      child: InkResponse(
        onTap: loading ? null : onTap,
        radius: 26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 24, color: color ?? Colors.white),
            if (label.isNotEmpty)
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black.withValues(alpha: .55),
          side: BorderSide(color: Colors.white.withValues(alpha: .35)),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _ReelMessage extends StatelessWidget {
  const _ReelMessage({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _BookBackdrop extends StatelessWidget {
  const _BookBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}

class _SwipeGuide extends StatelessWidget {
  const _SwipeGuide({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swipe Instruction
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swipe_left_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.reelSwipeHint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Double Tap Instruction
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.reelDoubleTapHint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Got it button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.gotIt,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
