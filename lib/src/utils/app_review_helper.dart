import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReviewHelper {
  const AppReviewHelper._();

  static const String _keyActionCount = 'app_review_action_count';
  static const String _keyLastPromptTime = 'app_review_last_prompt_time';
  
  /// Threshold of significant actions before requesting a review.
  static const int _actionThreshold = 3;
  
  /// Minimum days between review requests.
  static const int _daysBetweenPrompts = 7;

  /// Increments the significant action counter and checks if a review should be requested.
  static Future<void> incrementActionAndCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Increment action count
      final currentCount = prefs.getInt(_keyActionCount) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(_keyActionCount, newCount);
      
      debugPrint('[AppReviewHelper] Incrementing action count: $newCount');

      if (newCount >= _actionThreshold) {
        await requestReviewIfNeeded(prefs: prefs);
      }
    } catch (e, stack) {
      debugPrint('[AppReviewHelper] Error incrementing action count: $e\n$stack');
    }
  }

  /// Explicitly triggers the check and requests review if conditions are met.
  static Future<void> requestReviewIfNeeded({SharedPreferences? prefs}) async {
    try {
      if (kIsWeb) {
        debugPrint('[AppReviewHelper] In-app review not supported on Web');
        return;
      }

      final p = prefs ?? await SharedPreferences.getInstance();
      
      // Check last prompt time
      final lastPromptMillis = p.getInt(_keyLastPromptTime) ?? 0;
      final lastPromptTime = DateTime.fromMillisecondsSinceEpoch(lastPromptMillis);
      final daysSinceLastPrompt = DateTime.now().difference(lastPromptTime).inDays;

      debugPrint('[AppReviewHelper] Days since last prompt: $daysSinceLastPrompt');

      if (daysSinceLastPrompt >= _daysBetweenPrompts) {
        final InAppReview inAppReview = InAppReview.instance;
        
        if (await inAppReview.isAvailable()) {
          debugPrint('[AppReviewHelper] Requesting in-app review...');
          await inAppReview.requestReview();
          
          // Reset action counter and update last prompt time on successful request
          await p.setInt(_keyActionCount, 0);
          await p.setInt(_keyLastPromptTime, DateTime.now().millisecondsSinceEpoch);
        } else {
          debugPrint('[AppReviewHelper] In-app review is not available');
        }
      } else {
        debugPrint('[AppReviewHelper] Review request skipped: within $_daysBetweenPrompts days interval');
      }
    } catch (e, stack) {
      debugPrint('[AppReviewHelper] Error requesting in-app review: $e\n$stack');
    }
  }
}
