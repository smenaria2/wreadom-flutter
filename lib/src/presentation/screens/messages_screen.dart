import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Text('No conversations yet. Start from a user profile.'),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherId = conversation.participants.firstWhere(
                (id) => id != currentUser?.id,
                orElse: () => conversation.participants.first,
              );
              final other = conversation.participantDetails[otherId];
              final title = conversation.name ??
                  other?.displayName ??
                  other?.username ??
                  'Conversation';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(title.characters.first.toUpperCase()),
                ),
                title: Text(title),
                subtitle: Text(
                  conversation.lastMessage?.text ?? 'No messages yet',
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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}
