import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/app_haptics.dart';
import '../../utils/format_utils.dart';
import '../components/generated_book_cover.dart';
import '../providers/auth_providers.dart';
import '../providers/message_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/error_message_utils.dart';
import '../utils/message_display_utils.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/see_more_content_button.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.subtitle,
  });

  final String conversationId;
  final String title;
  final String? subtitle;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final text = _controller.text.trim();
    final currentUser = ref.read(currentUserProvider).asData?.value;
    if (text.isEmpty || currentUser == null) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(messageRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            sender: currentUser,
            text: text,
          );
      _controller.clear();
    } on MessageLimitException {
      // The composer state already reflects blocked/first-message limits.
    } catch (error, stackTrace) {
      logUiError('Message send failed', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingErrorMessage(AppLocalizations.of(context)!, error),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesState = ref.watch(
      pagedConversationMessagesProvider(widget.conversationId),
    );
    final messagesController = ref.read(
      pagedConversationMessagesProvider(widget.conversationId).notifier,
    );
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final messages = messagesState.items;
    final conversation = conversationAsync.asData?.value;
    final otherUserId =
        conversation != null &&
            currentUser != null &&
            conversation.type == 'direct'
        ? conversation.participants.firstWhere(
            (id) => id != currentUser.id,
            orElse: () => '',
          )
        : '';
    final otherUser = otherUserId.isEmpty
        ? null
        : conversation?.participantDetails[otherUserId];
    final isBlocked =
        currentUser != null &&
        conversation?.memberStatus[currentUser.id] == 'blocked';
    final waitingForReply =
        currentUser != null &&
        conversation != null &&
        _isWaitingForReply(conversation, currentUser.id, messages);
    final newDirectThread =
        currentUser != null &&
        conversation != null &&
        conversation.type == 'direct' &&
        conversation.createdBy == currentUser.id &&
        conversation.firstMessageSenderId == null;

    return GlassScaffold(
      appBar: glassAppBar(
        title: _ConversationTitle(
          title: widget.title,
          subtitle: widget.subtitle,
          userId: otherUserId,
          photoUrl: otherUser?.photoURL,
        ),
        actions: [
          if (conversation != null &&
              currentUser != null &&
              conversation.type == 'direct')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  _blockOtherUser(context, conversation, currentUser.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded),
                      const SizedBox(width: 8),
                      Text(l10n.blockUser),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (messagesState.isInitialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (messagesState.error != null && messages.isEmpty) {
                  return Center(
                    child: _ConversationLoadError(
                      onRetry: messagesController.refresh,
                    ),
                  );
                }
                if (messages.isEmpty) {
                  if (newDirectThread) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ConversationInfoMessage(text: l10n.oneMessageAllowed),
                      ],
                    );
                  }
                  return Center(child: Text(l10n.noMessagesYet));
                }
                final hasLoader = messagesState.hasMore;
                final hasWaitingNotice = waitingForReply;
                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      messages.length +
                      (hasLoader ? 1 : 0) +
                      (hasWaitingNotice ? 1 : 0) +
                      (messagesState.error != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (messagesState.error != null && index == 0) {
                      return _LiveUpdateWarning(
                        onRetry: messagesController.retryLiveUpdates,
                      );
                    }
                    final errorOffset = messagesState.error != null ? 1 : 0;
                    index -= errorOffset;
                    if (hasLoader && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: SeeMoreContentButton(
                            onPressed: messagesState.isLoadingMore
                                ? null
                                : messagesController.loadMore,
                            loading: messagesState.isLoadingMore,
                          ),
                        ),
                      );
                    }
                    final noticeIndex = hasLoader ? 1 : 0;
                    if (hasWaitingNotice && index == noticeIndex) {
                      return _ConversationInfoMessage(
                        text: l10n.oneMessageAllowed,
                      );
                    }
                    final messageIndex =
                        index -
                        (hasLoader ? 1 : 0) -
                        (hasWaitingNotice ? 1 : 0);
                    final message = messages[messageIndex];
                    final isMine = message.senderId == currentUser?.id;
                    final canDeleteMessage =
                        currentUser != null &&
                        message.id?.trim().isNotEmpty == true &&
                        !_isProtectedFirstMessage(
                          conversation: conversation,
                          message: message,
                          currentUserId: currentUser.id,
                          messages: messages,
                        );
                    final placement = messageGroupPlacement(
                      messages,
                      messageIndex,
                    );
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _MessageSwipeShell(
                        enabled: canDeleteMessage,
                        onDelete: () async {
                          final messageId = message.id;
                          if (currentUser == null || messageId == null) {
                            return;
                          }
                          try {
                            await ref
                                .read(messageRepositoryProvider)
                                .deleteMessage(
                                  conversationId: widget.conversationId,
                                  messageId: messageId,
                                  userId: currentUser.id,
                                );
                            await messagesController.refresh();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.failedToLoadWithError(error.toString()),
                                ),
                              ),
                            );
                          }
                        },
                        child: _MessageBubble(
                          message: message,
                          isMine: isMine,
                          showSender: placement.startsGroup,
                          bottomMargin: placement.continuesGroup ? 4 : 10,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (isBlocked)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassSurface(
                  strong: true,
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(16),
                  child: Text(
                    l10n.cannotSendMessages,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            )
          else if (waitingForReply)
            const SizedBox.shrink()
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassSurface(
                  strong: true,
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: l10n.messageHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            onPressed: _sending ? null : _sendMessage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isWaitingForReply(
    Conversation conversation,
    String currentUserId,
    List<Message> messages,
  ) {
    if (conversation.type != 'direct' ||
        conversation.createdBy != currentUserId) {
      return false;
    }
    if (_hasLoadedRecipientReply(conversation, currentUserId, messages)) {
      return false;
    }
    return conversation.firstMessageSenderId == currentUserId &&
        !conversation.recipientHasReplied;
  }

  bool _isProtectedFirstMessage({
    required Conversation? conversation,
    required Message message,
    required String currentUserId,
    required List<Message> messages,
  }) {
    if (conversation == null || conversation.type != 'direct') return false;
    if (conversation.createdBy != currentUserId) return false;
    if (message.senderId != currentUserId) return false;
    if (_hasLoadedRecipientReply(conversation, currentUserId, messages)) {
      return false;
    }
    return conversation.firstMessageSenderId == currentUserId &&
        !conversation.recipientHasReplied;
  }

  bool _hasLoadedRecipientReply(
    Conversation conversation,
    String currentUserId,
    List<Message> messages,
  ) {
    if (conversation.recipientHasReplied) return true;
    return messages.any((message) => message.senderId != currentUserId);
  }

  Future<void> _blockOtherUser(
    BuildContext context,
    Conversation conversation,
    String currentUserId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockUserTitle),
        content: Text(l10n.blockUserBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(messageRepositoryProvider)
        .blockUserInConversation(
          conversationId: conversation.id,
          blockedUserId: otherUserId,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.userBlocked)));
  }
}

