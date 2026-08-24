import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/domain/models/feed_post.dart';
import 'package:librebook_flutter/src/presentation/providers/homepage_providers.dart';
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
    // Reuse the compiled/cache-first Home audio payload. Mounting this preview
    // must not create a second public-feed pagination request.
    final postsAsync = ref.watch(homepageAudioPostsProvider);
    final posts = postsAsync.asData?.value ?? const <FeedPost>[];

    if (posts.isEmpty) {
      if (postsAsync.isLoading && !postsAsync.hasValue) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
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
            return ReelPreviewCard(post: post);
          },
        ),
      ),
    );
  }
}

class ReelPreviewCard extends StatelessWidget {
  const ReelPreviewCard({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;
    final hasBookCover =
        post.bookCover != null && post.bookCover!.trim().isNotEmpty;
    final coverUrl = hasImage
        ? post.imageUrl
        : (hasBookCover ? post.bookCover : null);
    final postText = post.text.trim();
    final gradientIndex =
        (post.id.hashCode).abs() % ReelsPreviewCarousel._gradientPresets.length;
    final gradient = ReelsPreviewCarousel._gradientPresets[gradientIndex];

    String resolveName() {
      if (post.penName != null && post.penName!.trim().isNotEmpty) {
        return post.penName!.trim();
      }
      if (post.displayName != null && post.displayName!.trim().isNotEmpty) {
        return post.displayName!.trim();
      }
      if (post.username.trim().isNotEmpty) {
        return post.username.trim();
      }
      return 'Anonymous';
    }

    final displayName = resolveName();
    final initialLetter = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'W';

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.feedReels, arguments: post.id);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Layer
            if (coverUrl != null)
              CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(decoration: BoxDecoration(gradient: gradient)),
                errorWidget: (context, url, error) =>
                    Container(decoration: BoxDecoration(gradient: gradient)),
              )
            else
              Container(decoration: BoxDecoration(gradient: gradient)),

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

            // Keep the post copy visible even when an image or book cover is
            // used as the card background.
            if (postText.isNotEmpty)
              Positioned(
                left: 8,
                right: 8,
                top: 44,
                bottom: 34,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      postText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
