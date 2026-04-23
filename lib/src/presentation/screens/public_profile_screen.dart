import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../domain/models/user_model.dart';
import '../widgets/follow_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_providers.dart';
import '../providers/book_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/follow_providers.dart';
import '../providers/message_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../components/book_card.dart';
import '../components/feed_post_card.dart';
import '../components/profile/profile_share_card.dart';
import 'follow_list_screen.dart';
import '../../utils/app_link_helper.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final followingAsync = ref.watch(isFollowingProvider(userId));
    final selfId = ref.watch(currentUserProvider).asData?.value?.id;
    final isSelf = selfId == userId;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: profileAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.userNotFound));
          }
          final theme = Theme.of(context);
          final worksCount = ref
              .watch(userBooksProvider(user.id))
              .maybeWhen(
                data: (books) => books.length,
                orElse: () => user.pinnedWorks?.length ?? 0,
              );
          final level = (user.privacyLevel ?? 'public').toLowerCase();
          final contentVisible =
              isSelf ||
              level == 'public' ||
              (level != 'private' &&
                  (user.email.isNotEmpty || user.pinnedWorks != null));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
                actions: [
                  IconButton(
                    tooltip: l10n.shareProfile,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareProfile(context, user, worksCount),
                  ),
                  if (!isSelf) ...[
                    FollowButton(targetUserId: userId, compact: true),
                    followingAsync.when(
                      data: (isFollowing) {
                        if (isFollowing) {
                          return IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () async {
                              final currentUser = await ref.read(
                                currentUserProvider.future,
                              );
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
                                    title: user.displayName ?? user.username,
                                  ),
                                );
                              }
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    user.displayName ?? user.username,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    child: SafeArea(
                      child: Center(
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: user.photoURL != null
                              ? CachedNetworkImageProvider(user.photoURL!)
                              : null,
                          child: user.photoURL == null
                              ? Text(
                                  (user.displayName ?? user.username)
                                      .characters
                                      .first
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
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
                      if ((user.penName ?? '').isNotEmpty) ...[
                        Text(l10n.penNameValue(user.penName!)),
                      ],
                      if ((user.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          user.bio!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _StatChip(
                            label: l10n.followers,
                            value: '${user.followersCount ?? 0}',
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: userId,
                                mode: FollowListMode.followers,
                                title: l10n.followers,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            label: l10n.following,
                            value: '${user.followingCount ?? 0}',
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.followList,
                              arguments: FollowListArguments(
                                userId: userId,
                                mode: FollowListMode.following,
                                title: l10n.following,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatChip(label: l10n.works, value: '$worksCount'),
                        ],
                      ),
                      if (!isSelf) ...[
                        const SizedBox(height: 16),
                        followingAsync.when(
                          data: (isFollowing) {
                            final level = (user.privacyLevel ?? 'public')
                                .toLowerCase();
                            final followersOnly =
                                level == 'followers' ||
                                level == 'followersonly' ||
                                level == 'followers_only';
                            if (level == 'private') {
                              return _PrivacyNoticeCard(
                                message: l10n.privateAccountNotice,
                                icon: Icons.lock_outline,
                              );
                            }
                            if (followersOnly && !isFollowing) {
                              return _PrivacyNoticeCard(
                                message: l10n.followToSeeFullProfile,
                                icon: Icons.people_outline,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (contentVisible) ...[
                        const SizedBox(height: 28),
                        _PublicProfileContentTabs(userId: userId),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.failedToLoadWithError(error.toString()))),
      ),
    );
  }

  void _shareProfile(BuildContext context, UserModel user, int worksCount) {
    final name = user.displayName ?? user.username;
    shareUserProfileCard(
      context,
      user: user,
      worksCount: worksCount,
      fallbackText: AppLocalizations.of(
        context,
      )!.readWithUserOnWreadom(name, AppLinkHelper.user(user.id)),
    );
  }
}

class _PublicProfileContentTabs extends StatefulWidget {
  const _PublicProfileContentTabs({required this.userId});

  final String userId;

  @override
  State<_PublicProfileContentTabs> createState() =>
      _PublicProfileContentTabsState();
}

class _PublicProfileContentTabsState extends State<_PublicProfileContentTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_index != _controller.index) {
          setState(() => _index = _controller.index);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _controller,
          tabs: [
            Tab(text: l10n.books),
            Tab(text: l10n.posts),
          ],
        ),
        const SizedBox(height: 16),
        if (_index == 0)
          _PublicBooksSection(userId: widget.userId)
        else
          _PublicPostsSection(userId: widget.userId),
      ],
    );
  }
}

class _PrivacyNoticeCard extends StatelessWidget {
  const _PrivacyNoticeCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$value $label'),
      onPressed: onTap,
      side: BorderSide.none,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
    );
  }
}

class _PublicBooksSection extends ConsumerWidget {
  const _PublicBooksSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(userBooksProvider(userId));
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        booksAsync.when(
          data: (books) {
            if (books.isEmpty) {
              return Text(l10n.noPublishedBooksYet);
            }
            return GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 8),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.44,
                crossAxisSpacing: 12,
                mainAxisSpacing: 28,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) =>
                  BookCard(book: books[index], width: double.infinity),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Text(l10n.failedToLoadBooks(error.toString())),
        ),
      ],
    );
  }
}

class _PublicPostsSection extends ConsumerWidget {
  const _PublicPostsSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userFeedPostsProvider(userId));
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.posts,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Text(l10n.noPosts);
            }
            return Column(
              children: [
                for (final post in posts.take(10)) FeedPostCard(post: post),
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text(l10n.failedToLoadPosts(error.toString())),
        ),
      ],
    );
  }
}
