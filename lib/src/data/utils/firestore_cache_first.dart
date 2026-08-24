import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../services/startup_performance.dart';

class FirestoreReadMetadata {
  const FirestoreReadMetadata({
    required this.operation,
    required this.cacheElapsed,
    required this.refreshShared,
    required this.refreshSuppressed,
  });

  final String operation;
  final Duration cacheElapsed;
  final bool refreshShared;
  final bool refreshSuppressed;
}

/// Result of an immediate cache read plus a server refresh started afterwards.
class FirestoreCacheFirstResult<T> {
  const FirestoreCacheFirstResult({
    required this.cacheAvailable,
    required this.cached,
    required this.refresh,
    required this.metadata,
  });

  final bool cacheAvailable;
  final T? cached;
  final Future<T?> refresh;
  final FirestoreReadMetadata metadata;
}

class _CoalescedRefresh<T> {
  const _CoalescedRefresh(
    this.future, {
    this.shared = false,
    this.suppressed = false,
  });

  final Future<T?> future;
  final bool shared;
  final bool suppressed;
}

class _PendingServerTimeout implements Exception {
  const _PendingServerTimeout(this.completion);

  final Future<void> completion;
}

/// Keeps display reads responsive when a device has a slow or broken network.
///
/// Cache misses are expected on a first run and are intentionally not logged as
/// errors. Server failures are logged without paths, IDs, or document data.
class FirestoreCacheFirst {
  static const defaultServerTimeout = Duration(seconds: 4);
  static const _refreshCooldown = Duration(seconds: 2);
  static final Map<String, Future<Object?>> _inFlight = {};
  static final Map<String, ({DateTime at, Object? value})> _recent = {};
  static const int _maxConcurrentServerReads = 4;
  static int _activeServerReads = 0;
  static final List<Completer<void>> _serverWaiters = [];
  static String _cachedTransport = 'unavailable';
  static DateTime? _transportCheckedAt;
  static Future<String>? _transportLookup;

