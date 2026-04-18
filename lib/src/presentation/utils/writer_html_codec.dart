import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

Document documentFromHtml(String input) {
  final html = input.trim();
  if (html.isEmpty) return Document();

  try {
    final delta = Delta();
    final fragment = html_parser.parseFragment(html);
    final state = _HtmlState();
    for (final node in fragment.nodes) {
      _appendNode(delta, node, const {}, state);
    }
    if (!state.endsWithNewline) {
      delta.insert('\n');
    }
    if (delta.isEmpty) {
      delta.insert('\n');
    }
    return Document.fromDelta(delta);
  } catch (_) {
    return Document()..insert(0, html_parser.parseFragment(html).text ?? html);
  }
}

String htmlFromDocument(Document document) {
  final html = _deltaToHtml(document.toDelta());
  return sanitizeWriterHtml(html);
}

String sanitizeWriterHtml(String input) {
  final fragment = html_parser.parseFragment(input);
  final buffer = StringBuffer();
  for (final node in fragment.nodes) {
    buffer.write(_sanitizeNode(node));
  }
  return buffer.toString().trim();
}

String plainTextFromHtml(String input) {
  return html_parser.parseFragment(input).text?.trim() ?? input.trim();
}

const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'h1',
  'h2',
  'h3',
  'blockquote',
  'ul',
  'ol',
  'li',
};

void _appendNode(
  Delta delta,
  dom.Node node,
  Map<String, dynamic> inlineAttributes,
  _HtmlState state,
) {
  if (node is dom.Text) {
    final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) {
      if (!state.lastWasSpace && !state.endsWithNewline) {
        delta.insert(' ', inlineAttributes.isEmpty ? null : inlineAttributes);
        state.lastWasSpace = true;
        state.isEmpty = false;
      }
      return;
    }
    delta.insert(text, inlineAttributes.isEmpty ? null : inlineAttributes);
    state.lastWasSpace = text.endsWith(' ');
    state.endsWithNewline = false;
    state.isEmpty = false;
    return;
  }

  if (node is! dom.Element) return;

  final tag = node.localName?.toLowerCase() ?? '';
  if (tag == 'script' || tag == 'style') return;

  if (tag == 'br') {
    delta.insert('\n');
    state.endsWithNewline = true;
    state.lastWasSpace = false;
    state.isEmpty = false;
    return;
  }

  final nextInline = Map<String, dynamic>.from(inlineAttributes);
  if (tag == 'strong' || tag == 'b') nextInline['bold'] = true;
  if (tag == 'em' || tag == 'i') nextInline['italic'] = true;
  if (tag == 'u') nextInline['underline'] = true;
  if (tag == 'a') {
    final href = node.attributes['href'];
    if (_isSafeUrl(href)) nextInline['link'] = href;
  }

  if (tag == 'img') {
    final src = node.attributes['src'];
    final alt = node.attributes['alt'] ?? 'Image';
    if (_isSafeUrl(src)) {
      delta.insert(alt, nextInline.isEmpty ? null : nextInline);
      state.endsWithNewline = false;
      state.lastWasSpace = false;
      state.isEmpty = false;
    }
    return;
  }

  if (_blockTags.contains(tag) && !state.endsWithNewline && !state.isEmpty) {
    delta.insert('\n');
  }

  for (final child in node.nodes) {
    _appendNode(delta, child, nextInline, state);
  }

  final lineAttributes = <String, dynamic>{};
  if (tag == 'h1') lineAttributes['header'] = 1;
  if (tag == 'h2') lineAttributes['header'] = 2;
  if (tag == 'h3') lineAttributes['header'] = 3;
  if (tag == 'blockquote') lineAttributes['blockquote'] = true;
  if (tag == 'li') {
    final parent = node.parent?.localName?.toLowerCase();
    lineAttributes['list'] = parent == 'ol' ? 'ordered' : 'bullet';
  }

  if (_blockTags.contains(tag) && !state.endsWithNewline) {
    delta.insert('\n', lineAttributes.isEmpty ? null : lineAttributes);
    state.endsWithNewline = true;
    state.lastWasSpace = false;
    state.isEmpty = false;
  }
}

