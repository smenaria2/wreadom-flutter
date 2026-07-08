import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'youtube_player_widget.dart';
import 'instagram_embed_widget.dart';
import 'in_app_media_web_view.dart';
import 'writer_media_embed.dart';
import '../utils/writer_media_utils.dart';

/// Renders a media link (YouTube, Instagram, Spotify, Suno, etc.) in feed posts.
/// Shows a large, visually rich brand preview card/thumbnail first, and then loads
/// the player or web view inline in the feed container once "Play" is clicked.
class FeedMediaPlayableCard extends StatefulWidget {
  const FeedMediaPlayableCard({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<FeedMediaPlayableCard> createState() => _FeedMediaPlayableCardState();
}

class _FeedMediaPlayableCardState extends State<FeedMediaPlayableCard> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final info = classifyWriterMediaUrl(widget.url);
    final scheme = Theme.of(context).colorScheme;

    if (!info.isSupported) {
      return const SizedBox.shrink();
    }

    final isPlayable = info.type == WriterMediaType.youtube ||
        info.type == WriterMediaType.instagram ||
        info.type == WriterMediaType.spotify ||
        info.type == WriterMediaType.suno;

    // Fall back to compact preview row if the media type is not a playable video/audio.
    if (!isPlayable) {
      return WriterMediaPreview(url: widget.url, compact: true);
    }

    if (_isPlaying) {
      return _buildInlinePlayer(info, scheme);
    }

    return _buildPreviewCard(info, scheme);
  }

  Widget _buildInlinePlayer(WriterMediaInfo info, ColorScheme scheme) {
    switch (info.type) {
      case WriterMediaType.youtube:
        final segments = Uri.tryParse(info.embedUrl)?.pathSegments ?? [];
        final embedIdx = segments.indexOf('embed');
        final videoId = (embedIdx != -1 && embedIdx + 1 < segments.length)
            ? segments[embedIdx + 1]
            : '';
        if (videoId.isNotEmpty) {
          return YoutubePlayerWidget(
            videoId: videoId,
            originalUrl: info.originalUrl,
            autoPlay: true,
          );
        }
        return WriterMediaPreview(url: widget.url, compact: true);

      case WriterMediaType.instagram:
        return InstagramEmbedWidget(
          embedUrl: info.embedUrl,
          originalUrl: info.originalUrl,
          interactive: true,
        );

      case WriterMediaType.spotify:
      case WriterMediaType.suno:
        return InAppMediaWebView(
          url: info.originalUrl,
          height: 350,
        );

      default:
        return WriterMediaPreview(url: widget.url, compact: true);
    }
  }

  Widget _buildPreviewCard(WriterMediaInfo info, ColorScheme scheme) {
    switch (info.type) {
      case WriterMediaType.youtube:
        final videoId = youtubeVideoIdFromUrl(info.originalUrl) ?? '';
        return _buildYouTubePreview(videoId, info, scheme);
      case WriterMediaType.instagram:
        return _buildBrandPreviewCard(
          info: info,
          scheme: scheme,
          icon: Icons.photo_camera_outlined,
          brandName: 'Instagram',
          gradient: const LinearGradient(
            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFFC13584),
        );
      case WriterMediaType.spotify:
        return _buildBrandPreviewCard(
          info: info,
          scheme: scheme,
          icon: Icons.graphic_eq_rounded,
          brandName: 'Spotify',
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF191414)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          accentColor: const Color(0xFF1DB954),
        );
      case WriterMediaType.suno:
        return _buildBrandPreviewCard(
          info: info,
          scheme: scheme,
          icon: Icons.music_note_rounded,
          brandName: 'Suno',
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5722), Color(0xFF212121)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          accentColor: const Color(0xFFFF5722),
        );
      default:
        return WriterMediaPreview(url: widget.url, compact: true);
    }
  }

  Widget _buildYouTubePreview(String videoId, WriterMediaInfo info, ColorScheme scheme) {
    final thumbnailUrl = videoId.isNotEmpty
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // High-res Thumbnail
              if (thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.play_circle_fill_rounded, size: 50, color: Colors.grey),
                  ),
                )
              else
                Container(color: scheme.surfaceContainerHighest),

              // Dark Overlay Gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Play Button
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _isPlaying = true),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD93025).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),

              // Header Badge (Top-Left)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFD93025), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title/Link Info (Bottom-Left)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.originalUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPreviewCard({
    required WriterMediaInfo info,
    required ColorScheme scheme,
    required IconData icon,
    required String brandName,
    required Gradient gradient,
    required Color accentColor,
  }) {
    final double cardHeight = info.type == WriterMediaType.instagram ? 400.0 : 350.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),

          // Central Icon and Title Info
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  brandName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    info.originalUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _isPlaying = true),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            info.type == WriterMediaType.instagram ? Icons.visibility_rounded : Icons.play_arrow_rounded,
                            color: Colors.black87,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            info.type == WriterMediaType.instagram ? 'View Post' : 'Play Media',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header Badge (Top-Left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    brandName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