class _ConversationInfoMessage extends StatelessWidget {
  const _ConversationInfoMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

class _ConversationLoadError extends StatelessWidget {
  const _ConversationLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.somethingWentWrong),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.tryAgain),
        ),
      ],
    );
  }
}

class _LiveUpdateWarning extends StatelessWidget {
  const _LiveUpdateWarning({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          dense: true,
          leading: Icon(
            Icons.sync_problem_rounded,
            color: colorScheme.onErrorContainer,
          ),
          title: Text(
            l10n.somethingWentWrong,
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          trailing: TextButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
        ),
      ),
    );
  }
}

class _ConversationTitle extends StatelessWidget {
  const _ConversationTitle({
    required this.title,
    required this.subtitle,
    required this.userId,
    required this.photoUrl,
  });

  final String title;
  final String? subtitle;
  final String userId;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final canOpenProfile = userId.trim().isNotEmpty;
    final content = Row(
      children: [
        if (canOpenProfile) ...[
          CircleAvatar(
            radius: 17,
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(photoUrl!)
                : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? Text(title.characters.first.toUpperCase())
                : null,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );

    if (!canOpenProfile) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.publicProfile,
        arguments: PublicProfileArguments(userId: userId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      ),
    );
  }
}

class _MessageSwipeShell extends StatefulWidget {
  const _MessageSwipeShell({
    required this.child,
    required this.enabled,
    required this.onDelete,
  });

  final Widget child;
  final bool enabled;
  final Future<void> Function() onDelete;

  @override
  State<_MessageSwipeShell> createState() => _MessageSwipeShellState();
}

class _MessageSwipeShellState extends State<_MessageSwipeShell> {
  static const double _threshold = 64;
  static const double _maxSlide = 88;

  double _dragOffset = 0;
  bool _hapticArmed = false;
  bool _deleting = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || _deleting) return;
    final next = (_dragOffset + (details.primaryDelta ?? 0)).clamp(
      -_maxSlide,
      0,
    );
    final crossed = next.abs() >= _threshold;
    if (crossed && !_hapticArmed) {
      AppHaptics.selection();
      _hapticArmed = true;
    } else if (!crossed) {
      _hapticArmed = false;
    }
    setState(() => _dragOffset = next.toDouble());
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    final shouldDelete = _dragOffset <= -_threshold;
    setState(() {
      _dragOffset = 0;
      _hapticArmed = false;
    });
    if (!shouldDelete || _deleting) return;
    await _delete();
  }

  Future<void> _confirmDelete() async {
    if (!widget.enabled || _deleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteActionUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    AppHaptics.light();
    setState(() => _deleting = true);
    try {
      await widget.onDelete();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _dragOffset.abs() > 8 ? 1 : 0,
              duration: const Duration(milliseconds: 90),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: () => setState(() {
              _dragOffset = 0;
              _hapticArmed = false;
            }),
            onLongPress: _confirmDelete,
            child: AnimatedContainer(
              duration: _dragOffset == 0
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showSender,
    required this.bottomMargin,
  });

  final Message message;
  final bool isMine;
  final bool showSender;
  final double bottomMargin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMine
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.78)
        : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.72);

    return GlassSurface(
      margin: EdgeInsets.only(bottom: bottomMargin),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSender) ...[
              _MessageSender(message: message),
              const SizedBox(height: 6),
            ],
            if (message.type == 'story' && message.storyData != null)
              _StoryMessageCard(story: message.storyData!)
            else
              Text(message.text ?? ''),
            const SizedBox(height: 5),
            Text(
              FormatUtils.relativeTime(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageSender extends StatelessWidget {
  const _MessageSender({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final photoUrl = message.senderPhotoURL;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.publicProfile,
        arguments: PublicProfileArguments(userId: message.senderId),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? Text(
                    _initial(message.senderName),
                    style: const TextStyle(fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message.senderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}

class _StoryMessageCard extends StatelessWidget {
  const _StoryMessageCard({required this.story});

  final MessageStoryData story;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.bookDetail,
        arguments: BookDetailArguments(bookId: story.id),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 70,
              child: story.coverUrl != null && story.coverUrl!.isNotEmpty
                  ? Image.network(story.coverUrl!, fit: BoxFit.cover)
                  : GeneratedBookCover(
                      title: story.title,
                      author: story.authorNames,
                      seed: story.id,
                      borderRadius: 8,
                      compact: true,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  story.authorNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
