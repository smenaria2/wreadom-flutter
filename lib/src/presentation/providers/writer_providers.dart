import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/image_upload_service.dart';
import '../../data/services/writer_draft_service.dart';
import '../../data/repositories/firebase_writer_repository.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import 'auth_providers.dart';

final writerRepositoryProvider = Provider<WriterRepository>((ref) {
  return FirebaseWriterRepository();
});

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});

final writerDraftServiceProvider = Provider<WriterDraftStore>((ref) {
  return WriterDraftService();
});

/// The current selected tab in the Writer Dashboard
class WriterDashboardTab extends Notifier<String> {
  @override
  String build() => 'published';

  void setTab(String tab) => state = tab;
}

final writerDashboardTabProvider = NotifierProvider<WriterDashboardTab, String>(
  WriterDashboardTab.new,
);

bool writerBookMatchesTab(Book book, String activeTab) {
  final status = book.status?.trim().toLowerCase();
  if (activeTab == 'published') return status == 'published';
  if (activeTab == 'draft') {
    return status != 'published' && status != 'deleted';
  }
  return false;
}

/// Fetches books for the current user based on status
final filteredMyBooksProvider = FutureProvider<List<Book>>((ref) async {
  final activeTab = ref.watch(writerDashboardTabProvider);
  if (activeTab == 'social') return const [];

  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final books = await ref.watch(writerRepositoryProvider).getUserBooks(user.id);
  return books.where((book) => writerBookMatchesTab(book, activeTab)).toList();
});

/// Keep myBooksProvider for backwards compatibility if needed, but pointing to 'all'
final myBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(writerRepositoryProvider).getUserBooks(user.id);
});
