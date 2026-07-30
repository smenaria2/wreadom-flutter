import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_post.dart';
import '../../data/services/analytics_service.dart';
import '../../utils/app_haptics.dart';
import '../../utils/app_link_helper.dart';
import '../components/feed_post_card.dart';
import '../components/create_post_sheet.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/local_comments_notifier.dart';
import '../utils/optimistic_mutation.dart';
import '../routing/app_routes.dart';
import '../widgets/adaptive_banner_ad.dart';
import '../widgets/comment_widgets.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/hindi_input_wrapper.dart';
import 'static_info_screen.dart';

const _postCommentsBannerAdUnitId = 'ca-app-pub-7031076798250177/8829012161';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.preloadedPost,
    this.targetStoryId,
    this.targetCommentId,
    this.targetReplyId,
  });

  final String postId;
  final FeedPost? preloadedPost;
  final String? targetStoryId;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(liveSinglePostProvider(postId));
    final l10n = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(l10n.post),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              await AppHaptics.selection();
              await Share.share(
                l10n.checkOutPostOnWreadom(AppLinkHelper.post(postId)),
                subject: l10n.wreadomPost,
              );
            },
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          final effectivePost = post ?? preloadedPost;
          if (effectivePost == null) {
            return StaticInfoScreen(
              title: 'Content Not Found',
              body: l10n.postNotFoundOrDeleted,
              actionLabel: l10n.searchBooks,
              onAction: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.discovery, arguments: {'query': postId}),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(liveSinglePostProvider(postId));
              ref.invalidate(liveFeedPostCommentsProvider(postId));
            },
            child: ListView(
              children: [
                _TargetStoryCard(
                  post: effectivePost,
                  targetStoryId: targetStoryId,
                ),
                FeedPostCard(
                  key: ValueKey(effectivePost.id ?? ''),
                  post: effectivePost,
                  openOnTap: false,
                  autoPlayAudio: true,
                  onReplyToQuestion: (post) {
                    showCreatePostSheet(
                      context,
                      initialQuestion: post.question,
                      questionLeafId: post.questionLeafId,
                      lockQuestion:
                          post.bookId?.toString().trim().isNotEmpty == true,
                      bookId: post.bookId?.toString(),
                      bookTitle: post.bookTitle,
                      bookAuthorName: post.bookAuthorName,
                      bookCover: post.bookCover,
                    );
                  },
                ),
                GlassSurface(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                  borderRadius: BorderRadius.circular(20),
                  child: _InlineComments(
                    post: effectivePost,
                    targetCommentId: targetCommentId,
                    targetReplyId: targetReplyId,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: AdaptiveBannerAd(
                    adUnitId: _postCommentsBannerAdUnitId,
                    horizontalInset: 32,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => preloadedPost != null
            ? ListView(
                children: [
                  _TargetStoryCard(
                    post: preloadedPost!,
                    targetStoryId: targetStoryId,
                  ),
                  FeedPostCard(
                    key: ValueKey(preloadedPost!.id ?? ''),
                    post: preloadedPost!,
                    openOnTap: false,
                    autoPlayAudio: true,
                    onReplyToQuestion: (post) {
                      showCreatePostSheet(
                        context,
                        initialQuestion: post.question,
                        questionLeafId: post.questionLeafId,
                        lockQuestion:
                            post.bookId?.toString().trim().isNotEmpty == true,
                        bookId: post.bookId?.toString(),
                        bookTitle: post.bookTitle,
                        bookAuthorName: post.bookAuthorName,
                        bookCover: post.bookCover,
                      );
                    },
                  ),
                  GlassSurface(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 18),
                    borderRadius: BorderRadius.circular(20),
                    child: _InlineComments(
                      post: preloadedPost!,
                      targetCommentId: targetCommentId,
                      targetReplyId: targetReplyId,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: AdaptiveBannerAd(
                      adUnitId: _postCommentsBannerAdUnitId,
                      horizontalInset: 32,
                    ),
                  ),
                ],
              )
            : const _PostDetailSkeleton(),
        error: (err, _) =>
            Center(child: Text(l10n.failedToLoadPost(err.toString()))),
      ),
    );
  }
}

StoryImage? selectTargetStoryImage(FeedPost post, String? targetStoryId) {
  final normalizedTarget = targetStoryId?.trim();
  if (normalizedTarget == null || normalizedTarget.isEmpty) return null;
  for (final story in post.images ?? const <StoryImage>[]) {
    if (story.id == normalizedTarget) return story;
  }
  return null;
}

class _TargetStoryCard extends StatelessWidget {
  const _TargetStoryCard({required this.post, required this.targetStoryId});

  final FeedPost post;
  final String? targetStoryId;

  @override
  Widget build(BuildContext context) {
    final story = selectTargetStoryImage(post, targetStoryId);
    if (story == null) return const SizedBox.shrink();
    return Padding(
      key: ValueKey('target-story-${story.id}'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: story.url,
                        fit: BoxFit.contain,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      child: IconButton.filled(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: story.url,
                  height: 360,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox(
                    height: 180,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              if (story.caption?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(story.caption!.trim()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostDetailSkeleton extends StatelessWidget {
  const _PostDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _SkeletonBlock(width: 48, height: 48, radius: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 160, height: 16, color: color),
                  const SizedBox(height: 8),
                  _SkeletonBlock(width: 96, height: 12, color: color),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SkeletonBlock(height: 18, color: color),
        const SizedBox(height: 10),
        _SkeletonBlock(height: 18, color: color),
        const SizedBox(height: 10),
        _SkeletonBlock(width: 220, height: 18, color: color),
        const SizedBox(height: 28),
        _SkeletonBlock(height: 1, color: color),
        const SizedBox(height: 20),
        _SkeletonBlock(width: 140, height: 18, color: color),
        const SizedBox(height: 14),
        _SkeletonBlock(height: 72, radius: 12, color: color),
        const SizedBox(height: 12),
        _SkeletonBlock(height: 72, radius: 12, color: color),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    this.radius = 8,
    required this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _InlineComments extends ConsumerStatefulWidget {
  const _InlineComments({
    required this.post,
    this.targetCommentId,
    this.targetReplyId,
  });

  final FeedPost post;
  final String? targetCommentId;
  final String? targetReplyId;

  @override
  ConsumerState<_InlineComments> createState() => _InlineCommentsState();
}

class _InlineCommentsState extends ConsumerState<_InlineComments>
    with RestorationMixin {
  final _controller = RestorableTextEditingController();
  final _commentFocusNode = FocusNode();
  Comment? _replyingTo;
  bool _submitting = false;

  @override
  String? get restorationId =>
      'post_detail_comments_${widget.post.id ?? 'unknown'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, 'comment_text');
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final postId = widget.post.id;
    final text = _controller.value.text.trim();
    final user = ref.read(currentUserProvider).asData?.value;
    if (postId == null || text.isEmpty) return;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInToContinueAction)));
      return;
    }

    final replyingTo = _replyingTo;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final reply = replyingTo == null
        ? null
        : CommentReply(
            userId: user.id,
            username: user.username,
            displayName: user.displayName,
            penName: user.penName,
            userPhotoURL: user.photoURL,
            text: text,
            timestamp: timestamp,
          );
    final comment = replyingTo == null
        ? Comment(
            userId: user.id,
            username: user.username,
            displayName: user.displayName,
            penName: user.penName,
            userPhotoURL: user.photoURL,
            text: text,
            timestamp: timestamp,
            feedPostId: postId,
          )
        : null;
    final localComments = ref.read(failedCommentsProvider.notifier);
    final localId = localComments.addPendingComment(
      targetId: postId,
      target: FailedCommentTarget.feedPost,
      parentCommentId: replyingTo?.id,
      comment: comment,
      reply: reply,
    );

    _controller.value.clear();
    setState(() {
      _submitting = true;
      _replyingTo = null;
    });

    try {
      if (reply != null) {
        await runOptimisticMutation(
          ref
              .read(feedRepositoryProvider)
              .addCommentReply(postId, replyingTo!.id!, reply),
        );
      } else {
        await runOptimisticMutation(
          ref.read(feedRepositoryProvider).addComment(postId, {
            'userId': user.id,
            'username': user.username,
            'displayName': user.displayName,
            'penName': user.penName,
            'userPhotoURL': user.photoURL,
            'text': text,
          }),
        );
      }
      localComments.removeFailedComment(localId);
      AnalyticsService.logCommentCreate(targetType: 'feed_post');
      await AppHaptics.light();
      ref.invalidate(liveFeedPostCommentsProvider(postId));
      ref.invalidate(liveSinglePostProvider(postId));
      ref.invalidate(feedPostsProvider);
      for (final filter in FeedFilter.values) {
        ref.invalidate(filteredFeedPostsProvider(filter));
        ref.invalidate(pagedFeedPostsProvider(filter));
      }
      ref.invalidate(pagedUserFeedPostsProvider(widget.post.userId));
    } catch (error) {
      localComments.markFailed(localId, error.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSubmittingComment(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post.id;
    if (postId == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(liveFeedPostCommentsProvider(postId));
    final localComments = ref.watch(failedCommentsProvider).where((item) {
      return item.target == FailedCommentTarget.feedPost &&
          item.targetId == postId &&
          item.parentCommentId == null &&
          item.comment != null;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commentsAsync.maybeWhen(
              data: (comments) => l10n.commentsCount(comments.length),
              orElse: () => l10n.comments,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty && localComments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(l10n.noCommentsYet),
                );
              }
              final targetComment = _targetComment(comments);
              final visibleComments = targetComment == null
                  ? comments
                  : comments
                        .where((comment) => comment.id != targetComment.id)
                        .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final localItem in localComments)
                    CommentTile(
                      key: ValueKey(
                        'post-detail-local-comment-${localItem.localId}',
                      ),
                      comment: localItem.comment!,
                      isFailed: !localItem.isPending,
                      onReply: () {},
                      onRetry: () async {
                        try {
                          await ref
                              .read(failedCommentsProvider.notifier)
                              .retryComment(localItem.localId);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.retryFailed(error.toString()),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      onDeleteLocal: () => ref
                          .read(failedCommentsProvider.notifier)
                          .removeFailedComment(localItem.localId),
                    ),
                  if (targetComment != null) ...[
                    _TargetCommentHeader(label: l10n.fromNotifications),
                    CommentTile(
                      key: ValueKey(
                        'post-detail-target-comment-${targetComment.id ?? targetComment.timestamp}',
                      ),
                      comment: targetComment,
                      onReply: () =>
                          setState(() => _replyingTo = targetComment),
                      isTargetComment: true,
                      targetReplyId: widget.targetReplyId,
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final comment in visibleComments)
                    CommentTile(
                      key: ValueKey(
                        'post-detail-comment-${comment.id ?? comment.timestamp}',
                      ),
                      comment: comment,
                      onReply: () => setState(() => _replyingTo = comment),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                Text(l10n.failedToLoadComments(error.toString())),
          ),
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.replyingTo(
                        _replyingTo!.displayName ?? _replyingTo!.username,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HindiInputWrapper(
                  controller: _controller.value,
                  focusNode: _commentFocusNode,
                  inlineButton: true,
                  child: TextField(
                    controller: _controller.value,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _replyingTo == null
                          ? l10n.addAComment
                          : l10n.addAReply,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassSurface(
                strong: true,
                borderRadius: BorderRadius.circular(24),
                onTap: _submit,
                semanticButton: true,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Comment? _targetComment(List<Comment> comments) {
    final targetId = widget.targetCommentId?.trim();
    if (targetId == null || targetId.isEmpty) return null;
    for (final comment in comments) {
      if (comment.id == targetId) return comment;
    }
    return null;
  }
}

class _TargetCommentHeader extends StatelessWidget {
  const _TargetCommentHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
