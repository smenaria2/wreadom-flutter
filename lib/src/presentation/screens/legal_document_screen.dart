import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../data/services/legal_document_service.dart';

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
  late Future<LegalDocument> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = _loadDocument();
  }

  @override
  void didUpdateWidget(LegalDocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.title != widget.title) {
      _documentFuture = _loadDocument();
    }
  }

  Future<LegalDocument> _loadDocument() {
    return ref
        .read(legalDocumentServiceProvider)
        .fetch(widget.url, title: widget.title);
  }

  void _retry() {
    setState(() {
      _documentFuture = _loadDocument();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: FutureBuilder<LegalDocument>(
          future: _documentFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final document = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _retry(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (document.isFallback) ...[
                    Material(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Showing an in-app fallback because the live '
                                'document could not be loaded.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  HtmlWidget(
                    document.html,
                    textStyle: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.55),
                    customStylesBuilder: (element) {
                      final tag = element.localName?.toLowerCase();
                      if (tag == 'table') {
                        return {'width': '100%'};
                      }
                      if (tag == 'th' || tag == 'td') {
                        return {'padding': '8px', 'border': '1px solid #ddd'};
                      }
                      return null;
                    },
                    onTapUrl: (_) async => false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
