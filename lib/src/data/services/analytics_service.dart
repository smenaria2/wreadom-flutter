import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/book.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  static Future<void> setUserDisplayName(String? displayName) async {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) {
      await Future.wait([
        analytics.setUserId(id: null),
        analytics.setUserProperty(name: 'display_name', value: null),
      ]);
      return;
    }

    await Future.wait([
      analytics.setUserId(id: name),
      analytics.setUserProperty(name: 'display_name', value: name),
    ]);
  }

  static void identifyUser(String? displayName) {
    unawaited(_safe(() => setUserDisplayName(displayName)));
  }

  static void logSignUp({required String method}) {
    logEvent('sign_up', parameters: {'method': method});
  }

  static void logLogin({required String method}) {
    logEvent('login', parameters: {'method': method});
  }

  static void logBookView(Book book) {
    logEvent(
      'book_view',
      parameters: {'book_id': book.id, 'source': book.source ?? 'unknown'},
    );
  }

  static void logReaderOpen(Book book) {
    logEvent(
      'reader_open',
      parameters: {'book_id': book.id, 'source': book.source ?? 'unknown'},
    );
  }

  static void logChapterComplete({
    required String bookId,
    required int chapterIndex,
  }) {
    logEvent(
      'chapter_complete',
      parameters: {'book_id': bookId, 'chapter_index': chapterIndex},
    );
  }

  static void logSearch(String searchTerm) {
    final term = searchTerm.trim();
    if (term.isEmpty) return;
    logEvent('search', parameters: {'search_term': term});
  }

  static void logGenreSelect(String genre) {
    final value = genre.trim();
    if (value.isEmpty) return;
    logEvent('genre_select', parameters: {'genre': value});
  }

  static void logBookmark({required bool added, required String bookId}) {
    logEvent(
      added ? 'bookmark_add' : 'bookmark_remove',
      parameters: {'book_id': bookId},
    );
  }

  static void logFollow({
    required bool followed,
    required String targetUserId,
  }) {
    logEvent(
      followed ? 'follow_user' : 'unfollow_user',
      parameters: {'target_user_id': targetUserId},
    );
  }

  static void logCommentCreate({required String targetType}) {
    logEvent('comment_create', parameters: {'target_type': targetType});
  }

  static void logPostCreate() {
    logEvent('post_create');
  }

  static void logBookPublish({required String bookId}) {
    logEvent('book_publish', parameters: {'book_id': bookId});
  }

  static void logEvent(String name, {Map<String, Object>? parameters}) {
    unawaited(
      _safe(() => analytics.logEvent(name: name, parameters: parameters)),
    );
  }

  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Analytics event failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
