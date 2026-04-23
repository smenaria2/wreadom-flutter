import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

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
  int _limit = 20;
  static const int _increment = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final idsAsync = widget.mode == FollowListMode.followers
        ? ref.watch(userFollowersListProvider(widget.userId))
        : ref.watch(userFollowingListProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: idsAsync.when(
        data: (ids) {
          if (ids.isEmpty) {
            return Center(
              child: Text(l10n.noFollowersYet(widget.title.toLowerCase())),
            );
          }

          final displayCount = (_limit < ids.length) ? _limit : ids.length;
          final hasMore = _limit < ids.length;

          return ListView.separated(
            itemCount: displayCount + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == displayCount && hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _limit += _increment),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.loadMore),
                    ),
                  ),
                );
              }
              return _FollowUserTile(userId: ids[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(l10n.failedToLoadTitle(widget.title, error.toString())),
        ),
      ),
    );
  }
}

class _FollowUserTile extends ConsumerWidget {
  const _FollowUserTile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return profileAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
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
      },
      loading: () => const ListTile(
        leading: CircleAvatar(),
        title: LinearProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
