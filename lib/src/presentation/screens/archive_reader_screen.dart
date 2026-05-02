import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/services/reader_ad_service.dart';
import '../../domain/models/book.dart';
import 'webview_platform_helper.dart';

class ArchiveReaderScreen extends StatefulWidget {
  const ArchiveReaderScreen({super.key, required this.book});

  final Book book;

  @override
  State<ArchiveReaderScreen> createState() => _ArchiveReaderScreenState();
}

class _ArchiveReaderScreenState extends State<ArchiveReaderScreen> {
  WebViewController? _controller;
  final ReaderAdService _readerAdService = ReaderAdService();
  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    initializeWebViewPlatform();
    unawaited(_readerAdService.showArchiveLoadingAd());
    _initController();
  }

  @override
  void dispose() {
    _readerAdService.dispose();
    super.dispose();
  }

  void _initController() {
    final identifier = widget.book.identifier?.trim();
    if (identifier == null || identifier.isEmpty) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

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
            debugPrint('ArchiveReader WebView Error: ${error.description}');
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.host == 'archive.org' ||
                uri.host.endsWith('.archive.org') ||
                uri.host == 'googleads.g.doubleclick.net' || // Allow ads if necessary
                uri.host == 'www.googleadservices.com') {
              return NavigationDecision.navigate;
            }
            debugPrint('Blocking navigation to unauthorized host: ${uri.host}');
            return NavigationDecision.prevent;
          },
        ),
      );
      controller.loadRequest(Uri.https('archive.org', '/embed/$identifier'));

      setState(() {
        _controller = controller;
        _isLoading = true;
        _loadingProgress = 0;
        _hasError = false;
      });
    } catch (error, stackTrace) {
      debugPrint('ArchiveReader WebView initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _controller = null;
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPdf() async {
    final pdfUrl = widget.book.formats['application/pdf'];
    if (pdfUrl == null) return;
    final url = Uri.parse(pdfUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Internet Archive Reader',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (widget.book.formats.containsKey('application/pdf'))
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              tooltip: 'View PDF',
              onPressed: _launchPdf,
            ),
        ],
      ),
      body: Stack(
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),

          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      widget.book.identifier == null ||
                              widget.book.identifier!.isEmpty
                          ? 'Missing book identifier'
                          : 'Could not load reader',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your internet connection or try opening in browser.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.book.identifier?.trim().isNotEmpty == true) {
                          _initController();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: Icon(
                        widget.book.identifier == null
                            ? Icons.arrow_back
                            : Icons.refresh,
                      ),
                      label: Text(
                        widget.book.identifier == null ? 'Go Back' : 'Retry',
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
