import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/home_banner.dart';
import '../../utils/app_link_helper.dart';
import '../providers/home_banner_by_id_provider.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class HomeBannerArguments {
  const HomeBannerArguments({this.banner, this.bannerId});

  final HomeBanner? banner;
  final String? bannerId;
}

class HomeBannerScreen extends ConsumerStatefulWidget {
  const HomeBannerScreen({
    super.key,
    this.banner,
    this.bannerId,
  });

  final HomeBanner? banner;
  final String? bannerId;

  @override
  ConsumerState<HomeBannerScreen> createState() => _HomeBannerScreenState();
}

class _HomeBannerScreenState extends ConsumerState<HomeBannerScreen> {
  HomeBanner? _banner;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _banner = widget.banner;
    if (_banner == null && widget.bannerId != null) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banner = await ref.read(homeBannerByIdProvider(widget.bannerId!).future);
      if (mounted) {
        setState(() {
          _banner = banner;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load banner details.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const GlassScaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _banner == null) {
      return GlassScaffold(
        appBar: glassAppBar(
          title: const Text('Banner Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Banner not found',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (widget.bannerId != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadBanner,
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final banner = _banner!;
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
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 20,
                bottom: 16,
              ),
              title: Text(
                banner.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
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
                        Center(
                          child: FilledButton(
                            onPressed: () =>
                                _openAnyLink(context, banner.buttonLink),
                            child: Text(banner.buttonText),
                          ),
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
    return _openAnyLink(context, link);
  }

  Future<bool> _openAnyLink(BuildContext context, String link) async {
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
