import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Result of an immediate cache read plus a server refresh started afterwards.
class FirestoreCacheFirstResult<T> {
  const FirestoreCacheFirstResult({
    required this.cacheAvailable,
    required this.cached,
    required this.refresh,
  });

  final bool cacheAvailable;
  final T? cached;
  final Future<T?> refresh;
}

/// Keeps display reads responsive when a device has a slow or broken network.
///
/// Cache misses are expected on a first run and are intentionally not logged as
/// errors. Server failures are logged without paths, IDs, or document data.
class FirestoreCacheFirst {
  static const defaultServerTimeout = Duration(seconds: 4);

  static Future<
    FirestoreCacheFirstResult<DocumentSnapshot<Map<String, dynamic>>>
  >
  document(
    DocumentReference<Map<String, dynamic>> reference, {
    String operation = 'document_read',
    Duration serverTimeout = defaultServerTimeout,
  }) async {
    DocumentSnapshot<Map<String, dynamic>>? cached;
    var cacheAvailable = false;
    final stopwatch = Stopwatch()..start();
    try {
      cached = await reference.get(const GetOptions(source: Source.cache));
      cacheAvailable = true;
      logDiagnostic(operation, 'cache_hit', stopwatch.elapsed);
    } on FirebaseException catch (error) {
      logDiagnostic(operation, 'cache_miss', stopwatch.elapsed, error.code);
    }

    final refresh = _serverDocument(reference, operation, serverTimeout);
    if (cacheAvailable) unawaited(refresh);
    return FirestoreCacheFirstResult(
      cacheAvailable: cacheAvailable,
      cached: cached,
      refresh: refresh,
    );
  }

  static Future<FirestoreCacheFirstResult<QuerySnapshot<Map<String, dynamic>>>>
  query(
    Query<Map<String, dynamic>> reference, {
    String operation = 'query_read',
    Duration serverTimeout = defaultServerTimeout,
  }) async {
    QuerySnapshot<Map<String, dynamic>>? cached;
    var cacheAvailable = false;
    final stopwatch = Stopwatch()..start();
    try {
      cached = await reference.get(const GetOptions(source: Source.cache));
      // A cache-only query returns an empty snapshot both for a genuine empty
      // cached result and for a query the client has never cached. Treat empty
      // as a miss so first-run callers still obtain server data.
      cacheAvailable = cached.docs.isNotEmpty;
      logDiagnostic(
        operation,
        cacheAvailable ? 'cache_hit' : 'cache_miss',
        stopwatch.elapsed,
      );
    } on FirebaseException catch (error) {
      logDiagnostic(operation, 'cache_miss', stopwatch.elapsed, error.code);
    }

    final refresh = _serverQuery(reference, operation, serverTimeout);
    if (cacheAvailable) unawaited(refresh);
    return FirestoreCacheFirstResult(
      cacheAvailable: cacheAvailable,
      cached: cached,
      refresh: refresh,
    );
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> _serverDocument(
    DocumentReference<Map<String, dynamic>> reference,
    String operation,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final value = await reference
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      logDiagnostic(operation, 'server_success', stopwatch.elapsed);
      return value;
    } on TimeoutException {
      logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
    } on FirebaseException catch (error) {
      logDiagnostic(operation, 'server_error', stopwatch.elapsed, error.code);
    } catch (_) {
      logDiagnostic(operation, 'server_error', stopwatch.elapsed);
    }
    return null;
  }

  static Future<QuerySnapshot<Map<String, dynamic>>?> _serverQuery(
    Query<Map<String, dynamic>> reference,
    String operation,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final value = await reference
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      logDiagnostic(operation, 'server_success', stopwatch.elapsed);
      return value;
    } on TimeoutException {
      logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
    } on FirebaseException catch (error) {
      logDiagnostic(operation, 'server_error', stopwatch.elapsed, error.code);
    } catch (_) {
      logDiagnostic(operation, 'server_error', stopwatch.elapsed);
    }
    return null;
  }

  static void logDiagnostic(
    String operation,
    String outcome,
    Duration elapsed, [
    String? firebaseCode,
  ]) {
    unawaited(_writeDiagnostic(operation, outcome, elapsed, firebaseCode));
  }

  static Future<void> _writeDiagnostic(
    String operation,
    String outcome,
    Duration elapsed,
    String? firebaseCode,
  ) async {
    String transport = 'unavailable';
    try {
      final types = await Connectivity().checkConnectivity();
      transport = types.map((type) => type.name).join(',');
    } catch (_) {
      // Diagnostics must never delay or fail a user-facing read.
    }
    debugPrint(
      '[firestore_read] platform=${kIsWeb ? 'web' : defaultTargetPlatform.name} '
      'transport=$transport operation=$operation outcome=$outcome '
      'elapsed_ms=${elapsed.inMilliseconds}'
      '${firebaseCode == null ? '' : ' firebase_code=$firebaseCode'}',
    );
  }
}
