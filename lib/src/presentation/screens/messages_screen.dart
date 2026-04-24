import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../providers/auth_providers.dart';
import '../providers/message_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider).asData?.value;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.messages)),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(child: Text(l10n.noConversationsYet));
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherId = conversation.participants.firstWhere(
                (id) => id != currentUser?.id,
                orElse: () => conversation.participants.first,
              );
              final other = conversation.participantDetails[otherId];
              final title =
                  conversation.name ??
                  other?.displayName ??
                  other?.username ??
                  l10n.conversation;
              return _ConversationSwipeShell(
                onDelete: currentUser == null
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deleteChatTitle),
                            content: Text(l10n.deleteConversationBody),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await ref
                            .read(messageRepositoryProvider)
                            .deleteConversationForUser(
                              conversationId: conversation.id,
                              userId: currentUser.id,
                            );
                        ref.invalidate(conversationsProvider);
                      },
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(title.characters.first.toUpperCase()),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    conversation.lastMessage?.text ?? l10n.noMessagesYet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.conversation,
                      arguments: ConversationArguments(
                        conversationId: conversation.id,
                        title: title,
                        subtitle: other?.username,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.failedToLoadWithError(error.toString()))),
      ),
    );
  }
}

class _ConversationSwipeShell extends StatefulWidget {
  const _ConversationSwipeShell({
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final Future<void> Function()? onDelete;

  @override
  State<_ConversationSwipeShell> createState() => _ConversationSwipeShellState();
}

class _ConversationSwipeShellState extends State<_ConversationSwipeShell> {
  static const double _threshold = 72;
  static const double _maxSlide = 96;

  double _dragOffset = 0;
  bool _hapticArmed = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.onDelete == null) return;
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
    final offset = _dragOffset;
    setState(() {
      _dragOffset = 0;
      _hapticArmed = false;
    });
    if (offset <= -_threshold) {
      HapticFeedback.lightImpact();
      await widget.onDelete?.call();
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
                  child: _ConversationActionChip(),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: () => setState(() {
              _dragOffset = 0;
              _hapticArmed = false;
            }),
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

class _ConversationActionChip extends StatelessWidget {
  const _ConversationActionChip();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_sweep_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.deleteChat,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
