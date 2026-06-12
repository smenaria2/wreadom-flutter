import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Plays a YouTube video in-app using the official IFrame Player API.
/// Falls back to an in-app browser (or external browser on Web) on error.
class YoutubePlayerWidget extends StatefulWidget {
  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.originalUrl,
  });

  /// The 11-character YouTube video ID.
  final String videoId;

  /// The original URL used for the fallback button.
  final String originalUrl;

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        enableCaption: true,
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
      onWebResourceError: (error) {
        if (mounted) setState(() => _hasError = true);
      },
    );
    // Cue (not auto-play) the video once the controller is ready.
    _controller.cueVideoById(videoId: widget.videoId);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.originalUrl);
    if (uri == null) return;
    // On mobile use in-app browser; on web open in new tab
    final mode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.inAppBrowserView;
    await launchUrl(uri, mode: mode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_hasError) {
      return _buildFallback(scheme);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        color: Colors.black,
      ),
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildFallback(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD93025).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFFD93025)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'YouTube',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Watch'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD93025),
            ),
          ),
        ],
      ),
    );
  }
}
