import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper utility providing cache-first reading and network resilience for Firestore.
///
/// Implements a 0ms Stale-While-Revalidate pattern:
/// 1. Reads local cache first (`Source.cache`) and returns immediately if available (<10ms).
/// 2. Spawns an unawaited background fetch (`Source.server`) to update the disk cache.
/// 3. Falls back to a short-timeout server request if cache is unavailable.
class FirestoreResilienceHelper {
  const FirestoreResilienceHelper._();

  static const Duration defaultServerTimeout = Duration(seconds: 4);

  /// Retrieves a document snapshot with fast cache-first fallback.
  static Future<DocumentSnapshot<T>> getDocWithFastCacheFallback<T extends Object?>(
    DocumentReference<T> docRef, {
    Duration serverTimeout = defaultServerTimeout,
  }) async {
    // 1. Try fast local cache read (<10ms)
    try {
      final cached = await docRef.get(const GetOptions(source: Source.cache));
      if (cached.exists && cached.data() != null) {
        // Refresh local cache in the background silently
        unawaited(
          docRef
              .get(const GetOptions(source: Source.server))
              .then<Object?>((fresh) => fresh)
              .catchError((e) {
                debugPrint('[FirestoreResilience] Background doc refresh error: $e');
                return cached;
              }),
        );
        return cached;
      }
    } catch (_) {
      // Cache miss or unavailable, proceed to server fetch
    }

    // 2. Fetch from server with short timeout
    try {
      return await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(serverTimeout);
    } catch (e) {
      debugPrint('[FirestoreResilience] Server doc fetch timeout or error: $e. Falling back to default get.');
    }

    // 3. Fallback to default get (serverAndCache)
    try {
      return await docRef.get();
    } catch (e, stack) {
      debugPrint('[FirestoreResilience] Default doc get failed: $e\n$stack');
      rethrow;
    }
  }

  /// Retrieves query snapshot with fast cache-first fallback.
  static Future<QuerySnapshot<T>> getQueryWithFastCacheFallback<T extends Object?>(
    Query<T> query, {
    Duration serverTimeout = defaultServerTimeout,
  }) async {
    // 1. Try fast local cache read (<10ms)
    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        // Refresh local cache in the background silently
        unawaited(
          query
              .get(const GetOptions(source: Source.server))
              .then<Object?>((fresh) => fresh)
              .catchError((e) {
                debugPrint('[FirestoreResilience] Background query refresh error: $e');
                return cached;
              }),
        );
        return cached;
      }
    } catch (_) {
      // Cache miss or unavailable, proceed to server fetch
    }

    // 2. Fetch from server with short timeout
    try {
      return await query
          .get(const GetOptions(source: Source.server))
          .timeout(serverTimeout);
    } catch (e) {
      debugPrint('[FirestoreResilience] Server query fetch timeout or error: $e. Falling back to default get.');
    }

    // 3. Fallback to default get (serverAndCache)
    try {
      return await query.get();
    } catch (e, stack) {
      debugPrint('[FirestoreResilience] Default query get failed: $e\n$stack');
      rethrow;
    }
  }
}
