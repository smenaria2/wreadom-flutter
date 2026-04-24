import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import '../../domain/models/book.dart';
import '../../domain/models/author.dart';
import '../../domain/models/chapter.dart';

class ArchiveBookService {
  static const String searchUrl = 'https://archive.org/advancedsearch.php';
  static const String metadataUrl = 'https://archive.org/metadata';

  Future<Map<String, dynamic>> searchBooks({
    String? query,
    String? title,
    String? creator,
    String? identifier,
    String? language,
    String? subject,
    int page = 1,
    int rows = 20,
    String sort = 'downloads desc',
  }) async {
    final queryParts = ['mediatype:texts'];

    if (title != null) queryParts.add('title:("$title")');
    if (creator != null) queryParts.add('creator:("$creator")');
    if (identifier != null) queryParts.add('identifier:($identifier)');

    if (query != null && query.isNotEmpty) {
      if (query.contains(':') &&
          RegExp(r'^[a-z]+:', caseSensitive: false).hasMatch(query)) {
        final lower = query.toLowerCase();
        if (lower.startsWith('topic:') || lower.startsWith('subject:')) {
          final term = query.substring(query.indexOf(':') + 1).trim();
          queryParts.add('subject:("$term")');
        } else {
          queryParts.add(query);
        }
      } else {
        final cleanSearch = query.replaceAll('"', '').trim();
        queryParts.add(
          '(title:("$cleanSearch") OR creator:("$cleanSearch") OR subject:("$cleanSearch"))',
        );
      }
    }

    if (language != null) {
      if (language.toLowerCase() == 'hindi') {
        queryParts.add('(language:hi OR language:hin OR language:hindi)');
      } else {
        queryParts.add('language:$language');
      }
    }

    if (subject != null) {
      queryParts.add('subject:${Uri.encodeComponent(subject)}');
    }

    final q = queryParts.join(' AND ');
    final url = Uri.parse(
      '$searchUrl?q=${Uri.encodeComponent(q)}'
      '&fl[]=identifier,title,creator,year,language,downloads,subject,collection'
      '&rows=$rows&page=$page&sort[]=${Uri.encodeComponent(sort)}&output=json',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Archive books');
    }

    final data = jsonDecode(response.body);
    final docs = (data['response']['docs'] as List? ?? []);
    final results = docs.map((doc) => _archiveDocToBook(doc)).toList();

    return {'count': data['response']['numFound'] ?? 0, 'results': results};
  }

  Future<Book> getBookMetadata(String identifier) async {
    final url = Uri.parse('$metadataUrl/$identifier');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Book not found in archives');
    }

