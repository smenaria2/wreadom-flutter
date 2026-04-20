import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../../utils/format_utils.dart';
import '../components/generated_book_cover.dart';
import '../providers/auth_providers.dart';
import '../providers/message_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final messages = messagesAsync.asData?.value ?? const <Message>[];
    final conversation = conversationAsync.asData?.value;
    final isBlocked =
        currentUser != null &&
        conversation?.memberStatus[currentUser.id] == 'blocked';
    final waitingForReply =
        currentUser != null &&
        conversation != null &&
        _isWaitingForReply(conversation, messages, currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
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
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded),
                      SizedBox(width: 8),
                      Text('Block User'),
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
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMine = message.senderId == currentUser?.id;
                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _MessageBubble(message: message, isMine: isMine),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load: $error')),
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
                        ? 'You can\'t send messages in this conversation.'
                        : 'The recipient will receive only one message from you unless they reply.',
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty || currentUser == null) return;
                        try {
                          await ref
                              .read(messageRepositoryProvider)
                              .sendMessage(
                                conversationId: widget.conversationId,
                                sender: currentUser,
                                text: text,
                              );
                          _controller.clear();
                        } on MessageLimitException catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
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

  Future<void> _blockOtherUser(
    BuildContext context,
    Conversation conversation,
    String currentUserId,
  ) async {
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block user?'),
        content: const Text(
          'They will no longer be able to send messages in this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
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
    ).showSnackBar(const SnackBar(content: Text('User blocked.')));
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isMine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
