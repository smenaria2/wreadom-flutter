// tool/backfill_book_reading_times.dart
//
// Utility script to backfill `wordCount` and `readingTimeMinutes` on existing `books`
// documents in Cloud Firestore that were created before automatic projection.
//
// Usage:
//   dart run tool/backfill_book_reading_times.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:librebook_flutter/src/utils/reading_time_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final booksQuery = await firestore
      .collection('books')
      .where('status', isEqualTo: 'published')
      .get();

  debugPrint('Found ${booksQuery.docs.length} published books to inspect.');

  int updatedCount = 0;
  for (final doc in booksQuery.docs) {
    final data = doc.data();
    final existingMinutes = data['readingTimeMinutes'];
    final existingWords = data['wordCount'];

    if (existingMinutes is int && existingMinutes > 0 && existingWords is int) {
      continue; // Already backfilled
    }

    // Fetch chapters for this book
    final chaptersQuery = await firestore
        .collection('books')
        .doc(doc.id)
        .collection('chapters')
        .get();

    int totalWords = 0;
    if (chaptersQuery.docs.isNotEmpty) {
      for (final chapterDoc in chaptersQuery.docs) {
        final content = chapterDoc.data()['content']?.toString() ?? '';
        totalWords += countWords(content);
      }
    } else {
      final chaptersRaw = data['chapters'];
      if (chaptersRaw is List) {
        for (final item in chaptersRaw) {
          if (item is Map) {
            final content = item['content']?.toString() ?? '';
            totalWords += countWords(content);
          }
        }
      }
    }

    final int calculatedMinutes;
    if (totalWords > 0) {
      final m = (totalWords / 200).ceil();
      calculatedMinutes = m < 1 ? 1 : m;
    } else {
      final count = data['chapterCount'] is int ? data['chapterCount'] as int : 1;
      calculatedMinutes = (count * 3).clamp(1, 99999);
    }

    await doc.reference.update({
      'wordCount': totalWords,
      'readingTimeMinutes': calculatedMinutes,
    });

    updatedCount++;
    debugPrint('Updated book "${data['title'] ?? doc.id}": $totalWords words, $calculatedMinutes min read.');
  }

  debugPrint('Backfill complete! Updated $updatedCount books.');
}
