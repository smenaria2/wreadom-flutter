import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/presentation/providers/feed_providers.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/presentation/widgets/glass_surface.dart';
import 'package:librebook_flutter/src/presentation/widgets/resilient_profile_avatar.dart';

class ReelsPreviewCarousel extends ConsumerWidget {
  const ReelsPreviewCarousel({super.key});

  static const List<LinearGradient> _gradientPresets = [
    LinearGradient(
      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF00c6ff), Color(0xFF0072ff)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pagedFeedPostsProvider(FeedFilter.public));
    final posts = state.items;

    if (posts.isEmpty) {
      if (state.isInitialLoading) {
        return const SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: posts.length.clamp(0, 15),
          itemBuilder: (context, index) {
            final post = posts[index];
            return _ReelPreviewCard(post: post);
          },
        ),
      ),
    );
  }
}

class _ReelPreviewCard extends StatelessWidget {
  const _ReelPreviewCard({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;
    final hasBookCover = post.bookCover != null && post.bookCover!.trim().isNotEmpty;
    final coverUrl = hasImage ? post.imageUrl : (hasBookCover ? post.bookCover : null);
    final gradientIndex = (post.id.hashCode).abs() % ReelsPreviewCarousel._gradientPresets.length;
    final gradient = ReelsPreviewCarousel._gradientPresets[gradientIndex];

    final displayName = post.penName ?? post.displayName ?? post.username;
    final initialLetter = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'W';

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.feedReels,
            arguments: post.id,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Layer
            if (coverUrl != null)
              CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(gradient: gradient),
              ),

            // Dimming Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Text Snippet inside Card (only if no image covers the card background)
            if (coverUrl == null && post.text.trim().isNotEmpty)
              Positioned(
                left: 8,
                right: 8,
                top: 48,
                bottom: 36,
                child: Center(
                  child: Text(
                    post.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Story-like Ring + User Avatar (Top-left)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF007F),
                      Color(0xFFFF7F00),
                      Color(0xFFFFFF00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(1.0),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: ResilientProfileAvatar(
                    radius: 12,
                    initial: initialLetter,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    imageUrl: post.userPhotoURL,
                  ),
                ),
              ),
            ),

            // Middle Play Badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            // Star Rating (if review) or small overlay
            if (post.type.toLowerCase() == 'review' && post.rating != null)
              Positioned(
                right: 8,
                top: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (idx) => Icon(
                      Icons.star,
                      color: idx < post.rating! ? Colors.amber : Colors.white24,
                      size: 9,
                    ),
                  ),
                ),
              ),

            // Bottom penName / username
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
