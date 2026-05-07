import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/format_utils.dart';
import '../components/generated_book_cover.dart';
import '../providers/auth_providers.dart';
import '../providers/message_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/message_display_utils.dart';
import '../utils/swipe_hint.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showSwipeHintOnce(
        context: context,
        key: 'swipe_hint_seen_conversation_v1',
        message: l10n.swipeHintMessages,
        actionLabel: l10n.gotIt,
      );
    });
  }

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
      await ref
          .read(
            pagedConversationMessagesProvider(widget.conversationId).notifier,
          )
          .refresh();
    } on MessageLimitException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
        _isWaitingForReply(conversation, messages, currentUser.id);
    final newDirectThread =
        currentUser != null &&
        conversation != null &&
        conversation.type == 'direct' &&
        conversation.createdBy == currentUser.id &&
        messages.isEmpty;

    return Scaffold(
      appBar: AppBar(
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
                if (messagesState.error != null) {
                  return Center(
                    child: Text(
                      l10n.failedToLoadWithError(
                        messagesState.error.toString(),
                      ),
                    ),
                  );
                }
                if (messages.isEmpty) {
                  return Center(child: Text(l10n.noMessagesYet));
                }
                final hasLoader = messagesState.hasMore;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (hasLoader ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (hasLoader && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: messagesState.isLoadingMore
                                ? null
                                : messagesController.loadMore,
                            icon: messagesState.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.history_rounded),
                            label: Text(l10n.loadMore),
                          ),
                        ),
                      );
                    }
                    final messageIndex = index - (hasLoader ? 1 : 0);
                    final message = messages[messageIndex];
                    final isMine = message.senderId == currentUser?.id;
                    final canDeleteMessage =
                        currentUser != null &&
                        message.id?.trim().isNotEmpty == true &&
                        !_isProtectedFirstMessage(
                          conversation: conversation,
                          message: message,
                          currentUserId: currentUser.id,
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
          if (isBlocked || waitingForReply)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isBlocked
                        ? l10n.cannotSendMessages
                        : l10n.oneMessageAllowed,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (newDirectThread) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.oneMessageAllowed,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
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
                        IconButton(
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: _sending ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isWaitingForReply(
    Conversation conversation,
    List<Message> messages,
    String currentUserId,
  ) {
    if (conversation.type != 'direct' ||
        conversation.createdBy != currentUserId) {
      return false;
    }
    if (messages.isEmpty) return false;
    return !messages.any((message) => message.senderId != currentUserId);
  }

  bool _isProtectedFirstMessage({
    required Conversation? conversation,
    required Message message,
    required String currentUserId,
  }) {
    if (conversation == null || conversation.type != 'direct') return false;
    if (conversation.createdBy != currentUserId) return false;
    if (conversation.lastMessage == null) return false;
    if (message.senderId != currentUserId) return false;
    final hasRecipientReply = messagesStateHasRecipientReply(
      ref.read(pagedConversationMessagesProvider(widget.conversationId)).items,
      currentUserId,
    );
    if (hasRecipientReply) return false;
    return conversation.lastMessage?.senderId == currentUserId &&
        conversation.lastMessage?.timestamp == message.timestamp;
  }

  bool messagesStateHasRecipientReply(
    List<Message> messages,
    String currentUserId,
  ) {
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
                ? NetworkImage(photoUrl!)
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
      HapticFeedback.selectionClick();
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
    HapticFeedback.lightImpact();
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
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: EdgeInsets.only(bottom: bottomMargin),
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
                ? NetworkImage(photoUrl)
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
