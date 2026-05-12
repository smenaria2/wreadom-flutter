import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../domain/models/chapter.dart';
import 'writer_html_codec.dart';
import 'writer_media_utils.dart';

const int chapterVersionMaxSnapshots = 10;
const int chapterVersionWordThreshold = 50;
const int chapterVersionTimeThresholdMillis = 5 * 60 * 1000;

bool shouldCreateChapterVersion({
  required String previousContent,
  required String currentContent,
  required int lastSavedAt,
  required int now,
  int wordThreshold = chapterVersionWordThreshold,
  int timeThresholdMillis = chapterVersionTimeThresholdMillis,
}) {
  final previous = sanitizeWriterHtml(previousContent);
  final current = sanitizeWriterHtml(currentContent);
  if (!_hasSnapshotContent(previous)) {
    return false;
  }
  if (previous.trim() == current.trim()) return false;

  if (_richContentSignature(previous) != _richContentSignature(current)) {
    return true;
  }

  final previousWordCount = wordCountFromHtml(previous);
  final currentWordCount = wordCountFromHtml(current);
  final wordCountDiff = (currentWordCount - previousWordCount).abs();
  final timeSinceLastSave = now - lastSavedAt;

  return wordCountDiff >= wordThreshold ||
      timeSinceLastSave >= timeThresholdMillis;
}

List<ChapterVersion> addChapterVersionSnapshot({
  required List<ChapterVersion> versions,
  required String content,
  required int timestamp,
  required int wordCount,
  int maxSnapshots = chapterVersionMaxSnapshots,
}) {
  final sanitizedContent = sanitizeWriterHtml(content);
  final next = <ChapterVersion>[
    ...versions,
    ChapterVersion(
      content: sanitizedContent,
      timestamp: timestamp,
      wordCount: wordCountFromHtml(sanitizedContent),
    ),
  ];
  if (next.length <= maxSnapshots) return next;
  return next.sublist(next.length - maxSnapshots);
}

List<ChapterVersion> restoreChapterVersionHistory({
  required List<ChapterVersion> versions,
  required String currentContent,
  required int now,
  int maxSnapshots = chapterVersionMaxSnapshots,
}) {
  final current = sanitizeWriterHtml(currentContent);
  if (!_hasSnapshotContent(current)) {
    return versions;
  }
  return addChapterVersionSnapshot(
    versions: versions,
    content: current,
    timestamp: now,
    wordCount: wordCountFromHtml(current),
    maxSnapshots: maxSnapshots,
  );
}

bool _hasSnapshotContent(String html) =>
    hasMeaningfulWriterHtml(html) || plainTextFromHtml(html).isNotEmpty;

String _richContentSignature(String html) {
  final fragment = html_parser.parseFragment(sanitizeWriterHtml(html));
  final parts = <String>[];

  void visit(dom.Node node) {
    if (node is dom.Element) {
      final tag = node.localName?.toLowerCase() ?? '';
      if (_formattingTags.contains(tag)) {
        parts.add('tag:$tag');
      }
      if (tag == 'img') {
        final src = node.attributes['src'];
        if (isTrustedCloudinaryImageUrl(src)) {
          parts.add('img:${src!.trim()}');
        }
      } else if (tag == 'a') {
        final href = node.attributes['href'];
        if (isAllowedWriterLink(href)) {
          parts.add('media:${href!.trim()}');
        }
      }
    }
    for (final child in node.nodes) {
      visit(child);
    }
  }

  for (final node in fragment.nodes) {
    visit(node);
  }
  return parts.join('|');
}

const _formattingTags = {
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
};
