import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/homepage/compiled_homepage.dart';

void main() {
  test('CompiledHomepage parses public shelves and audio posts', () {
    final homepage = CompiledHomepage.fromJson({
      'schemaVersion': 1,
      'generatedAt': 123,
      'ttlSeconds': 3600,
      'metadata': {
        'authors': [
          {'id': 'user-1', 'username': 'asha'},
        ],
        'dailyTopics': [
          {'id': 'topic-1', 'topicName': 'Write'},
        ],
        'homeBanners': [
          {'id': 'banner-1', 'title': 'Featured', 'isEnabled': true},
        ],
        'recommendationStats': {
          'book-1': {'upvotes': 2, 'downvotes': 0, 'recommendationCount': 2},
        },
      },
      'shelves': {
        'allBooks': [
          {
            'id': 'book-1',
            'title': 'First Book',
            'authors': [
              {'name': 'Asha'},
            ],
            'subjects': ['poetry'],
            'languages': ['en'],
            'formats': {},
            'download_count': 0,
            'media_type': 'text',
            'bookshelves': [],
            'status': 'published',
          },
        ],
        'authorWorks': [],
        'originals': [],
        'trending': [],
        'popular': [],
        'recent': [],
        'communityClassics': [
          {
            'id': 'archive-1',
            'title': 'Pride and Prejudice',
            'coverUrl': 'https://example.com/cover.jpg',
            'authors': [
              {'name': 'Jane Austen'},
            ],
            'subjects': ['classic'],
            'languages': ['en'],
            'formats': {},
            'download_count': 0,
            'media_type': 'text',
            'bookshelves': [],
            'source': 'archive',
            'status': 'published',
          },
        ],
        'booksWithLeaves': [
          {
            'id': 'leaf-book',
            'title': 'Leafy Book',
            'authors': [
              {'name': 'Asha'},
            ],
            'subjects': [],
            'languages': ['en'],
            'formats': {},
            'download_count': 0,
            'media_type': 'text',
            'bookshelves': [],
            'status': 'published',
            'hasLeaves': true,
            'leafCount': 1,
            'leaves': [
              {
                'id': 'leaf-1',
                'type': 'text',
                'createdBy': 'user-1',
                'createdAt': 123,
                'textPlain': 'Note',
              },
            ],
          },
        ],
        'series': [],
        'audioPosts': [
          {
            'id': 'post-1',
            'userId': 'user-1',
            'username': 'asha',
            'type': 'post',
            'text': 'Listen',
            'timestamp': 123,
            'likes': [],
            'visibility': 'public',
            'audioUrl': 'https://example.com/audio.m4a',
          },
        ],
        'genres': {
          'poetry': [
            {
              'id': 'book-1',
              'title': 'First Book',
              'authors': [
                {'name': 'Asha'},
              ],
              'subjects': ['poetry'],
              'languages': ['en'],
              'formats': {},
              'download_count': 0,
              'media_type': 'text',
              'bookshelves': [],
              'status': 'published',
            },
          ],
        },
      },
    });

    expect(homepage.hasPublicContent, true);
    expect(homepage.metadata.value.authors.single.username, 'asha');
    expect(homepage.metadata.homeBanners.single.title, 'Featured');
    expect(homepage.shelves.allBooks.single.title, 'First Book');
    expect(
      homepage.shelves.communityClassics.single.title,
      'Pride and Prejudice',
    );
    expect(
      homepage.shelves.communityClassics.single.authors.single.name,
      'Jane Austen',
    );
    expect(
      homepage.shelves.communityClassics.single.coverUrl,
      contains('cover.jpg'),
    );
    expect(homepage.shelves.booksWithLeaves.single.title, 'Leafy Book');
    expect(homepage.shelves.booksWithLeaves.single.leafCount, 1);
    expect(homepage.shelves.audioPosts.single.audioUrl, contains('audio.m4a'));
    expect(homepage.shelves.genreBooks('poetry').single.id, 'book-1');
  });
}
