import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_storage.dart';

class ChapterManifest {
  const ChapterManifest(this.revision, this.entries);
  final int revision;
  final List<ChapterDirectoryEntry> entries;
}

class ChapterContentService {
  ChapterContentService(this.firestore);
  final FirebaseFirestore firestore;
  final Map<String, Future<String>> _inflight = {};

  Future<ChapterManifest> getManifest(String bookId) async {
    try {
      debugPrint('[ChapterContentService] getManifest starting for $bookId');
      final ref = firestore.collection('books').doc(bookId);
      // The manifest must be current: a cached book or partly cached directory
      // shows stale chapters or fails the count check. A plain get() reads the
      // server and falls back to the cache only when offline.
      final parent = await ref.get();
      requireChapterSchema(parent.data()?['chapterStorageVersion']);
      if (parent.data()?['status'] != 'published') {
        throw const ChapterStorageException(
          'missing',
          'This book is no longer published.',
        );
      }
      final revision = parent.data()?['manifestRevision'];
      if (revision is! int) {
        throw const ChapterStorageException(
          'invalid-data',
          'Book revision is missing.',
        );
      }
      final entries = <ChapterDirectoryEntry>[];
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      while (true) {
        Query<Map<String, dynamic>> query = ref
            .collection('chapterDirectory')
            .orderBy('orderKey')
            .limit(100);
        if (cursor != null) query = query.startAfterDocument(cursor);
        final page = await query.get();
        entries.addAll(
          page.docs.map(
            (doc) => ChapterDirectoryEntry.fromMap(doc.id, doc.data()),
          ),
        );
        if (page.docs.length < 100) break;
        cursor = page.docs.last;
      }
      debugPrint(
        '[ChapterContentService] getManifest loaded ${entries.length} entries for $bookId',
      );
      final after = await ref.get();
      if (after.data()?['manifestRevision'] != revision) {
        throw const ChapterStorageException(
          'revision-mismatch',
          'The chapter list changed. Please retry.',
        );
      }
      if (parent.data()?['chapterCount'] != entries.length) {
        throw const ChapterStorageException(
          'invalid-data',
          'The chapter directory is incomplete.',
        );
      }
      return ChapterManifest(revision, entries);
    } catch (e, stack) {
      debugPrint(
        '[ChapterContentService] getManifest error for $bookId: $e\n$stack',
      );
      rethrow;
    }
  }

  Future<String> getContent(String bookId, ChapterDirectoryEntry entry) {
    final key = '$bookId/${entry.id}/${entry.publishedRevision}';
    return _inflight.putIfAbsent(key, () async {
      try {
        debugPrint('[ChapterContentService] getContent starting for $key');
        final docRef = firestore
            .collection('books')
            .doc(bookId)
            .collection('chapters')
            .doc(entry.id);
        // Bodies are immutable per published revision, so a cached copy of
        // the same revision is safe to use.
        try {
          final cached = await docRef.get(
            const GetOptions(source: Source.cache),
          );
          if (cached.data()?['publishedRevision'] == entry.publishedRevision) {
            return entry.readBody(cached.data());
          }
        } catch (_) {
          // Not cached.
        }
        final snapshot = await docRef.get();
        final body = entry.readBody(snapshot.data());
        debugPrint(
          '[ChapterContentService] getContent loaded ${body.length} chars for $key',
        );
        return body;
      } catch (e, stack) {
        debugPrint(
          '[ChapterContentService] getContent error for $key: $e\n$stack',
        );
        rethrow;
      } finally {
        _inflight.remove(key);
      }
    });
  }

  Future<List<Chapter>> hydrate(String bookId) async {
    final manifest = await getManifest(bookId);
    final chapters = List<Chapter?>.filled(manifest.entries.length, null);
    var next = 0;
    await Future.wait(
      List.generate(chapters.length < 4 ? chapters.length : 4, (_) async {
        while (next < chapters.length) {
          final index = next++;
          final entry = manifest.entries[index];
          chapters[index] = Chapter(
            id: entry.id,
            title: entry.title,
            content: await getContent(bookId, entry),
            index: index,
            status: 'published',
            revision: entry.publishedRevision,
          );
        }
      }),
    );
    final DocumentSnapshot<Map<String, dynamic>> after;
    try {
      after = await firestore
          .collection('books')
          .doc(bookId)
          .get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const ChapterStorageException(
          'unavailable',
          'Could not reach the server. Check your connection and retry.',
        );
      }
      rethrow;
    }
    if (after.data()?['manifestRevision'] != manifest.revision) {
      throw const ChapterStorageException(
        'revision-mismatch',
        'The book changed during download. Please retry.',
      );
    }
    return chapters.cast<Chapter>();
  }
}
