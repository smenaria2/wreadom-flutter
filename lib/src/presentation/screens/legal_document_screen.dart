import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import 'webview_platform_helper.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    initializeWebViewPlatform();
    _initController();
  }

  void _initController() {
    try {
      final controller = createWebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setBackgroundColor(const Color(0x00000000));
      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('LegalDocument WebView Error: ${error.description}');
            if (error.isForMainFrame == true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      );
      controller.loadRequest(Uri.parse(widget.url));

      setState(() {
        _controller = controller;
        _isLoading = true;
        _loadingProgress = 0;
        _hasError = false;
      });
    } catch (error) {
      debugPrint('LegalDocument WebView initialization failed: $error');
      if (!mounted) return;
      setState(() {
        _controller = null;
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initController,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassSurface(
                    strong: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load ${widget.title}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your internet connection or try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initController,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
