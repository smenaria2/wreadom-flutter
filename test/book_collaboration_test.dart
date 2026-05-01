import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author.dart';
import 'package:librebook_flutter/src/domain/models/book.dart';
import 'package:librebook_flutter/src/presentation/routing/app_routes.dart';
import 'package:librebook_flutter/src/utils/book_collaboration_utils.dart';
import 'package:librebook_flutter/src/domain/models/app_notification.dart';
import 'package:librebook_flutter/src/utils/notification_target_resolver.dart';

void main() {
  test('serializes collaboration fields on books', () {
    final book = _book(
      collaborationStatus: collaborationStatusPending,
      collaboratorId: 'co1',
      collaboratorName: 'Co Author',
      collaboratorPhotoURL: 'https://example.test/photo.jpg',
      collaborationRequestedBy: 'author1',
      collaborationRequestedAt: 10,
      authorIds: const ['author1'],
    );

    final json = book.toJson()
      ..['authors'] = book.authors.map((author) => author.toJson()).toList();
    expect(json['collaborationStatus'], collaborationStatusPending);
    expect(json['collaboratorId'], 'co1');
    expect(json['collaboratorName'], 'Co Author');
    expect(json['authorIds'], ['author1']);

    final parsed = Book.fromJson(json);
    expect(parsed.collaboratorId, 'co1');
    expect(parsed.collaborationRequestedAt, 10);
  });

  test('accepted collaboration renders author with co-author', () {
    final book = _book(
      collaborationStatus: collaborationStatusAccepted,
      collaboratorId: 'co1',
      collaboratorName: 'Y Author',
      authorIds: const ['author1', 'co1'],
    );

    expect(collaborativeAuthorLine(book), 'X Author with Y Author');
  });

  test('accepted collaborator can edit but cannot delete', () {
    final book = _book(
      collaborationStatus: collaborationStatusAccepted,
      collaboratorId: 'co1',
      authorIds: const ['author1', 'co1'],
    );

    expect(canEditCollaborativeBook(book, 'author1'), isTrue);
    expect(canEditCollaborativeBook(book, 'co1'), isTrue);
    expect(canDeleteCollaborativeBook(book, 'co1'), isFalse);
  });

  test('collaboration notification opens request route', () {
    final target = NotificationTargetResolver.resolve(
      AppNotification(
        id: 'n1',
        userId: 'co1',
        actorId: 'author1',
        actorName: 'X Author',
        type: 'collaboration_request',
        text: 'X Author wants to collaborate with you.',
        link: '',
        targetId: 'book1',
        timestamp: 1,
        isRead: false,
        metadata: const {'bookId': 'book1'},
      ),
    );

    expect(target?.route, AppRoutes.collaborationRequest);
    expect(target?.payload, 'book1');
  });

  test('rules expose accepted edit and primary-only delete guards', () {
    final source = File('firestore.rules').readAsStringSync();

    expect(source, contains('function canEditBookData(data)'));
    expect(source, contains("data.collaborationStatus == 'accepted'"));
    expect(source, contains('allow delete: if isPrimaryBookAuthorData'));
    expect(source, contains('validCollaborationResponse()'));
  });

  test('functions fan out book notifications to accepted authors', () {
    final source = File('functions/index.js').readAsStringSync();

    expect(source, contains('function acceptedBookAuthorIds'));
    expect(source, contains('for (const ownerId of ownerIds)'));
    expect(source, contains('type: "collaboration_request"'));
    expect(source, contains('wants to collaborate with you.'));
  });
}

Book _book({
  String? collaborationStatus,
  String? collaboratorId,
  String? collaboratorName,
  String? collaboratorPhotoURL,
  String? collaborationRequestedBy,
  int? collaborationRequestedAt,
  List<String>? authorIds,
}) {
  return Book(
    id: 'book1',
    title: 'Book',
    authors: const [Author(name: 'X Author')],
    subjects: const [],
    languages: const ['en'],
    formats: const {},
    downloadCount: 0,
    mediaType: 'text',
    bookshelves: const [],
    isOriginal: true,
    authorId: 'author1',
    status: 'draft',
    collaborationStatus: collaborationStatus,
    collaboratorId: collaboratorId,
    collaboratorName: collaboratorName,
    collaboratorPhotoURL: collaboratorPhotoURL,
    collaborationRequestedBy: collaborationRequestedBy,
    collaborationRequestedAt: collaborationRequestedAt,
    authorIds: authorIds,
  );
}
