import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../../domain/models/user_model.dart';

import '../providers/follow_providers.dart';
import '../providers/profile_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/follow_button.dart';

enum FollowListMode { followers, following }

class FollowListArguments {
  const FollowListArguments({
    required this.userId,
    required this.mode,
    required this.title,
  });

  final String userId;
  final FollowListMode mode;
  final String title;
}

class FollowListScreen extends ConsumerStatefulWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.mode,
    required this.title,
  });

  final String userId;
  final FollowListMode mode;
  final String title;

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = FollowListQuery(
      userId: widget.userId,
      type: widget.mode == FollowListMode.followers
          ? FollowListType.followers
          : FollowListType.following,
    );
    final followState = ref.watch(pagedFollowListProvider(query));
    final followController = ref.read(pagedFollowListProvider(query).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Builder(
        builder: (context) {
          if (followState.isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (followState.error != null) {
            return Center(
              child: Text(
                l10n.failedToLoadTitle(
                  widget.title,
                  followState.error.toString(),
                ),
              ),
            );
          }
          if (followState.items.isEmpty) {
            return Center(
              child: Text(l10n.noFollowersYet(widget.title.toLowerCase())),
            );
          }

          final profilesKey = followState.items.join('|');
          final profilesAsync = ref.watch(
            publicProfilesByStableIdsProvider(profilesKey),
          );

          return profilesAsync.when(
            data: (profiles) => ListView.separated(
              itemCount: profiles.length + (followState.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == profiles.length && followState.hasMore) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: followState.isLoadingMore
                            ? null
                            : followController.loadMore,
                        icon: followState.isLoadingMore
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_rounded),
                        label: Text(l10n.loadMore),
                      ),
                    ),
                  );
                }
                return _FollowUserTile(user: profiles[index]);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                l10n.failedToLoadTitle(widget.title, error.toString()),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName?.trim();
    final penName = user.penName?.trim();
    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : penName != null && penName.isNotEmpty
        ? penName
        : user.username;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoURL != null
            ? CachedNetworkImageProvider(user.photoURL!)
            : null,
        child: user.photoURL == null && name.isNotEmpty
            ? Text(name.characters.first.toUpperCase())
            : null,
      ),
      title: Text(name),
      trailing: FollowButton(targetUserId: user.id, compact: true),
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.publicProfile,
        arguments: PublicProfileArguments(userId: user.id),
      ),
    );
  }
}
