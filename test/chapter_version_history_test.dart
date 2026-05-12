import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/chapter.dart';
import 'package:librebook_flutter/src/presentation/utils/chapter_version_history.dart';

void main() {
  group('chapter version history', () {
    test('does not snapshot tiny edits before five minutes', () {
      final shouldSnapshot = shouldCreateChapterVersion(
        previousContent: '<p>one two three</p>',
        currentContent: '<p>one two three four</p>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 2).inMilliseconds,
      );

      expect(shouldSnapshot, isFalse);
    });

    test('snapshots formatting-only edits before five minutes', () {
      final shouldSnapshot = shouldCreateChapterVersion(
        previousContent: '<p>one two three</p>',
        currentContent:
            '<blockquote><strong>one two three</strong></blockquote>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 1).inMilliseconds,
      );

      expect(shouldSnapshot, isTrue);
    });

    test('snapshots image and media edits before five minutes', () {
      const image =
          'https://res.cloudinary.com/demo/image/upload/f_auto/sample.jpg';
      const media = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

      final shouldSnapshotImage = shouldCreateChapterVersion(
        previousContent: '<p>one two three</p>',
        currentContent: '<p>one two three</p><p><img src="$image"></p>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 1).inMilliseconds,
      );
      final shouldSnapshotMedia = shouldCreateChapterVersion(
        previousContent: '<p>one two three</p>',
        currentContent:
            '<p>one two three</p><p><a href="$media">YouTube</a></p>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 1).inMilliseconds,
      );

      expect(shouldSnapshotImage, isTrue);
      expect(shouldSnapshotMedia, isTrue);
    });

    test('snapshots after a 50 word change', () {
      final previous = List.filled(10, 'old').join(' ');
      final current = List.filled(61, 'new').join(' ');

      final shouldSnapshot = shouldCreateChapterVersion(
        previousContent: '<p>$previous</p>',
        currentContent: '<p>$current</p>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 1).inMilliseconds,
      );

      expect(shouldSnapshot, isTrue);
    });

    test('snapshots after five minutes even with smaller edits', () {
      final shouldSnapshot = shouldCreateChapterVersion(
        previousContent: '<p>one two three</p>',
        currentContent: '<p>one two three four</p>',
        lastSavedAt: 1000,
        now: 1000 + const Duration(minutes: 5).inMilliseconds,
      );

      expect(shouldSnapshot, isTrue);
    });

    test('caps history to the last 10 versions', () {
      var versions = List.generate(
        10,
        (index) => ChapterVersion(
          content: '<p>$index</p>',
          timestamp: index,
          wordCount: 1,
        ),
      );

      versions = addChapterVersionSnapshot(
        versions: versions,
        content: '<p>10</p>',
        timestamp: 10,
        wordCount: 1,
      );

      expect(versions.length, 10);
      expect(versions.first.timestamp, 1);
      expect(versions.last.timestamp, 10);
    });

    test('restore pushes current content before replacing it', () {
      final versions = restoreChapterVersionHistory(
        versions: const [],
        currentContent: '<p>current content</p>',
        now: 1234,
      );

      expect(versions, hasLength(1));
      expect(versions.single.content, '<p>current content</p>');
      expect(versions.single.timestamp, 1234);
      expect(versions.single.wordCount, 2);
    });

    test('restore snapshots sanitized rich html with media and formatting', () {
      const image =
          'https://res.cloudinary.com/demo/image/upload/f_auto/sample.jpg';
      const media = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final versions = restoreChapterVersionHistory(
        versions: const [],
        currentContent:
            '<h2>Current</h2><p><strong>rich</strong> text</p>'
            '<p><img src="$image" onerror="bad()"></p>'
            '<p><a href="$media" onclick="bad()">YouTube</a></p>',
        now: 1234,
      );

      expect(versions, hasLength(1));
      expect(versions.single.content, contains('<h2>Current</h2>'));
      expect(versions.single.content, contains('<strong>rich</strong>'));
      expect(versions.single.content, contains('<img src="$image">'));
      expect(versions.single.content, contains('href="$media"'));
      expect(versions.single.content, isNot(contains('onerror')));
      expect(versions.single.content, isNot(contains('onclick')));
    });
  });
}
