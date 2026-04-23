import 'package:flutter/material.dart';
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
              return ListTile(
                leading: CircleAvatar(
                  child: Text(title.characters.first.toUpperCase()),
                ),
                title: Text(title),
                subtitle: Text(
                  conversation.lastMessage?.text ?? l10n.noMessagesYet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: l10n.deleteChat,
                  onPressed: currentUser == null
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
