import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/writer_media_utils.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
      child: InkWell(
        onTap: () => _openUrl(info.originalUrl),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accentColor(info.type).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconFor(info.type),
                  color: _accentColor(info.type),
                ),
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
      WriterMediaType.unsupported => Icons.link_off_rounded,
    };
  }

  Color _accentColor(WriterMediaType type) {
    return switch (type) {
      WriterMediaType.youtube => const Color(0xFFD93025),
      WriterMediaType.instagram => const Color(0xFFC13584),
      WriterMediaType.spotify => const Color(0xFF1DB954),
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

Future<void> _openUrl(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
