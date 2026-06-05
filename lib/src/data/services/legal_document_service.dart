import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

final legalDocumentServiceProvider = Provider<LegalDocumentService>((ref) {
  return LegalDocumentService();
});

class LegalDocument {
  const LegalDocument({
    required this.html,
    required this.sourceUrl,
    required this.isFallback,
  });

  final String html;
  final String sourceUrl;
  final bool isFallback;
}

class LegalDocumentService {
  LegalDocumentService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<LegalDocument> fetch(String url, {required String title}) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }

      final sanitized = sanitizeLegalHtml(response.body);
      if (_plainText(sanitized).isEmpty) {
        throw StateError('Legal document was empty after sanitizing.');
      }

      return LegalDocument(html: sanitized, sourceUrl: url, isFallback: false);
    } catch (_) {
      return LegalDocument(
        html: fallbackLegalHtml(title: title, sourceUrl: url),
        sourceUrl: url,
        isFallback: true,
      );
    }
  }
}

String sanitizeLegalHtml(String input) {
  final document = html_parser.parse(input);
  final root =
      document.querySelector('main') ??
      document.querySelector('article') ??
      document.body ??
      document.documentElement;
  if (root == null) return '';

  final buffer = StringBuffer();
  for (final node in root.nodes) {
    buffer.write(_sanitizeLegalNode(node));
  }
  return buffer.toString().trim();
}

String fallbackLegalHtml({required String title, required String sourceUrl}) {
  final escapedTitle = const HtmlEscape().convert(title);
  final escapedUrl = const HtmlEscape().convert(sourceUrl);
  return '<section>'
      '<h1>$escapedTitle</h1>'
      '<p>We could not load this document right now. Please check your '
      'connection and try again.</p>'
      '<p>Source: <a href="$escapedUrl">$escapedUrl</a></p>'
      '</section>';
}

String _sanitizeLegalNode(dom.Node node) {
  if (node is dom.Text) return const HtmlEscape().convert(node.text);
  if (node is! dom.Element) return '';

  final tag = node.localName?.toLowerCase() ?? '';
  if (_blockedLegalTags.contains(tag)) return '';

  final children = node.nodes.map(_sanitizeLegalNode).join();
  if (!_allowedLegalTags.contains(tag)) return children;
  if (tag == 'br') return '<br>';

  final attributes = _safeAttributesFor(tag, node);
  return '<$tag$attributes>$children</$tag>';
}

String _safeAttributesFor(String tag, dom.Element element) {
  if (tag != 'a') return '';
  final href = element.attributes['href']?.trim();
  if (!_isSafeLegalHref(href)) return '';
  return ' href="${_escapeHtmlAttribute(href!)}"';
}

bool _isSafeLegalHref(String? href) {
  if (href == null || href.isEmpty) return false;
  final uri = Uri.tryParse(href);
  if (uri == null) return false;
  if (!uri.hasScheme) return true;
  return uri.scheme == 'https' ||
      uri.scheme == 'http' ||
      uri.scheme == 'mailto';
}

String _plainText(String html) =>
    html_parser.parseFragment(html).text?.trim() ?? '';

String _escapeHtmlAttribute(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

const _allowedLegalTags = {
  'a',
  'article',
  'b',
  'blockquote',
  'br',
  'div',
  'em',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'i',
  'li',
  'main',
  'ol',
  'p',
  'section',
  'span',
  'strong',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'u',
  'ul',
};

const _blockedLegalTags = {
  'base',
  'embed',
  'form',
  'iframe',
  'input',
  'link',
  'meta',
  'noscript',
  'object',
  'script',
  'style',
  'svg',
  'template',
};
