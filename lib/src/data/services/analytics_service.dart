import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../../domain/models/book.dart';

class _DummyObserver extends NavigatorObserver {}

class AnalyticsService {
  AnalyticsService._();

  static bool _initialized = false;
  static bool get _hasFirebase {
    if (_initialized) return true;
    try {
      Firebase.app();
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  static NavigatorObserver get observer {
    if (!_hasFirebase) return _DummyObserver();
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  static Future<void> setUserDisplayName(String? displayName) async {
    if (!_hasFirebase) return;
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

  static void logChapterReviewPromptShown({
    required String bookId,
    required int chapterIndex,
  }) {
    logEvent(
      'chapter_review_prompt_shown',
      parameters: {'book_id': bookId, 'chapter_index': chapterIndex},
    );
  }

  static void logChapterReviewPromptDismissed({
    required String bookId,
    required int chapterIndex,
  }) {
    logEvent(
      'chapter_review_prompt_dismissed',
      parameters: {'book_id': bookId, 'chapter_index': chapterIndex},
    );
  }

  static void logChapterReviewPromptSubmitted({
    required String bookId,
    required int chapterIndex,
    required bool usedVoice,
  }) {
    logEvent(
      usedVoice
          ? 'chapter_review_prompt_voice_submitted'
          : 'chapter_review_prompt_text_submitted',
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
    if (!_hasFirebase) return;
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
