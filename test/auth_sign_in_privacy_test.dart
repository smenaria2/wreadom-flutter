import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/repositories/firebase_auth_repository.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';

const _privateFields = [
  'email',
  'readingHistory',
  'savedBooks',
  'bookmarks',
  'notificationSettings',
  'readingProgress',
  'fcmTokens',
];

UserModel _fallback(String uid) => UserModel(
  id: uid,
  username: 'reader',
  email: 'reader@example.com',
  privacyLevel: 'public',
  readingHistory: const [],
  savedBooks: const [],
  bookmarks: const [],
);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseAuthRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseAuthRepository(firestore: firestore);
  });

  test('signing in a migrated user never writes private fields to the public doc', () async {
    await firestore.doc('users/u1').set({'id': 'u1', 'username': 'reader'});
    await firestore.doc('users/u1/private/account').set({
      'email': 'reader@example.com',
      'savedBooks': ['7'],
    });

    final raw = (await firestore.doc('users/u1').get()).data()!;
    final user = await repository.completeSignIn(
      uid: 'u1',
      authEmail: 'reader@example.com',
      raw: raw,
      fallbackUser: _fallback('u1'),
    );

    final publicDoc = (await firestore.doc('users/u1').get()).data()!;
    for (final field in _privateFields) {
      expect(publicDoc.containsKey(field), isFalse, reason: '$field leaked');
    }
    expect(publicDoc['lastLogin'], isA<int>());
    expect(user.email, 'reader@example.com');
    expect(user.savedBooks, ['7']);

    final account = (await firestore.doc('users/u1/private/account').get()).data()!;
    expect(account['notificationSettings'], isNotNull);
    expect(account['lastLogin'], isA<int>());
  });

  test('a user with no email on the public doc is not healed on every login', () async {
    await firestore.doc('users/u2').set({'id': 'u2', 'username': 'reader'});
    await firestore.doc('users/u2/private/account').set({'email': 'a@b.c'});

    for (var i = 0; i < 2; i++) {
      await repository.completeSignIn(
        uid: 'u2',
        authEmail: 'a@b.c',
        raw: (await firestore.doc('users/u2').get()).data()!,
        fallbackUser: _fallback('u2'),
      );
    }

    final publicDoc = (await firestore.doc('users/u2').get()).data()!;
    expect(publicDoc.keys.toSet(), {'id', 'username', 'lastLogin', 'searchTerms'});
  });

  test('legacy root values seed the private document once and are not rewritten', () async {
    await firestore.doc('users/u3').set({
      'id': 'u3',
      'username': 'legacy',
      'email': 'legacy@example.com',
      'readingHistory': ['1'],
      'savedBooks': ['2'],
      'bookmarks': <dynamic>[],
    });

    final user = await repository.completeSignIn(
      uid: 'u3',
      authEmail: 'legacy@example.com',
      raw: (await firestore.doc('users/u3').get()).data()!,
      fallbackUser: _fallback('u3'),
    );

    final account = (await firestore.doc('users/u3/private/account').get()).data()!;
    expect(account['email'], 'legacy@example.com');
    expect(account['readingHistory'], ['1']);
    expect(account['savedBooks'], ['2']);
    expect(user.savedBooks, ['2']);
  });

  test('a missing username is the only thing healed on the public doc', () async {
    await firestore.doc('users/u4').set({'id': 'u4'});

    await repository.completeSignIn(
      uid: 'u4',
      displayName: 'Named Reader',
      authEmail: 'n@example.com',
      raw: (await firestore.doc('users/u4').get()).data()!,
      fallbackUser: _fallback('u4'),
    );

    final publicDoc = (await firestore.doc('users/u4').get()).data()!;
    expect(publicDoc['username'], 'Named Reader');
    expect(publicDoc['privacyLevel'], 'public');
    for (final field in _privateFields) {
      expect(publicDoc.containsKey(field), isFalse, reason: '$field leaked');
    }
  });
}
