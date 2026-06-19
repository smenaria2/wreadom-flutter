import '../../domain/models/chapter.dart';

class ChapterReviewPromptPolicy {
  const ChapterReviewPromptPolicy._();

  static String localDay(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static String lastPromptDayKey(String userId) {
    return 'chapter_review_prompt_last_day:${Uri.encodeComponent(userId)}';
  }

  static String promptCountKey(String userId) {
    return 'chapter_review_prompt_count:${Uri.encodeComponent(userId)}';
  }

  static String promptedChapterKey({
    required String userId,
    required String bookId,
    required Chapter chapter,
    required int chapterIndex,
  }) {
    final chapterKey = chapter.id.trim().isNotEmpty
        ? chapter.id.trim()
        : 'index:$chapterIndex';
    return 'chapter_review_prompted:${Uri.encodeComponent(userId)}:'
        '${Uri.encodeComponent(bookId)}:${Uri.encodeComponent(chapterKey)}';
  }

  static bool emphasizeVoice(int previousPromptCount) {
    return (previousPromptCount + 1) % 3 == 0;
  }
}