  /// Performs only an immediate local Firestore cache lookup.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> cachedDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String operation = 'document_cache_read',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final value = await reference.get(const GetOptions(source: Source.cache));
      logDiagnostic(
        operation,
        value.exists ? 'cache_hit' : 'cache_miss',
        stopwatch.elapsed,
      );
      return value.exists ? value : null;
    } catch (error) {
      logDiagnostic(
        operation,
        'cache_miss',
        stopwatch.elapsed,
        error is FirebaseException ? error.code : null,
      );
      return null;
    }
  }

  /// Performs only a bounded server document refresh.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> refreshDocument(
    DocumentReference<Map<String, dynamic>> reference, {
    String operation = 'document_refresh',
    Duration serverTimeout = defaultServerTimeout,
  }) => _boundedServerRead(
    serverTimeout,
    operation,
    (remaining) => _serverDocument(reference, operation, remaining),
  );

  /// Performs only an immediate local Firestore query cache lookup.
  static Future<QuerySnapshot<Map<String, dynamic>>?> cachedQuery(
    Query<Map<String, dynamic>> reference, {
    String operation = 'query_cache_read',
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final value = await reference.get(const GetOptions(source: Source.cache));
      logDiagnostic(
        operation,
        value.docs.isEmpty ? 'cache_miss' : 'cache_hit',
        stopwatch.elapsed,
      );
      return value.docs.isEmpty ? null : value;
    } catch (error) {
      logDiagnostic(
        operation,
        'cache_miss',
        stopwatch.elapsed,
        error is FirebaseException ? error.code : null,
      );
      return null;
    }
  }

  /// Performs only a bounded server query refresh.
  static Future<QuerySnapshot<Map<String, dynamic>>?> refreshQuery(
    Query<Map<String, dynamic>> reference, {
    String operation = 'query_refresh',
    Duration serverTimeout = defaultServerTimeout,
  }) => _boundedServerRead(
    serverTimeout,
    operation,
    (remaining) => _serverQuery(reference, operation, remaining),
  );

  static Future<
    FirestoreCacheFirstResult<DocumentSnapshot<Map<String, dynamic>>>
  >
  document(
    DocumentReference<Map<String, dynamic>> reference, {
    String operation = 'document_read',
    String? requestKey,
    Duration serverTimeout = defaultServerTimeout,
    @visibleForTesting
    Future<DocumentSnapshot<Map<String, dynamic>>> Function()? serverLoader,
  }) async {
    DocumentSnapshot<Map<String, dynamic>>? cached;
    var cacheAvailable = false;
    final stopwatch = Stopwatch()..start();
    try {
      cached = await reference.get(const GetOptions(source: Source.cache));
      cacheAvailable = cached.exists;
      logDiagnostic(
        operation,
        cacheAvailable ? 'cache_hit' : 'cache_miss',
        stopwatch.elapsed,
      );
    } catch (error) {
      logDiagnostic(
        operation,
        'cache_miss',
        stopwatch.elapsed,
        error is FirebaseException ? error.code : null,
      );
    }

    final refresh = _coalesced<DocumentSnapshot<Map<String, dynamic>>>(
      'doc:${requestKey ?? reference.path}',
      operation,
      () => _boundedServerRead(
        serverTimeout,
        operation,
        (remaining) => _serverDocument(
          reference,
          operation,
          remaining,
          serverLoader: serverLoader,
        ),
      ),
    );
    if (cacheAvailable) unawaited(refresh.future);
    return FirestoreCacheFirstResult(
      cacheAvailable: cacheAvailable,
      cached: cached,
      refresh: refresh.future,
      metadata: FirestoreReadMetadata(
        operation: operation,
        cacheElapsed: stopwatch.elapsed,
        refreshShared: refresh.shared,
        refreshSuppressed: refresh.suppressed,
      ),
    );
  }

  static Future<FirestoreCacheFirstResult<QuerySnapshot<Map<String, dynamic>>>>
  query(
    Query<Map<String, dynamic>> reference, {
    String operation = 'query_read',
    String? requestKey,
    Duration serverTimeout = defaultServerTimeout,
    @visibleForTesting
    Future<QuerySnapshot<Map<String, dynamic>>> Function()? serverLoader,
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
    } catch (error) {
      logDiagnostic(
        operation,
        'cache_miss',
        stopwatch.elapsed,
        error is FirebaseException ? error.code : null,
      );
    }

    final refresh = _coalesced<QuerySnapshot<Map<String, dynamic>>>(
      'query:${requestKey ?? '$operation:${identityHashCode(reference)}'}',
      operation,
      () => _boundedServerRead(
        serverTimeout,
        operation,
        (remaining) => _serverQuery(
          reference,
          operation,
          remaining,
          serverLoader: serverLoader,
        ),
      ),
    );
    if (cacheAvailable) unawaited(refresh.future);
    return FirestoreCacheFirstResult(
      cacheAvailable: cacheAvailable,
      cached: cached,
      refresh: refresh.future,
      metadata: FirestoreReadMetadata(
        operation: operation,
        cacheElapsed: stopwatch.elapsed,
        refreshShared: refresh.shared,
        refreshSuppressed: refresh.suppressed,
      ),
    );
  }

  static _CoalescedRefresh<T> _coalesced<T>(
    String key,
    String operation,
    Future<T?> Function() action,
  ) {
    final now = DateTime.now();
    _recent.removeWhere(
      (_, entry) => now.difference(entry.at) >= _refreshCooldown,
    );
    final active = _inFlight[key];
    if (active != null) {
      logDiagnostic(operation, 'refresh_deduplicated', Duration.zero);
      return _CoalescedRefresh(
        active.then((value) => value as T?),
        shared: true,
      );
    }
    final recent = _recent[key];
    if (recent != null && now.difference(recent.at) < _refreshCooldown) {
      logDiagnostic(operation, 'refresh_cooled_down', Duration.zero);
      return _CoalescedRefresh(
        Future<T?>.value(recent.value as T?),
        suppressed: true,
      );
    }
    final future = Future<T?>.sync(action);
    _inFlight[key] = future;
    unawaited(
      future.then<void>(
        (value) {
          _recent[key] = (at: DateTime.now(), value: value);
          _inFlight.remove(key);
        },
        onError: (Object error, StackTrace stackTrace) {
          _inFlight.remove(key);
        },
      ),
    );
    return _CoalescedRefresh(future);
  }

  static Future<T?> _boundedServerRead<T>(
    Duration budget,
    String operation,
    Future<T?> Function(Duration remaining) action,
  ) async {
    final stopwatch = Stopwatch()..start();
    final acquired = await _acquireServerPermit(budget);
    if (!acquired) {
      logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
      return null;
    }
    var releaseImmediately = true;
    try {
      final remaining = budget - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
        return null;
      }
      return await action(remaining);
    } on _PendingServerTimeout catch (timeout) {
      releaseImmediately = false;
      unawaited(timeout.completion.then<void>((_) => _releaseServerPermit()));
      return null;
    } finally {
      if (releaseImmediately) _releaseServerPermit();
    }
  }

  static void _releaseServerPermit() {
    if (_serverWaiters.isNotEmpty) {
      _serverWaiters.removeAt(0).complete();
    } else if (_activeServerReads > 0) {
      _activeServerReads--;
    }
  }

  static Future<bool> _acquireServerPermit(Duration budget) async {
    if (_activeServerReads < _maxConcurrentServerReads) {
      _activeServerReads++;
      return true;
    }
    final waiter = Completer<void>();
    _serverWaiters.add(waiter);
    try {
      await waiter.future.timeout(budget);
      return true;
    } on TimeoutException {
      // If removal fails, the permit was transferred concurrently. Return it
      // through the normal release path instead of leaking capacity.
      if (!_serverWaiters.remove(waiter)) return true;
      return false;
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> _serverDocument(
    DocumentReference<Map<String, dynamic>> reference,
    String operation,
    Duration timeout, {
    Future<DocumentSnapshot<Map<String, dynamic>>> Function()? serverLoader,
  }) async {
    final stopwatch = Stopwatch()..start();
    late final Future<DocumentSnapshot<Map<String, dynamic>>> request;
    try {
      request =
          serverLoader?.call() ??
          reference.get(const GetOptions(source: Source.server));
      final value = await request.timeout(timeout);
      logDiagnostic(operation, 'server_success', stopwatch.elapsed);
      return value;
    } on TimeoutException {
      logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
      throw _PendingServerTimeout(
        request.then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {},
        ),
      );
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
    Duration timeout, {
    Future<QuerySnapshot<Map<String, dynamic>>> Function()? serverLoader,
  }) async {
    final stopwatch = Stopwatch()..start();
    late final Future<QuerySnapshot<Map<String, dynamic>>> request;
    try {
      request =
          serverLoader?.call() ??
          reference.get(const GetOptions(source: Source.server));
      final value = await request.timeout(timeout);
      logDiagnostic(operation, 'server_success', stopwatch.elapsed);
      return value;
    } on TimeoutException {
      logDiagnostic(operation, 'server_timeout', stopwatch.elapsed);
      throw _PendingServerTimeout(
        request.then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {},
        ),
      );
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
    final transport = await _currentTransport();
    final safeOperation = _safeDiagnosticLabel(operation);
    final safeOutcome = _safeDiagnosticLabel(outcome);
    final safeCode = firebaseCode == null
        ? null
        : _safeDiagnosticLabel(firebaseCode);
    debugPrint(
      '[firestore_read] platform=${kIsWeb ? 'web' : defaultTargetPlatform.name} '
      'transport=$transport correlation=${StartupPerformance.correlationId} '
      'operation=$safeOperation outcome=$safeOutcome '
      'elapsed_ms=${elapsed.inMilliseconds}'
      '${safeCode == null ? '' : ' firebase_code=$safeCode'}',
    );
  }

  static Future<String> _currentTransport() async {
    final checkedAt = _transportCheckedAt;
    if (checkedAt != null &&
        DateTime.now().difference(checkedAt) < const Duration(seconds: 2)) {
      return _cachedTransport;
    }
    final active = _transportLookup;
    if (active != null) return active;
    final lookup = () async {
      try {
        final types = await Connectivity().checkConnectivity();
        return types.map((type) => type.name).join(',');
      } catch (_) {
        return _cachedTransport;
      }
    }();
    _transportLookup = lookup;
    final value = await lookup;
    _cachedTransport = value.isEmpty ? 'unavailable' : value;
    _transportCheckedAt = DateTime.now();
    if (identical(_transportLookup, lookup)) _transportLookup = null;
    return _cachedTransport;
  }

  static String _safeDiagnosticLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (RegExp(r'^[a-z0-9_\-]{1,64}$').hasMatch(normalized)) {
      return normalized;
    }
    return 'redacted';
  }
}
