import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_writer_repository.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import 'auth_providers.dart';

final writerRepositoryProvider = Provider<WriterRepository>((ref) {
  return FirebaseWriterRepository();
});

final myBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(writerRepositoryProvider).getUserBooks(user.id);
});