    final data = jsonDecode(response.body);
    return _archiveMetadataToBook(data);
  }

  Future<List<Book>> getBooksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Construct a query for multiple identifiers: identifier:(id1 OR id2 OR ...)
    final identifiersQuery = ids.map((id) => '"$id"').join(' OR ');

    // We use searchBooks logic but specifically for these IDs
    final result = await searchBooks(
      identifier: identifiersQuery,
      rows: ids.length,
    );

    return result['results'] as List<Book>;
  }

  Future<List<Chapter>> fetchBookChapters(String identifier) async {
    // 1. Get metadata to find the right text file
    final metaUrl = Uri.parse('$metadataUrl/$identifier');
    final metaResponse = await http.get(metaUrl);
    if (metaResponse.statusCode != 200) {
      throw Exception('Metadata fetch failed');
    }
    final metaData = jsonDecode(metaResponse.body);

    final files = (metaData['files'] as List? ?? []);
    final preferredSource = _preferredReadableSource(files);
    if (preferredSource == null) {
      throw Exception('No text file found for this book');
    }

    final baseUrl = 'https://archive.org/download/$identifier';
    final contentUrl = Uri.parse(
      '$baseUrl/${Uri.encodeComponent(preferredSource.name)}',
    );
    final response = await http.get(contentUrl);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch book content');
    }

    if (preferredSource.kind == _ArchiveReadableKind.epub) {
      return _parseEpubToChapters(response.bodyBytes);
    }

    final text = preferredSource.kind == _ArchiveReadableKind.html
        ? _extractReadableTextFromHtml(response.body)
        : response.body;
    return compute(_parseArchiveTextToChaptersOnIsolate, text);
  }

  List<Chapter> _parseTextToChapters(String text) {
    if (text.isEmpty) return [];

    // Clean text: remove excessive whitespace
    final cleanedText = text
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Regex for chapter detection (English, Hindi, Bengali)
    final chapterRegex = RegExp(
      r'^(?:chapter|lesson|unit|section|part|chapter\s+\d+|ch\s+\d+|অধ্যায়\s+\d+|अध्याय\s+\d+)\s*[:.\-\s]*.*$',
      multiLine: true,
      caseSensitive: false,
    );

    final matches = chapterRegex.allMatches(cleanedText).toList();
    final chapters = <Chapter>[];

    if (matches.isEmpty) {
      return _splitIntoReadableChunks(cleanedText);
    }

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length)
          ? matches[i + 1].start
          : cleanedText.length;

      final titleLine = matches[i].group(0) ?? 'Chapter ${i + 1}';
      final content = cleanedText.substring(start, end).trim();

      if (content.length > 50) {
        // Filter out very small fragments
        chapters.add(
          Chapter(
            id: (i + 1).toString(),
            title: titleLine.trim(),
            content: content,
            index: i,
          ),
        );
      }
    }

    // If parsing produced very few chapters or failed to capture most of the text
    if (chapters.isEmpty) {
      return [
        Chapter(id: '1', title: 'Content', content: cleanedText, index: 0),
      ];
    }

    return chapters;
  }

  List<Chapter> _splitIntoReadableChunks(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    const wordsPerChunk = 2000;
    final chapters = <Chapter>[];
    for (var start = 0; start < words.length; start += wordsPerChunk) {
      final end = (start + wordsPerChunk).clamp(0, words.length);
      final index = chapters.length;
      chapters.add(
        Chapter(
          id: '${index + 1}',
          title: index == 0 ? 'First Chapter' : 'Part ${index + 1}',
          content: words.sublist(start, end).join(' '),
          index: index,
        ),
      );
    }
    return chapters;
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      final text = value['value'] ?? value['text'] ?? value['name'];
      return text?.toString() ?? fallback;
    }
    return value.toString();
  }

  List<String> _stringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) => _stringValue(e).trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final text = _stringValue(value).trim();
    return text.isEmpty ? <String>[] : <String>[text];
  }

  Book _archiveDocToBook(Map<String, dynamic> doc) {
    final identifier = _stringValue(doc['identifier']);
    final title = _stringValue(doc['title'], fallback: 'Untitled');
    final creators = _stringList(doc['creator']);
    final subjects = _stringList(doc['subject']);
    final languages = _stringList(doc['language']);
    final collections = _stringList(doc['collection']);

    final authors = creators.map((name) => Author(name: name)).toList();
    final baseDownloadUrl = 'https://archive.org/download/$identifier';

    return Book(
      id: identifier,
      identifier: identifier,
      title: title,
      authors: authors,
      subjects: subjects.take(5).toList(),
      languages: languages.map(_normalizeLanguage).toList(),
      formats: {
        'text/plain; charset=utf-8': '$baseDownloadUrl/${identifier}_djvu.txt',
        'text/plain': '$baseDownloadUrl/${identifier}_djvu.txt',
      },
      downloadCount: (doc['downloads'] as num?)?.toInt() ?? 0,
      mediaType: _stringValue(doc['mediatype'], fallback: 'texts'),
      bookshelves: collections,
      source: 'archive',
      coverUrl: 'https://archive.org/services/img/$identifier',
      year: doc['year'],
      description: '',
    );
  }

  Book _archiveMetadataToBook(Map<String, dynamic> data) {
    final meta = data['metadata'];
    if (meta == null) throw Exception('Metadata missing');

    final identifier = _stringValue(meta['identifier']);
    final creators = _stringList(meta['creator']);
    final subjects = _stringList(meta['subject']);
    final languages = _stringList(meta['language']);
    final collections = _stringList(meta['collection']);

    final formats = <String, String>{};
    final baseUrl = 'https://archive.org/download/$identifier';
    final files = (data['files'] as List? ?? []);

    String? htmlFile;
    String? epubFile;
    String? textFile;
    String? djvuTextFile;
    String? pdfFile;

    for (final file in files) {
      if (file is! Map) continue;
      final rawName = file['name']?.toString() ?? '';
      final name = rawName.toLowerCase();
      final format = (file['format']?.toString() ?? '').toLowerCase();

      if ((format.contains('html') || name.endsWith('.html') || name.endsWith('.htm')) &&
          !name.contains('_djvu')) {
        htmlFile ??= rawName;
      } else if (format.contains('epub') || name.endsWith('.epub')) {
        epubFile ??= rawName;
      } else if (name.endsWith('_djvu.txt')) {
        djvuTextFile ??= rawName;
      } else if (format.contains('text') || name.endsWith('.txt')) {
        textFile ??= rawName;
      }
      if (format.contains('pdf') || name.endsWith('.pdf')) {
        pdfFile ??= rawName;
      }
    }

    if (htmlFile != null) {
      formats['text/html'] = '$baseUrl/${Uri.encodeComponent(htmlFile)}';
    }
    if (epubFile != null) {
      formats['application/epub+zip'] = '$baseUrl/${Uri.encodeComponent(epubFile)}';
    }
    if (textFile != null) {
      formats['text/plain; charset=utf-8'] =
          '$baseUrl/${Uri.encodeComponent(textFile)}';
      formats['text/plain'] = '$baseUrl/${Uri.encodeComponent(textFile)}';
    }
    if (djvuTextFile != null) {
      formats['text/plain; ocr'] = '$baseUrl/${Uri.encodeComponent(djvuTextFile)}';
    }
    if (pdfFile != null) {
      formats['application/pdf'] = '$baseUrl/${Uri.encodeComponent(pdfFile)}';
    }

    if (formats.isEmpty) {
      formats['text/plain'] = '$baseUrl/${identifier}_djvu.txt';
    }

    return Book(
      id: identifier,
      identifier: identifier,
      title: _stringValue(meta['title'], fallback: 'Untitled'),
      authors: creators.map((name) => Author(name: name)).toList(),
      subjects: subjects.take(10).toList(),
      languages: languages.map(_normalizeLanguage).toList(),
      formats: formats,
      downloadCount: 0,
      mediaType: _stringValue(meta['mediatype'], fallback: 'texts'),
      bookshelves: collections,
      source: 'archive',
      coverUrl: 'https://archive.org/services/img/$identifier',
      year: meta['year'],
      description: _stringValue(meta['description']),
    );
  }

  String _normalizeLanguage(String lang) {
    if (lang.isEmpty) return 'Unknown';
    final l = lang.toLowerCase().trim();
    if (l == 'hindi' || l == 'hin' || l == 'hi') return 'Hindi';
    if (l == 'english' || l == 'eng' || l == 'en') return 'English';
    return lang[0].toUpperCase() + lang.substring(1).toLowerCase();
  }

  _ArchiveReadableSource? _preferredReadableSource(List files) {
    String? htmlFile;
    String? epubFile;
    String? textFile;
    String? djvuTextFile;

    for (final file in files) {
      if (file is! Map) continue;
      final rawName = file['name']?.toString() ?? '';
      final name = rawName.toLowerCase();
      final format = (file['format']?.toString() ?? '').toLowerCase();

      if ((format.contains('html') || name.endsWith('.html') || name.endsWith('.htm')) &&
          !name.contains('_djvu')) {
        htmlFile ??= rawName;
        continue;
      }
      if (format.contains('epub') || name.endsWith('.epub')) {
        epubFile ??= rawName;
        continue;
      }
      if (name.endsWith('_djvu.txt')) {
        djvuTextFile ??= rawName;
        continue;
      }
      if (format.contains('text') || name.endsWith('.txt')) {
        textFile ??= rawName;
      }
    }

    if (htmlFile != null) {
      return _ArchiveReadableSource(_ArchiveReadableKind.html, htmlFile);
    }
    if (epubFile != null) {
      return _ArchiveReadableSource(_ArchiveReadableKind.epub, epubFile);
    }
    if (textFile != null) {
      return _ArchiveReadableSource(_ArchiveReadableKind.text, textFile);
    }
    if (djvuTextFile != null) {
      return _ArchiveReadableSource(_ArchiveReadableKind.djvuText, djvuTextFile);
    }
    return null;
  }

  String _extractReadableTextFromHtml(String html) {
    final document = html_parser.parse(html);
    document.querySelectorAll('script, style, noscript').forEach((node) {
      node.remove();
    });
    final bodyText = document.body?.text ?? document.documentElement?.text ?? '';
    return bodyText
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  List<Chapter> _parseEpubToChapters(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    final packagePath = _findEpubPackagePath(archive);
    final packageEntry =
        packagePath == null ? null : archive.findFile(packagePath);
    final packageText = packageEntry == null
        ? null
        : utf8.decode(packageEntry.content as List<int>, allowMalformed: true);

    final contentFiles = <String>[];
    if (packagePath != null && packageText != null) {
      final manifest = <String, String>{};
      final itemRegex = RegExp(
        r'<item\b[^>]*id="([^"]+)"[^>]*href="([^"]+)"[^>]*media-type="([^"]+)"[^>]*\/?>',
        caseSensitive: false,
      );
      for (final match in itemRegex.allMatches(packageText)) {
        final mediaType = match.group(3)?.toLowerCase() ?? '';
        if (!mediaType.contains('html') && !mediaType.contains('xhtml')) {
          continue;
        }
        manifest[match.group(1)!] = match.group(2)!;
      }

      final baseDir = p.url.dirname(packagePath);
      final spineRegex = RegExp(
        r'<itemref\b[^>]*idref="([^"]+)"[^>]*\/?>',
        caseSensitive: false,
      );
      for (final match in spineRegex.allMatches(packageText)) {
        final href = manifest[match.group(1)!];
        if (href == null) continue;
        contentFiles.add(p.url.normalize(p.url.join(baseDir, href)));
      }
    }

    if (contentFiles.isEmpty) {
      contentFiles.addAll(
        archive.files
            .where(
              (file) =>
                  !file.isFile
                      ? false
                      : file.name.toLowerCase().endsWith('.xhtml') ||
                            file.name.toLowerCase().endsWith('.html') ||
                            file.name.toLowerCase().endsWith('.htm'),
            )
            .map((file) => file.name),
      );
    }

    final chapters = <Chapter>[];
    for (final path in contentFiles) {
      final entry = archive.findFile(path);
      if (entry == null || !entry.isFile) continue;
      final html = utf8.decode(entry.content as List<int>, allowMalformed: true);
      final text = _extractReadableTextFromHtml(html);
      if (text.trim().isEmpty) continue;
      final title = _epubTitleFromHtml(html) ?? 'Chapter ${chapters.length + 1}';
      chapters.add(
        Chapter(
          id: '${chapters.length + 1}',
          title: title,
          content: text,
          index: chapters.length,
        ),
      );
    }

    if (chapters.isNotEmpty) {
      return chapters;
    }
    return _splitIntoReadableChunks(''); // fall through to empty result
  }

  String? _findEpubPackagePath(Archive archive) {
    final container = archive.findFile('META-INF/container.xml');
    if (container != null) {
      final text = utf8.decode(container.content as List<int>, allowMalformed: true);
      final match = RegExp(r'full-path="([^"]+\.opf)"', caseSensitive: false)
          .firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }

    for (final file in archive.files) {
      if (file.isFile && file.name.toLowerCase().endsWith('.opf')) {
        return file.name;
      }
    }
    return null;
  }

  String? _epubTitleFromHtml(String html) {
    final document = html_parser.parse(html);
    final heading = document.querySelector('h1, h2, h3')?.text.trim();
    if (heading != null && heading.isNotEmpty) {
      return heading;
    }
    final title = document.querySelector('title')?.text.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return null;
  }
}

List<Chapter> _parseArchiveTextToChaptersOnIsolate(String text) {
  return ArchiveBookService()._parseTextToChapters(text);
}

enum _ArchiveReadableKind { html, epub, text, djvuText }

class _ArchiveReadableSource {
  const _ArchiveReadableSource(this.kind, this.name);

  final _ArchiveReadableKind kind;
  final String name;
}