String _deltaToHtml(Delta delta) {
  final buffer = StringBuffer();
  final inline = StringBuffer();
  Map<String, dynamic>? lineAttributes;

  void flushLine() {
    final content = inline.isEmpty ? '<br>' : inline.toString();
    final attrs = lineAttributes ?? const <String, dynamic>{};
    if (attrs['header'] == 1) {
      buffer.write('<h1>$content</h1>');
    } else if (attrs['header'] == 2) {
      buffer.write('<h2>$content</h2>');
    } else if (attrs['header'] == 3) {
      buffer.write('<h3>$content</h3>');
    } else if (attrs['blockquote'] == true) {
      buffer.write('<blockquote>$content</blockquote>');
    } else if (attrs['list'] == 'ordered') {
      buffer.write('<ol><li>$content</li></ol>');
    } else if (attrs['list'] == 'bullet') {
      buffer.write('<ul><li>$content</li></ul>');
    } else {
      buffer.write('<p>$content</p>');
    }
    inline.clear();
    lineAttributes = null;
  }

  for (final operation in delta.toList()) {
    final data = operation.data;
    if (data is! String) continue;
    final attributes = operation.attributes ?? const <String, dynamic>{};
    final pieces = data.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i].isNotEmpty) {
        inline.write(_formatInline(pieces[i], attributes));
      }
      if (i < pieces.length - 1) {
        lineAttributes = attributes;
        flushLine();
      }
    }
  }
  if (inline.isNotEmpty) flushLine();
  return buffer.toString();
}

String _formatInline(String text, Map<String, dynamic> attributes) {
  var value = _escapeHtml(text);
  final link = attributes['link'];
  if (attributes['bold'] == true) value = '<strong>$value</strong>';
  if (attributes['italic'] == true) value = '<em>$value</em>';
  if (attributes['underline'] == true) value = '<u>$value</u>';
  if (link is String && _isSafeUrl(link)) {
    value = '<a href="${_escapeAttribute(link)}">$value</a>';
  }
  return value;
}

String _sanitizeNode(dom.Node node) {
  if (node is dom.Text) return _escapeHtml(node.text);
  if (node is! dom.Element) return '';

  final tag = node.localName?.toLowerCase() ?? '';
  if (tag == 'script' || tag == 'style') return '';
  if (tag == 'br') return '<br>';

  const allowedTags = {
    'p',
    'div',
    'span',
    'br',
    'strong',
    'b',
    'em',
    'i',
    'u',
    'h1',
    'h2',
    'h3',
    'ul',
    'ol',
    'li',
    'blockquote',
    'a',
    'img',
  };

  final children = node.nodes.map(_sanitizeNode).join();
  if (!allowedTags.contains(tag)) return children;

  final attrs = <String>[];
  if (tag == 'a') {
    final href = node.attributes['href'];
    if (_isSafeUrl(href)) {
      attrs.add('href="${_escapeAttribute(href!)}"');
      attrs.add('target="_blank"');
      attrs.add('rel="noopener noreferrer"');
    }
  }
  if (tag == 'img') {
    final src = node.attributes['src'];
    if (!_isSafeUrl(src)) return '';
    attrs.add('src="${_escapeAttribute(src!)}"');
    final alt = node.attributes['alt'];
    if (alt != null && alt.trim().isNotEmpty) {
      attrs.add('alt="${_escapeAttribute(alt)}"');
    }
    final title = node.attributes['title'];
    if (title != null && title.trim().isNotEmpty) {
      attrs.add('title="${_escapeAttribute(title)}"');
    }
  }

  final attrText = attrs.isEmpty ? '' : ' ${attrs.join(' ')}';
  if (tag == 'img') return '<img$attrText>';
  return '<$tag$attrText>$children</$tag>';
}

bool _isSafeUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final normalized = url.trim().toLowerCase();
  return normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('mailto:') ||
      normalized.startsWith('/');
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _escapeAttribute(String value) {
  return _escapeHtml(value).replaceAll('"', '&quot;');
}

class _HtmlState {
  bool endsWithNewline = true;
  bool lastWasSpace = false;
  bool isEmpty = true;
}
