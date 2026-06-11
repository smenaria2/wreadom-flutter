import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/home_banner.dart';
import '../../utils/app_link_helper.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

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
    final contentHtml = _renderableBannerHtml(banner.bodyHtml);
    final plainContent = banner.body.trim().isEmpty
        ? banner.subtitle
        : banner.body;
    return GlassScaffold(
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
                GlassSurface(
                  strong: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (banner.subtitle.trim().isNotEmpty) ...[
                        Text(
                          banner.subtitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (contentHtml.isNotEmpty)
                        HtmlWidget(
                          contentHtml,
                          textStyle: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                            color: theme.colorScheme.onSurface,
                          ),
                          customStylesBuilder: _bannerHtmlStyles,
                          customWidgetBuilder: _bannerHtmlWidgets,
                          onTapUrl: (url) => _openHtmlLink(context, url),
                        )
                      else
                        Text(
                          plainContent,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      if (banner.buttonText.trim().isNotEmpty &&
                          banner.buttonLink.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () =>
                              _openLink(context, banner.buttonLink),
                          child: Text(banner.buttonText),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _openHtmlLink(BuildContext context, String link) async {
    if (_openLink(context, link)) return true;
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _openLink(BuildContext context, String link) {
    final resolved = AppLinkHelper.resolve(link);
    if (resolved == null) {
      final uri = Uri.tryParse(link.trim());
      if (uri == null || uri.hasScheme) return false;
      Navigator.of(context).pushNamed(link);
      return true;
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
    return true;
  }
}

Map<String, String>? _bannerHtmlStyles(dom.Element element) {
  switch (element.localName?.toLowerCase()) {
    case 'table':
      return {'width': '100%'};
    case 'img':
      return {'max-width': '100%', 'height': 'auto'};
    case 'a':
      return {'text-decoration': 'underline'};
  }
  return null;
}

Widget? _bannerHtmlWidgets(dom.Element element) {
  final tag = element.localName?.toLowerCase();
  if (tag == 'script' || tag == 'style' || tag == 'iframe') {
    return const SizedBox.shrink();
  }
  return null;
}

String _renderableBannerHtml(String rawHtml) {
  final raw = rawHtml.trim();
  if (raw.isEmpty) return '';
  final document = html_parser.parse(raw);
  final body = document.body;
  final nodes = (body?.nodes ?? html_parser.parseFragment(raw).nodes)
      .where((node) => node is! dom.Element || !_isBlockedBannerHtmlTag(node))
      .toList();
  for (final element in nodes.whereType<dom.Element>()) {
    element
        .querySelectorAll('script,style,iframe,object,embed,form,input,button')
        .forEach((child) => child.remove());
  }
  final html = nodes.map(_htmlForNode).join().trim();
  return html;
}

String _htmlForNode(dom.Node node) {
  if (node is dom.Element) return node.outerHtml;
  if (node is dom.Text) return node.data;
  return node.text ?? '';
}

bool _isBlockedBannerHtmlTag(dom.Element element) {
  return const {
    'script',
    'style',
    'iframe',
    'object',
    'embed',
    'form',
    'input',
    'button',
  }.contains(element.localName?.toLowerCase());
}
