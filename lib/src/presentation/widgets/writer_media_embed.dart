import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_link_helper.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import '../utils/writer_media_utils.dart';
import 'in_app_media_web_view.dart';
import 'glass_surface.dart';

class WriterImageEmbedBuilder extends EmbedBuilder {
  const WriterImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  String toPlainText(node) => ' Image ';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scheme = Theme.of(context).colorScheme;
          return Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 160, maxHeight: 420),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              url,
              width: constraints.maxWidth,
              fit: BoxFit.contain,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  _BrokenMediaCard(label: 'Image unavailable', detail: url),
            ),
          );
        },
      ),
    );
  }
}

class WriterMediaEmbedBuilder extends EmbedBuilder {
  const WriterMediaEmbedBuilder();

  @override
  String get key => BlockEmbed.videoType;

  @override
  String toPlainText(node) => ' Media ';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: WriterMediaPreview(url: url),
    );
  }
}

class WriterMediaPreview extends StatelessWidget {
  const WriterMediaPreview({
    super.key,
    required this.url,
    this.compact = false,
    this.textColor,
  });

  final String url;
  final bool compact;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final info = classifyWriterMediaUrl(url);
    final scheme = Theme.of(context).colorScheme;
    final foreground = textColor ?? scheme.onSurface;
    if (!info.isSupported) {
      return Text(
        url,
        style: TextStyle(color: foreground.withValues(alpha: 0.72)),
      );
    }

    final youtubeId = info.type == WriterMediaType.youtube ? youtubeVideoIdFromUrl(url) : null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
      child: InkWell(
        onTap: () => _openMediaUrl(context, info),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              if (youtubeId != null)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg',
                        width: 80,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 50,
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: const Color(0xFFD93025),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accentColor(info.type).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: info.type == WriterMediaType.suno
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/suno_logo.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(_iconFor(info.type), color: _accentColor(info.type)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.label,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.originalUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: foreground.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(WriterMediaType type) {
    return switch (type) {
      WriterMediaType.youtube => Icons.play_circle_fill_rounded,
      WriterMediaType.instagram => Icons.photo_camera_outlined,
      WriterMediaType.spotify => Icons.graphic_eq_rounded,
      WriterMediaType.amazon => Icons.shopping_bag_outlined,
      WriterMediaType.wikipedia => Icons.travel_explore_outlined,
      WriterMediaType.suno => Icons.music_note_rounded,
      WriterMediaType.wreadomBook => Icons.book_rounded,
      WriterMediaType.wreadomPost => Icons.dynamic_feed_rounded,
      WriterMediaType.unsupported => Icons.link_off_rounded,
    };
  }

  Color _accentColor(WriterMediaType type) {
    return switch (type) {
      WriterMediaType.youtube => const Color(0xFFD93025),
      WriterMediaType.instagram => const Color(0xFFC13584),
      WriterMediaType.spotify => const Color(0xFF1DB954),
      WriterMediaType.amazon => const Color(0xFFFF9900),
      WriterMediaType.wikipedia => const Color(0xFF54595D),
      WriterMediaType.suno => const Color(0xFFFF5722),
      WriterMediaType.wreadomBook => const Color(0xFFE91E63),
      WriterMediaType.wreadomPost => const Color(0xFF2E7D32),
      WriterMediaType.unsupported => Colors.grey,
    };
  }
}

class _BrokenMediaCard extends StatelessWidget {
  const _BrokenMediaCard({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label\n$detail',
        style: TextStyle(color: scheme.onErrorContainer),
      ),
    );
  }
}



void _openMediaUrl(BuildContext context, WriterMediaInfo info) {
  final url = info.originalUrl;
  if (info.type == WriterMediaType.wreadomBook ||
      info.type == WriterMediaType.wreadomPost) {
    final resolved = AppLinkHelper.resolve(url);
    if (resolved?.payload != null) {
      if (resolved!.route == AppRoutes.bookDetail) {
        Navigator.of(context).pushNamed(
          AppRoutes.bookDetail,
          arguments: BookDetailArguments(bookId: resolved.payload!),
        );
      } else if (resolved.route == AppRoutes.postDetail) {
        Navigator.of(context).pushNamed(
          AppRoutes.postDetail,
          arguments: PostDetailArguments(postId: resolved.payload!),
        );
      }
    }
    return;
  }
  if (info.type == WriterMediaType.amazon ||
      info.type == WriterMediaType.wikipedia ||
      info.type == WriterMediaType.suno) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
    return;
  }
  
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GlassSurface(
      strong: true,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                child: InAppMediaWebView(url: url),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
