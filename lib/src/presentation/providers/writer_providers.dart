import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_writer_repository.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import 'auth_providers.dart';

final writerRepositoryProvider = Provider<WriterRepository>((ref) {
  return FirebaseWriterRepository();
});

/// The current selected tab in the Writer Dashboard
class WriterDashboardTab extends Notifier<String> {
  @override
  String build() => 'published';
  
  void setTab(String tab) => state = tab;
}

final writerDashboardTabProvider = NotifierProvider<WriterDashboardTab, String>(WriterDashboardTab.new);

/// Fetches books for the current user based on status
final filteredMyBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  
  final activeTab = ref.watch(writerDashboardTabProvider);
  // 'published' tab shows 'published' status
  // 'draft' tab shows everything else (drafts, pending, etc.)
  final status = activeTab == 'published' ? 'published' : 'draft';
  
  // Note: FirebaseWriterRepository.getUserBooks handles filtering
  return ref.watch(writerRepositoryProvider).getUserBooks(user.id, status: status);
});

/// Keep myBooksProvider for backwards compatibility if needed, but pointing to 'all'
final myBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(writerRepositoryProvider).getUserBooks(user.id);
});
