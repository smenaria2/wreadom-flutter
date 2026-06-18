import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/app_haptics.dart';
import '../../domain/models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';
import '../providers/message_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../utils/message_display_utils.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/see_more_content_button.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(pagedConversationsProvider);
    final conversationsController = ref.read(
      pagedConversationsProvider.notifier,
    );
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;
    final isSignedIn = currentUser != null;
    final l10n = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: glassAppBar(title: Text(l10n.messages)),
      body: currentUserAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !isSignedIn
          ? const AuthRequiredView(icon: Icons.chat_bubble_outline_rounded)
          : RefreshIndicator(
              onRefresh: conversationsController.refresh,
              child: Builder(
                builder: (context) {
                  if (conversationsState.isInitialLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (conversationsState.error != null) {
                    return Center(
                      child: Text(
                        l10n.failedToLoadWithError(
                          conversationsState.error.toString(),
                        ),
                      ),
                    );
                  }
                  final conversations = visibleConversations(
                    conversationsState.items,
                    hiddenForUserId: currentUser.id,
                  );
                  if (conversations.isEmpty) {
                    return _EmptyMessagesSuggestions(
                      currentUser: currentUser,
                      emptyMessage: l10n.noConversationsYet,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        conversations.length +
                        (conversationsState.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == conversations.length &&
                          conversationsState.hasMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SeeMoreContentButton(
                              onPressed: conversationsState.isLoadingMore
                                  ? null
                                  : conversationsController.loadMore,
                              loading: conversationsState.isLoadingMore,
                            ),
                          ),
                        );
                      }
                      final conversation = conversations[index];
                      final otherId = conversation.participants.firstWhere(
                        (id) => id != currentUser.id,
                        orElse: () => conversation.participants.first,
                      );
                      final other = conversation.participantDetails[otherId];
                      final title =
                          conversation.name ??
                          other?.displayName ??
                          other?.username ??
                          l10n.conversation;
                      final photoUrl = other?.photoURL?.trim();
                      return _ConversationSwipeShell(
                        onDelete: () async {
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
                          await conversationsController.refresh();
                        },
                        child: GlassSurface(
                          borderRadius: BorderRadius.circular(18),
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
                          semanticButton: true,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? Text(title.characters.first.toUpperCase())
                                  : null,
                            ),
                            title: Text(title),
                            subtitle: Text(
                              conversation.lastMessage?.text ??
                                  l10n.noMessagesYet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyMessagesSuggestions extends ConsumerStatefulWidget {
  const _EmptyMessagesSuggestions({
    required this.currentUser,
    required this.emptyMessage,
  });

  final UserModel currentUser;
  final String emptyMessage;

  @override
  ConsumerState<_EmptyMessagesSuggestions> createState() =>
      _EmptyMessagesSuggestionsState();
}

class _EmptyMessagesSuggestionsState
    extends ConsumerState<_EmptyMessagesSuggestions> {
  int _visibleCount = 5;
  String? _openingUserId;

  @override
  Widget build(BuildContext context) {
    final followingAsync = ref.watch(followingListProvider);
    return followingAsync.when(
      data: (ids) {
        final filteredIds = ids
            .where((id) => id != widget.currentUser.id)
            .toList(growable: false);
        if (filteredIds.isEmpty) {
          return _PlainMessagesEmptyState(message: widget.emptyMessage);
        }
        final profilesAsync = ref.watch(
          publicProfilesByStableIdsProvider(filteredIds.join('|')),
        );
        return profilesAsync.when(
          data: (profiles) {
            if (profiles.isEmpty) {
              return _PlainMessagesEmptyState(message: widget.emptyMessage);
            }
            final visible = profiles.take(_visibleCount).toList();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              children: [
                Text(
                  AppLocalizations.of(context)!.startMessaging,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final profile in visible) ...[
                  GlassSurface(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openingUserId == null
                        ? () => _openConversation(profile)
                        : null,
                    semanticButton: true,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            profile.photoURL?.trim().isNotEmpty == true
                            ? CachedNetworkImageProvider(profile.photoURL!)
                            : null,
                        child: profile.photoURL?.trim().isNotEmpty == true
                            ? null
                            : Text(_profileName(profile).characters.first),
                      ),
                      title: Text(_profileName(profile)),
                      subtitle: Text('@${profile.username}'),
                      trailing: _openingUserId == profile.id
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_visibleCount < profiles.length)
                  Center(
                    child: SeeMoreContentButton(
                      onPressed: () => setState(() => _visibleCount += 5),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _PlainMessagesEmptyState(message: widget.emptyMessage),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _PlainMessagesEmptyState(message: widget.emptyMessage),
    );
  }

  Future<void> _openConversation(UserModel profile) async {
    if (_openingUserId != null) return;
    setState(() => _openingUserId = profile.id);
    try {
      final conversationId = await ref
          .read(messageRepositoryProvider)
          .getOrCreateDirectConversation(
            currentUser: widget.currentUser,
            otherUser: profile,
          );
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRoutes.conversation,
        arguments: ConversationArguments(
          conversationId: conversationId,
          title: _profileName(profile),
          subtitle: profile.username,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToLoadChats(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingUserId = null);
    }
  }

  String _profileName(UserModel profile) {
    for (final value in [
      profile.displayName,
      profile.penName,
      profile.username,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return profile.username;
  }
}

class _PlainMessagesEmptyState extends StatelessWidget {
  const _PlainMessagesEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationSwipeShell extends StatefulWidget {
  const _ConversationSwipeShell({required this.child, required this.onDelete});

  final Widget child;
  final Future<void> Function()? onDelete;

  @override
  State<_ConversationSwipeShell> createState() =>
      _ConversationSwipeShellState();
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
      AppHaptics.selection();
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
      AppHaptics.light();
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
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_sweep_rounded,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.deleteChat,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
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
