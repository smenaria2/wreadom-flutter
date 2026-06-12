import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../screens/webview_platform_helper.dart';
import '../utils/writer_media_utils.dart';
import 'youtube_player_widget.dart';
import 'instagram_embed_widget.dart';

/// Entry-point widget for all embedded writer media.
///
/// - YouTube  → [YoutubePlayerWidget] (official IFrame Player API, works on
///              Android / iOS / Web)
/// - Instagram → [InstagramEmbedWidget] (WebView with Chrome UA + HTML shell;
///               falls back to in-app browser on web)
/// - Spotify / other → plain WebView with a fallback banner
class InAppMediaWebView extends StatefulWidget {
  const InAppMediaWebView({
    super.key,
    required this.url,
    this.aspectRatio,
    this.height,
  });

  final String url;
  final double? aspectRatio;
  final double? height;

  @override
  State<InAppMediaWebView> createState() => _InAppMediaWebViewState();
}

class _InAppMediaWebViewState extends State<InAppMediaWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  WriterMediaInfo get _info => classifyWriterMediaUrl(widget.url);

  @override
  void initState() {
    super.initState();
    // Only initialise a generic WebView for non-YouTube, non-Instagram media.
    if (_info.type != WriterMediaType.youtube &&
        _info.type != WriterMediaType.instagram) {
      _initWebView();
    }
  }

  void _initWebView() {
    try {
      initializeWebViewPlatform();
      final controller = createWebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setBackgroundColor(Colors.transparent);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
      );

      final embedUrl = _info.embedUrl.isNotEmpty ? _info.embedUrl : widget.url;
      controller.loadRequest(
        Uri.parse(embedUrl),
        headers: const {'Referer': 'https://wreadom.in/'},
      );
      _controller = controller;
    } catch (_) {
      _hasError = true;
      _isLoading = false;
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    final mode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView;
    await launchUrl(uri, mode: mode);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;

    // ── YouTube ────────────────────────────────────────────────────────────
    if (info.type == WriterMediaType.youtube) {
      // Extract the video ID from the embed URL  (…/embed/<ID>)
      final segments = Uri.tryParse(info.embedUrl)?.pathSegments ?? [];
      final embedIdx = segments.indexOf('embed');
      final videoId = (embedIdx != -1 && embedIdx + 1 < segments.length)
          ? segments[embedIdx + 1]
          : '';

      if (videoId.isNotEmpty) {
        return YoutubePlayerWidget(
          videoId: videoId,
          originalUrl: info.originalUrl,
        );
      }
    }

    // ── Instagram ──────────────────────────────────────────────────────────
    if (info.type == WriterMediaType.instagram) {
      return InstagramEmbedWidget(
        embedUrl: info.embedUrl,
        originalUrl: info.originalUrl,
      );
    }

    // ── Generic WebView (Spotify / other) ─────────────────────────────────
    final scheme = Theme.of(context).colorScheme;
    Widget child;
    if (_hasError || _controller == null) {
      child = _buildErrorView(scheme);
    } else {
      child = Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final double resolvedHeight = widget.height ?? 350.0;
    final double? resolvedAspectRatio = widget.aspectRatio;
    final borderRadius = BorderRadius.circular(8);
    final borderColor = scheme.outlineVariant;

    if (resolvedAspectRatio != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AspectRatio(aspectRatio: resolvedAspectRatio, child: child),
        ),
      );
    }

    return Container(
      height: resolvedHeight,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }

  Widget _buildErrorView(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: scheme.error, size: 36),
            const SizedBox(height: 8),
            Text(
              'Failed to load media',
              style: TextStyle(
                  color: scheme.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
