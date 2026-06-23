import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/book.dart';
import 'homepage_providers.dart';

final homepageSeriesBooksProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  final series = books.where((book) {
    final count = book.chapterCount ?? book.chapters?.length ?? 0;
    return count > 1;
  }).toList()
    ..sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt ?? 0;
      final bTime = b.updatedAt ?? b.createdAt ?? 0;
      return bTime.compareTo(aTime);
    });
  return series.take(24).toList();
});
