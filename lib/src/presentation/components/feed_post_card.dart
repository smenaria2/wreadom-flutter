import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/feed_post.dart';
import '../../domain/models/comment.dart';
import '../providers/feed_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import '../widgets/comment_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../../utils/app_link_helper.dart';
import '../../utils/format_utils.dart';
import '../utils/notification_writer.dart';
import '../widgets/report_dialog.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

/// Maps post type → accent colour
Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'review':
      return Colors.amber;
    case 'quote':
      return Colors.teal;
    case 'testimony':
      return Colors.pink;
    default:
      return Colors.blue;
  }
}

/// Maps post type → icon
IconData _typeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'review':
      return Icons.star_rounded;
    case 'quote':
      return Icons.format_quote_rounded;
    case 'testimony':
      return Icons.favorite_rounded;
    default:
      return Icons.edit_note_rounded;
  }
}

class FeedPostCard extends ConsumerStatefulWidget {
  final FeedPost post;
  final bool openOnTap;
  const FeedPostCard({super.key, required this.post, this.openOnTap = true});

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _liking = false;
  bool _deleting = false;
  bool _editing = false;
  bool? _optimisticLiked;
  int? _optimisticLikesCount;

  Future<void> _toggleLike() async {
    if (_liking) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null || widget.post.id == null) return;

    final wasLiked = _optimisticLiked ?? widget.post.likes.contains(user.id);
    final prevCount = _optimisticLikesCount ?? widget.post.likes.length;

    setState(() {
      _optimisticLiked = !wasLiked;
      _optimisticLikesCount = wasLiked ? prevCount - 1 : prevCount + 1;
      _liking = true;
    });

