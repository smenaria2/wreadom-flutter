import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';
import '../providers/message_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final followingAsync = ref.watch(isFollowingProvider(userId));

    return Scaffold(
      body: profileAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(user.displayName ?? user.username),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? Text(
                                  (user.displayName ?? user.username)
                                      .characters
                                      .first
                                      .toUpperCase(),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if ((user.penName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Pen name: ${user.penName}'),
                      ],
                      if ((user.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          user.bio!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Followers',
                            value: '${user.followersCount ?? 0}',
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'Following',
                            value: '${user.followingCount ?? 0}',
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: 'Points',
                            value: '${user.totalPoints ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      followingAsync.when(
                        data: (isFollowing) => Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                final currentUser =
                                    await ref.read(currentUserProvider.future);
                                if (currentUser == null) return;
                                if (isFollowing) {
                                  await ref
                                      .read(followRepositoryProvider)
                                      .unfollowUser(
                                        followerId: currentUser.id,
                                        followingId: user.id,
                                      );
                                } else {
                                  await ref
                                      .read(followRepositoryProvider)
                                      .followUser(
                                        follower: currentUser,
                                        following: user,
                                      );
                                }
                                ref.invalidate(isFollowingProvider(userId));
                                ref.invalidate(publicProfileProvider(userId));
                              },
                              icon: Icon(isFollowing
                                  ? Icons.person_remove_alt_1
                                  : Icons.person_add_alt_1),
                              label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final currentUser =
                                    await ref.read(currentUserProvider.future);
                                if (currentUser == null) return;
                                final conversationId = await ref
                                    .read(messageRepositoryProvider)
                                    .getOrCreateDirectConversation(
                                      currentUser: currentUser,
                                      otherUser: user,
                                    );
                                if (context.mounted) {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.conversation,
                                    arguments: ConversationArguments(
                                      conversationId: conversationId,
                                      title:
                                          user.displayName ?? user.username,
                                      subtitle: '@${user.username}',
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Message'),
                            ),
                          ],
                        ),
                        loading: () =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$value $label'),
      side: BorderSide.none,
      backgroundColor:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
    );
  }
}
