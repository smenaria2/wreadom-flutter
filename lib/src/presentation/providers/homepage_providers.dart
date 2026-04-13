import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/book.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import 'book_providers.dart';

import 'dart:math' as math;

final homepageMetadataProvider = FutureProvider<HomepageMetadata>((ref) async {
  final doc = await FirebaseFirestore.instance
      .collection('settings')
      .doc('homepage_metadata')
      .get();
      
  return HomepageMetadata.fromJson(doc.data() ?? {});
});

final homepageBooksProvider = FutureProvider<List<Book>>((ref) async {
  // First, fetch the metadata to get the recommendation stats
  final metadata = await ref.watch(homepageMetadataProvider.future);
  final statsData = metadata.recommendationStats;
  
  // Also fetch all available internet archive books logic and originals
  // To reach parity with Web we should fetch what we need
  final popularAsync = await ref.watch(popularBooksProvider.future);
  final recentAsync = await ref.watch(recentBooksProvider.future);
  final originalAsync = await ref.watch(originalBooksProvider.future);
  
  // Combine all books and sort by recommendation stats
  final Map<String, Book> uniqueBooks = {};
  
  void addBooks(List<Book> books) {
    for (final book in books) {
      uniqueBooks[book.id] = book;
    }
  }
  
  addBooks(popularAsync);
  addBooks(recentAsync);
  addBooks(originalAsync);
  
  final combinedBooks = uniqueBooks.values.toList();
  
  // Apply the weighted score similar to web app
  combinedBooks.sort((a, b) {
    double getScore(Book book) {
      final avgRating = book.averageRating ?? 0.0;
      final ratingsCount = book.ratingsCount ?? 0;
      final stats = statsData[book.id];
      
      final popularityScore = avgRating * math.log(ratingsCount + 1) / math.ln10 + 
          (stats?.recommendationCount ?? 0) * 0.1;
          
      final weekInMs = 7 * 24 * 60 * 60 * 1000;
      final ageInWeeks = book.createdAt != null 
          ? (DateTime.now().millisecondsSinceEpoch - book.createdAt!) / weekInMs 
          : 0;
      
      final recencyScore = math.exp(-math.max(0, ageInWeeks) * 0.1);
      return popularityScore * (1 + recencyScore);
    }
    
    final scoreA = getScore(a);
    final scoreB = getScore(b);
    return scoreB.compareTo(scoreA); // Descending
  });
  
  return combinedBooks;
});

// Category Providers powered by the Homepage combined list
final homepageOriginalsProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.where((b) => b.isOriginal ?? false).toList();
});

final homepagePopularProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.take(20).toList();
});

final homepageRecentProvider = FutureProvider<List<Book>>((ref) async {
  final books = await ref.watch(homepageBooksProvider.future);
  final sorted = List<Book>.from(books)
    ..sort((a, b) {
      final tA = a.createdAt ?? 0;
      final tB = b.createdAt ?? 0;
      return tB.compareTo(tA);
    });
  return sorted.take(20).toList();
});

final homepageGenreProvider = FutureProvider.family<List<Book>, String>((ref, genre) async {
  final books = await ref.watch(homepageBooksProvider.future);
  return books.where((book) {
    final categories = book.topics ?? book.subjects;
    if (categories.isEmpty) return false;
    return categories.any((c) => c.toLowerCase() == genre.toLowerCase());
  }).toList();
});