    try {
      await ref
          .read(feedRepositoryProvider)
          .toggleLike(widget.post.id!, user.id);
      if (!wasLiked) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          await createAppNotification(
            ref,
            userId: widget.post.userId,
            actor: user,
            type: 'post_like',
            text: l10n.likedYourPost,
            link: AppLinkHelper.post(widget.post.id!),
            targetId: widget.post.id,
            metadata: {'postId': widget.post.id},
          );
        }
      }
      await HapticFeedback.lightImpact();
      // No need to invalidate, optimistic state handles it
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _optimisticLiked = wasLiked;
          _optimisticLikesCount = prevCount;
        });
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetails(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _deletePost() async {
    if (_deleting || widget.post.id == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePostTitle),
        content: Text(l10n.deletePostContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(feedRepositoryProvider).deleteFeedPost(widget.post.id!);
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
      ref.invalidate(userFeedPostsProvider(widget.post.userId));
      ref.invalidate(singlePostProvider(widget.post.id!));

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.postDeleted)));
      if (!widget.openOnTap) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotDeletePost(e.toString()))),
        );
      }
    }
  }

  Future<void> _showEditPostSheet() async {
    final postId = widget.post.id;
    if (_editing || postId == null) return;
    final textController = TextEditingController(text: widget.post.text);
    String? imageUrl = widget.post.imageUrl;
    XFile? pickedImage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final l10n = AppLocalizations.of(context)!;
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.editPost,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  minLines: 3,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n.updateYourPost,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 88,
                        );
                        if (image == null) return;
                        setModalState(() => pickedImage = image);
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        imageUrl == null && pickedImage == null
                            ? l10n.addImage
                            : l10n.replaceImage,
                      ),
                    ),
                    if (imageUrl != null || pickedImage != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            imageUrl = null;
                            pickedImage = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.removeImage),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    setState(() => _editing = true);
                    try {
                      var nextImageUrl = imageUrl;
                      if (pickedImage != null) {
                        final bytes = await pickedImage!.readAsBytes();
                        nextImageUrl = await ref
                            .read(feedRepositoryProvider)
                            .uploadPostImage(bytes, pickedImage!.name);
                      }
                      await ref
                          .read(feedRepositoryProvider)
                          .updateFeedPost(postId, {
                            'text': text,
                            'imageUrl': nextImageUrl,
                            'updatedAt': DateTime.now().millisecondsSinceEpoch,
                          });
                      _invalidateFeed(postId);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        final innerL10n = AppLocalizations.of(this.context)!;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              innerL10n.couldNotDeletePost(e.toString()),
                            ),
                          ), // Using delete error key as generic error for now or add edit error key
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _editing = false);
                    }
                  },
                  icon: _editing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.save),
                ),
              ],
            ),
          );
        },
      ),
    );
    textController.dispose();
  }

  void _invalidateFeed(String postId) {
    ref.invalidate(feedPostsProvider);
    ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
    ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
    ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
    ref.invalidate(userFeedPostsProvider(widget.post.userId));
    ref.invalidate(singlePostProvider(postId));
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _typeColor(post.type);
    final typeLabel = post.type[0].toUpperCase() + post.type.substring(1);

    // Check if current user liked this post (with optimistic override)
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final isOwner = currentUser?.id == post.userId;
    final liked =
        _optimisticLiked ??
        (currentUser != null && post.likes.contains(currentUser.id));
    final likesCount = _optimisticLikesCount ?? post.likes.length;
    final commentsCount = post.commentCount ?? post.comments?.length ?? 0;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // ─── Type accent bar ─────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Author row ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.publicProfile,
                            arguments: PublicProfileArguments(
                              userId: post.userId,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: post.userPhotoURL != null
                                  ? CachedNetworkImageProvider(
                                      post.userPhotoURL!,
                                    )
                                  : null,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: post.userPhotoURL == null
                                  ? Text(
                                      post.username.isNotEmpty
                                          ? post.username[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.displayName ?? post.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    FormatUtils.relativeTime(post.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Post type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _typeIcon(post.type),
                            size: 12,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentUser != null) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: _deleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'report') {
                            showDialog(
                              context: context,
                              builder: (context) => ReportDialog(
                                targetId: post.id!,
                                targetType: 'post',
                              ),
                            );
                          } else if (val == 'delete') {
                            _deletePost();
                          } else if (val == 'edit') {
                            _showEditPostSheet();
                          }
                        },
                        itemBuilder: (context) => [
                          if (isOwner)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(l10n.editPost),
                                ],
                              ),
                            ),
                          if (isOwner)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.deletePostTitle),
                                ],
                              ),
                            )
                          else
                            PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.report_problem_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.reportPost),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),

                // ─── Star rating (review) ─────────────────────────
                if (post.type.toLowerCase() == 'review' &&
                    post.rating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < post.rating!
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ),
                ],

                // ─── Book reference ───────────────────────────────
                if (post.bookTitle != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      if (post.bookId != null) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: BookDetailArguments(
                            bookId: post.bookId.toString(),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          if (post.bookCover != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: post.bookCover!,
                                width: 36,
                                height: 52,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 36,
                                  height: 52,
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.regarding,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  post.bookTitle!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ─── Post text ────────────────────────────────────
                // Italicise quotes
                if (post.type.toLowerCase() == 'quote')
                  _QuoteBlock(text: post.text)
                else
                  Text(
                    post.text,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),

                const SizedBox(height: 10),

                // ─── Post image ───────────────────────────────────
                if (post.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ─── Actions ──────────────────────────────────────
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: liked ? Colors.red : null,
                      label: likesCount.toString(),
                      semanticLabel: liked ? l10n.unlikePost : l10n.likePost,
                      loading: _liking,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 8),
                    // Comment
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: commentsCount.toString(),
                      semanticLabel: l10n.showComments,
                      onTap: () => _showComments(context),
                    ),
                    const Spacer(),
                    // Share
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: l10n.sharePost,
                      color: colorScheme.onSurfaceVariant,
                      onPressed: () {
                        if (post.id != null) {
                          Share.share(
                            l10n.checkOutPostOnWreadom(
                              AppLinkHelper.post(post.id!),
                            ),
                            subject: l10n.wreadomPost,
                          );
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.openOnTap || post.id == null) return card;
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.postDetail,
        arguments: PostDetailArguments(postId: post.id!, post: post),
      ),
      child: card,
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsSheet(post: widget.post),
    );
  }
}

