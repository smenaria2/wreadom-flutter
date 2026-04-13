import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/book.dart';
import '../../domain/models/author.dart';

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
      if (query.contains(':') && RegExp(r'^[a-z]+:', caseSensitive: false).hasMatch(query)) {
        queryParts.add(query);
      } else {
        final cleanSearch = Uri.encodeComponent(query);
        queryParts.add('(title:(*$cleanSearch*) OR creator:(*$cleanSearch*))');
      }
    }

    if (language != null) {
      if (language.toLowerCase() == 'hindi') {
        queryParts.add('(language:hi OR language:hin OR language:hindi)');
      } else {
        queryParts.add('language:$language');
      }
    }

    if (subject != null) queryParts.add('subject:${Uri.encodeComponent(subject)}');

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

    return {
      'count': data['response']['numFound'] ?? 0,
      'results': results,
    };
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

  Book _archiveDocToBook(Map<String, dynamic> doc) {
    final identifier = doc['identifier'] as String;
    final title = doc['title'] ?? 'Untitled';
    final creators = doc['creator'] is List ? List<String>.from(doc['creator']) : (doc['creator'] != null ? [doc['creator'].toString()] : <String>[]);
    final subjects = doc['subject'] is List ? List<String>.from(doc['subject']) : (doc['subject'] != null ? [doc['subject'].toString()] : <String>[]);
    final languages = doc['language'] is List ? List<String>.from(doc['language']) : (doc['language'] != null ? [doc['language'].toString()] : <String>[]);
    final collections = doc['collection'] is List ? List<String>.from(doc['collection']) : (doc['collection'] != null ? [doc['collection'].toString()] : <String>[]);

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
      downloadCount: doc['downloads'] ?? 0,
      mediaType: doc['mediatype'] ?? 'texts',
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

    final identifier = meta['identifier'] as String;
    final creators = meta['creator'] is List ? List<String>.from(meta['creator']) : (meta['creator'] != null ? [meta['creator'].toString()] : <String>[]);
    final subjects = meta['subject'] is List ? List<String>.from(meta['subject']) : (meta['subject'] != null ? [meta['subject'].toString()] : <String>[]);
    final languages = meta['language'] is List ? List<String>.from(meta['language']) : (meta['language'] != null ? [meta['language'].toString()] : <String>[]);
    final collections = meta['collection'] is List ? List<String>.from(meta['collection']) : (meta['collection'] != null ? [meta['collection'].toString()] : <String>[]);

    final formats = <String, String>{};
    final baseUrl = 'https://archive.org/download/$identifier';
    final files = (data['files'] as List? ?? []);

    String? textFile;
    String? pdfFile;

    for (final file in files) {
      final name = (file['name'] as String? ?? '').toLowerCase();
      final format = (file['format'] as String? ?? '').toLowerCase();

      if (name.endsWith('_djvu.txt')) {
        textFile = file['name'];
        break;
      } else if (format.contains('text') || name.endsWith('.txt')) {
        textFile ??= file['name'];
      }
      if (format.contains('pdf') || name.endsWith('.pdf')) {
        pdfFile ??= file['name'];
      }
    }

    if (textFile != null) {
      formats['text/plain; charset=utf-8'] = '$baseUrl/${Uri.encodeComponent(textFile)}';
      formats['text/plain'] = '$baseUrl/${Uri.encodeComponent(textFile)}';
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
      title: meta['title'] ?? 'Untitled',
      authors: creators.map((name) => Author(name: name)).toList(),
      subjects: subjects.take(10).toList(),
      languages: languages.map(_normalizeLanguage).toList(),
      formats: formats,
      downloadCount: 0,
      mediaType: meta['mediatype'] ?? 'texts',
      bookshelves: collections,
      source: 'archive',
      coverUrl: 'https://archive.org/services/img/$identifier',
      year: meta['year'],
      description: meta['description'] ?? '',
    );
  }

  String _normalizeLanguage(String lang) {
    if (lang.isEmpty) return 'Unknown';
    final l = lang.toLowerCase().trim();
    if (l == 'hindi' || l == 'hin' || l == 'hi') return 'Hindi';
    if (l == 'english' || l == 'eng' || l == 'en') return 'English';
    return lang[0].toUpperCase() + lang.substring(1).toLowerCase();
  }
}
