import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/utils/firestore_cache_first.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an existing cached document before server refresh', () async {
    final firestore = FakeFirebaseFirestore();
    final reference = firestore.collection('books').doc('cached');
    await reference.set({'title': 'Cached'});

    final result = await FirestoreCacheFirst.document(
      reference,
      operation: 'test_cache_hit',
      requestKey: 'test-cache-hit',
    );

    expect(result.cacheAvailable, isTrue);
    expect(result.cached?.data()?['title'], 'Cached');
    expect((await result.refresh)?.data()?['title'], 'Cached');
  });

  test('treats an absent cached document as a normal miss', () async {
    final firestore = FakeFirebaseFirestore();
    final reference = firestore.collection('books').doc('missing');

    final result = await FirestoreCacheFirst.document(
      reference,
      operation: 'test_cache_miss',
      requestKey: 'test-cache-miss',
    );

    expect(result.cacheAvailable, isFalse);
    expect(result.cached?.exists, isFalse);
    expect((await result.refresh)?.exists, isFalse);
  });

  test('bounds a slow server refresh and preserves the cache result', () async {
    final firestore = FakeFirebaseFirestore();
    final reference = firestore.collection('books').doc('slow');
    await reference.set({'title': 'Cached'});
    final serverCompleter = Completer<DocumentSnapshot<Map<String, dynamic>>>();

    final result = await FirestoreCacheFirst.document(
      reference,
      operation: 'test_timeout',
      requestKey: 'test-timeout',
      serverTimeout: const Duration(milliseconds: 5),
      serverLoader: () => serverCompleter.future,
    );

    expect(result.cacheAvailable, isTrue);
    expect(await result.refresh, isNull);
    expect(result.cached?.data()?['title'], 'Cached');
    serverCompleter.complete(await reference.get());
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'converts a Firebase server error to nonblocking refresh metadata',
    () async {
      final firestore = FakeFirebaseFirestore();
      final reference = firestore.collection('books').doc('error');

      final result = await FirestoreCacheFirst.document(
        reference,
        operation: 'test_error',
        requestKey: 'test-error',
        serverLoader: () => Future.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
      );

      expect(result.cacheAvailable, isFalse);
      expect(await result.refresh, isNull);
    },
  );

  test(
    'shares equivalent refreshes and suppresses immediate repeats',
    () async {
      final firestore = FakeFirebaseFirestore();
      final reference = firestore.collection('books').doc('shared');
      final completer = Completer<DocumentSnapshot<Map<String, dynamic>>>();
      var calls = 0;

      Future<DocumentSnapshot<Map<String, dynamic>>> loader() {
        calls++;
        return completer.future;
      }

      final first = await FirestoreCacheFirst.document(
        reference,
        operation: 'test_shared',
        requestKey: 'test-shared',
        serverLoader: loader,
      );
      final second = await FirestoreCacheFirst.document(
        reference,
        operation: 'test_shared',
        requestKey: 'test-shared',
        serverLoader: loader,
      );
      expect(second.metadata.refreshShared, isTrue);
      expect(calls, 1);

      await reference.set({'title': 'Server'});
      completer.complete(await reference.get());
      await Future.wait([first.refresh, second.refresh]);

      final third = await FirestoreCacheFirst.document(
        reference,
        operation: 'test_shared',
        requestKey: 'test-shared',
        serverLoader: loader,
      );
      expect(third.metadata.refreshSuppressed, isTrue);
      expect(calls, 1);
    },
  );

  test('queued reads share the same overall timeout budget', () async {
    final firestore = FakeFirebaseFirestore();
    var serverCalls = 0;
    final pending = <Completer<DocumentSnapshot<Map<String, dynamic>>>>[];
    Future<DocumentSnapshot<Map<String, dynamic>>> neverCompletes() {
      serverCalls++;
      final completer = Completer<DocumentSnapshot<Map<String, dynamic>>>();
      pending.add(completer);
      return completer.future;
    }

    final results = await Future.wait([
      for (var index = 0; index < 5; index++)
        FirestoreCacheFirst.document(
          firestore.collection('books').doc('queued-$index'),
          operation: 'test_queue_budget',
          requestKey: 'test-queue-budget-$index',
          serverTimeout: const Duration(milliseconds: 100),
          serverLoader: neverCompletes,
        ),
    ]);

    expect(await Future.wait(results.map((result) => result.refresh)), [
      null,
      null,
      null,
      null,
      null,
    ]);
    expect(serverCalls, 4);
    final releaseSnapshot = await firestore
        .collection('books')
        .doc('release')
        .get();
    for (final completer in pending) {
      completer.complete(releaseSnapshot);
    }
    await Future<void>.delayed(Duration.zero);
  });
}