// ─── Quote block ─────────────────────────────────────────────────────────────
class _QuoteBlock extends StatelessWidget {
  final String text;
  const _QuoteBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.teal.withValues(alpha: 0.6), width: 3),
        ),
      ),
      child: Text(
        '"$text"',
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final String semanticLabel;

  const _ActionButton({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.onTap,
    required this.semanticLabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      value: label,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Comments sheet ───────────────────────────────────────────────────────────
class _CommentsSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet>
    with RestorationMixin {
  final _ctrl = RestorableTextEditingController();
  bool _submitting = false;
  Comment? _replyingTo;

  @override
  String? get restorationId => 'feed_comments_${widget.post.id ?? 'unknown'}';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_ctrl, 'comment_text');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _ctrl.value.text.trim();
    if (text.isEmpty || widget.post.id == null) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      if (_replyingTo != null) {
        // Submit a reply
        final reply = CommentReply(
          userId: user.id,
          username: user.username,
          displayName: user.displayName,
          userPhotoURL: user.photoURL,
          text: text,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        if (_replyingTo!.feedPostId != null && _replyingTo!.id != null) {
          await ref
              .read(feedRepositoryProvider)
              .addCommentReply(widget.post.id!, _replyingTo!.id!, reply);
        } else {
          await ref
              .read(commentRepositoryProvider)
              .addReply(_replyingTo!.id!, reply);
        }
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          await createAppNotification(
            ref,
            userId: _replyingTo!.userId,
            actor: user,
            type: 'feed_reply',
            text: l10n.repliedToYourComment,
            link: AppLinkHelper.post(widget.post.id!),
            targetId: widget.post.id,
            metadata: {'postId': widget.post.id, 'commentId': _replyingTo!.id},
          );
        }
      } else {
        // Submit a top-level comment
        await ref.read(feedRepositoryProvider).addComment(widget.post.id!, {
          'userId': user.id,
          'username': user.username,
          'displayName': user.displayName,
          'userPhotoURL': user.photoURL,
          'text': text,
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          await createAppNotification(
            ref,
            userId: widget.post.userId,
            actor: user,
            type: 'feed_comment',
            text: l10n.commentedOnYourPost,
            link: AppLinkHelper.post(widget.post.id!),
            targetId: widget.post.id,
            metadata: {'postId': widget.post.id},
          );
        }
      }

      ref.invalidate(feedPostCommentsProvider(widget.post.id!));
      ref.invalidate(singlePostProvider(widget.post.id!));
      ref.invalidate(feedPostsProvider);
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.following));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.public));
      ref.invalidate(filteredFeedPostsProvider(FeedFilter.mine));
      await HapticFeedback.lightImpact();
      _ctrl.value.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSubmittingComment(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final commentsAsync = ref.watch(feedPostCommentsProvider(widget.post.id!));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 12, 0, bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              commentsAsync.when(
                data: (comments) => l10n.commentsCount(comments.length),
                loading: () => l10n.commentsLoading,
                error: (_, _) => l10n.comments,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        l10n.noCommentsYet,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, i) {
                    final c = comments[i];
                    return CommentTile(
                      comment: c,
                      onReply: () {
                        setState(() => _replyingTo = c);
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(l10n.errorLoadingComments(e.toString())),
                ),
              ),
            ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.replyingTo(
                        _replyingTo!.displayName ?? _replyingTo!.username,
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          // Comment input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl.value,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? l10n.addAReply
                          : l10n.addAComment,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  onPressed: _submitting ? null : _submitComment,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
