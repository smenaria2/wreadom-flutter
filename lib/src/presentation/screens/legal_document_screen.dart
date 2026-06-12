import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/legal_document_service.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import 'webview_platform_helper.dart';

class LegalDocumentScreen extends ConsumerStatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  ConsumerState<LegalDocumentScreen> createState() =>
      _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends ConsumerState<LegalDocumentScreen> {
  WebViewController? _controller;
  Future<LegalDocument>? _fallbackFuture;
  bool _isLoading = true;
  bool _hasWebError = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<LegalDocument> _fetchFallbackDocument() {
    return ref
        .read(legalDocumentServiceProvider)
        .fetch(widget.url, title: widget.title);
  }

  void _initController() {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _showFallback();
      return;
    }

    try {
      initializeWebViewPlatform();
      final controller = createWebViewController() as WebViewController;
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress / 100);
            },
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() {
                _isLoading = true;
                _hasWebError = false;
                _progress = 0;
              });
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                _progress = 1;
              });
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == false) return;
              _showFallback();
            },
          ),
        );
      unawaited(controller.loadRequest(uri));
      setState(() {
        _controller = controller;
        _isLoading = true;
        _hasWebError = false;
      });
    } catch (_) {
      _showFallback();
    }
  }

  void _showFallback() {
    if (!mounted) return;
    setState(() {
      _controller = null;
      _hasWebError = true;
      _isLoading = false;
      _fallbackFuture ??= _fetchFallbackDocument();
    });
  }

  void _refresh() {
    if (_controller != null && !_hasWebError) {
      setState(() {
        _isLoading = true;
        _progress = 0;
      });
      unawaited(_controller!.reload());
      return;
    }

    setState(() {
      _fallbackFuture = null;
      _hasWebError = false;
      _isLoading = true;
      _progress = 0;
    });
    _initController();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_controller != null && !_hasWebError)
              WebViewWidget(controller: _controller!),
            if (_hasWebError)
              _LegalFallbackView(
                title: widget.title,
                url: widget.url,
                future: _fallbackFuture ??= _fetchFallbackDocument(),
              ),
            if (_isLoading)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _progress > 0 && _progress < 1 ? _progress : null,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalFallbackView extends StatelessWidget {
  const _LegalFallbackView({
    required this.title,
    required this.url,
    required this.future,
  });

  final String title;
  final String url;
  final Future<LegalDocument> future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<LegalDocument>(
      future: future,
      builder: (context, snapshot) {
        final document =
            snapshot.data ??
            LegalDocument(
              html: fallbackLegalHtml(title: title, sourceUrl: url),
              sourceUrl: url,
              isFallback: true,
            );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            GlassSurface(
              strong: true,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Showing fallback content',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HtmlWidget(
                    document.html,
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
