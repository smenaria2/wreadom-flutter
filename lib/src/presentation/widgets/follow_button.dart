import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

class FollowButton extends ConsumerWidget {
  final String targetUserId;
  final bool compact;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserProvider).value?.id;

    // Don't show follow button for self
    if (currentUserId == null || currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }

    final isFollowingAsync = ref.watch(isFollowingProvider(targetUserId));

    return isFollowingAsync.when(
      data: (isFollowing) => compact
          ? IconButton(
              icon: Icon(
                isFollowing
                    ? Icons.person_remove_outlined
                    : Icons.person_add_outlined,
                color: isFollowing
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () => _toggleFollow(context, ref, isFollowing),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isFollowing
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: isFollowing
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _toggleFollow(context, ref, isFollowing),
              child: Text(isFollowing ? l10n.unfollow : l10n.follow),
            ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) =>
          const Icon(Icons.error_outline, size: 20, color: Colors.red),
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final follower = ref.read(currentUserProvider).value;
    final followerId = follower?.id;
    if (followerId == null || follower == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInToContinueAction)));
      return;
    }

    final repo = ref.read(followRepositoryProvider);

    try {
      if (isFollowing) {
        await repo.unfollowUser(
          followerId: followerId,
          followingId: targetUserId,
        );
      } else {
        await repo.followUser(
          followerId: followerId,
          followingId: targetUserId,
        );
      }
      await HapticFeedback.mediumImpact();
      // Invalidate both to refresh UI
      ref.invalidate(isFollowingProvider(targetUserId));
      ref.invalidate(followingListProvider);
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.followActionFailed(e.toString()))),
        );
      }
    }
  }
}
