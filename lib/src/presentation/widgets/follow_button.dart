import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/auth_providers.dart';
import '../providers/follow_providers.dart';

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
                isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                color: isFollowing ? Colors.grey : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () => _toggleFollow(ref, isFollowing),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isFollowing ? Colors.grey : Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: isFollowing ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _toggleFollow(ref, isFollowing),
              child: Text(isFollowing ? 'Unfollow' : 'Follow'),
            ),
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const Icon(Icons.error_outline, size: 20, color: Colors.red),
    );
  }

  Future<void> _toggleFollow(WidgetRef ref, bool isFollowing) async {
    final followerId = ref.read(currentUserProvider).value?.id;
    if (followerId == null) return;

    final repo = ref.read(followRepositoryProvider);
    
    try {
      if (isFollowing) {
        await repo.unfollowUser(followerId: followerId, followingId: targetUserId);
      } else {
        await repo.followUser(followerId: followerId, followingId: targetUserId);
      }
      await HapticFeedback.mediumImpact();
      // Invalidate both to refresh UI
      ref.invalidate(isFollowingProvider(targetUserId));
      ref.invalidate(followingListProvider);
    } catch (e) {
      // Handle error (could show a snackbar)
      debugPrint('Error toggling follow: $e');
    }
  }
}
