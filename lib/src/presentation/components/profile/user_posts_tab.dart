import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../providers/feed_providers.dart';
import '../../widgets/themed_empty_state.dart';
import '../../widgets/see_more_content_button.dart';
import '../feed_post_card.dart';

class UserPostsTab extends ConsumerWidget {
  final String userId;
  const UserPostsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pagedUserFeedPostsProvider(userId));
    final controller = ref.read(pagedUserFeedPostsProvider(userId).notifier);

    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.failedToLoadPosts(state.error.toString())),
        ),
      );
    }
    if (state.items.isEmpty) {
      return ThemedEmptyState(
        icon: Icons.dynamic_feed_outlined,
        message: l10n.noPostsYetStartSharing,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            if (!state.hasMore) return const SizedBox(height: 24);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SeeMoreContentButton(
                  onPressed: state.isLoadingMore ? null : controller.loadMore,
                  loading: state.isLoadingMore,
                ),
              ),
            );
          }
          return FeedPostCard(
            key: ValueKey(state.items[index].id ?? ''),
            post: state.items[index],
          );
        },
        itemCount: state.items.length + 1,
      ),
    );
  }
}
