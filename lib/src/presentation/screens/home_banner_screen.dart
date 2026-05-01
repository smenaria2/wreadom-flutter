import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/models/home_banner.dart';
import '../../utils/app_link_helper.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class HomeBannerArguments {
  const HomeBannerArguments({required this.banner});

  final HomeBanner banner;
}

class HomeBannerScreen extends StatelessWidget {
  const HomeBannerScreen({super.key, required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                banner.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (banner.coverImageUrl.isNotEmpty)
                    Image(
                      image: CachedNetworkImageProvider(banner.coverImageUrl),
                      fit: BoxFit.cover,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (banner.subtitle.trim().isNotEmpty) ...[
                  Text(
                    banner.subtitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(
                  banner.body.trim().isEmpty ? banner.subtitle : banner.body,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                if (banner.buttonText.trim().isNotEmpty &&
                    banner.buttonLink.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _openLink(context, banner.buttonLink),
                    child: Text(banner.buttonText),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openLink(BuildContext context, String link) {
    final resolved = AppLinkHelper.resolve(link);
    if (resolved == null) {
      Navigator.of(context).pushNamed(link);
      return;
    }

    switch (resolved.route) {
      case AppRoutes.bookDetail:
        Navigator.of(context).pushNamed(
          AppRoutes.bookDetail,
          arguments: BookDetailArguments(bookId: resolved.payload ?? ''),
        );
        break;
      case AppRoutes.postDetail:
        Navigator.of(context).pushNamed(
          AppRoutes.postDetail,
          arguments: PostDetailArguments(postId: resolved.payload ?? ''),
        );
        break;
      case AppRoutes.publicProfile:
        Navigator.of(context).pushNamed(
          AppRoutes.publicProfile,
          arguments: PublicProfileArguments(userId: resolved.payload ?? ''),
        );
        break;
      case AppRoutes.conversation:
        Navigator.of(context).pushNamed(
          AppRoutes.conversation,
          arguments: ConversationArguments(
            conversationId: resolved.payload ?? '',
            title: 'Messages',
          ),
        );
        break;
      default:
        Navigator.of(
          context,
        ).pushNamed(resolved.route, arguments: resolved.payload);
    }
  }
}
