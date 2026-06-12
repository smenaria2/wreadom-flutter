import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../screens/webview_platform_helper.dart';

/// Shows the actual Instagram post preview by loading the /embed URL in a
/// WebView. A full-size transparent overlay intercepts taps so that touching
/// the preview opens the original post in the in-app browser instead of
/// navigating inside the WebView.
///
/// Falls back to a plain preview card if the WebView fails or on web.
class InstagramEmbedWidget extends StatefulWidget {
  const InstagramEmbedWidget({
    super.key,
    required this.embedUrl,
    required this.originalUrl,
  });

  final String embedUrl;
  final String originalUrl;

  @override
  State<InstagramEmbedWidget> createState() => _InstagramEmbedWidgetState();
}

class _InstagramEmbedWidgetState extends State<InstagramEmbedWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // A realistic mobile Chrome UA convinces Instagram to serve the embed
  // without its "Open in App" redirect.
  static const String _chromeUA =
      'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      initializeWebViewPlatform();
      final controller = createWebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setUserAgent(_chromeUA)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() { _isLoading = true; _hasError = false; });
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == false) return;
              if (mounted) setState(() { _hasError = true; _isLoading = false; });
            },
            // Block ALL navigation so WebView never leaves the embed page.
            onNavigationRequest: (_) => NavigationDecision.prevent,
          ),
        )
        // Load a minimal HTML shell that iframes the /embed URL at a fixed
        // size — this avoids the flicker caused by Instagram's embed.js
        // resizing the container dynamically.
        ..loadHtmlString(_buildHtml(widget.embedUrl));

      _controller = controller;
    } catch (_) {
      _hasError = true;
      _isLoading = false;
    }
  }

  String _buildHtml(String embedUrl) => '''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    html, body { width:100%; height:100%; background:#fff; overflow:hidden; }
    iframe { width:100%; height:100%; border:none; display:block; }
  </style>
</head>
<body>
  <iframe
    src="$embedUrl"
    scrolling="no"
    allowtransparency="true"
    allow="autoplay; clipboard-write; encrypted-media; picture-in-picture"
    frameborder="0">
  </iframe>
</body>
</html>''';

  Future<void> _openInBrowser() async {
    final uri = Uri.tryParse(widget.originalUrl);
    if (uri == null) return;
    final mode =
        kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView;
    await launchUrl(uri, mode: mode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // ── Fallback card ──────────────────────────────────────────────────────
    if (_hasError || _controller == null) {
      return _buildFallbackCard(scheme);
    }

    // ── Actual preview with tap overlay ───────────────────────────────────
    return Container(
      height: 480,
      margin: const EdgeInsets.symmetric(vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
        color: Colors.white,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The actual embed preview
          WebViewWidget(controller: _controller!),

          // Loading indicator shown until the page is ready
          if (_isLoading)
            const ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),

          // Transparent overlay — intercepts every tap and opens in browser.
          // Using Positioned.fill so it covers the full WebView area.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _openInBrowser,
              // Absorb all gestures so the WebView never receives them.
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

          // Small "open" hint badge in the top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Tap to open',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCard(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        onTap: _openInBrowser,
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
                  color: const Color(0xFFC13584).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_camera_outlined,
                    color: Color(0xFFC13584)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Instagram',
                      style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.originalUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.58)),
            ],
          ),
        ),
      ),
    );
  }
}
