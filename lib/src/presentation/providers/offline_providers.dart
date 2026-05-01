import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/offline_service.dart';

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

final downloadedBooksProvider = FutureProvider<List>((ref) async {
  final service = ref.watch(offlineServiceProvider);
  await service.init();
  return service.getDownloadedBooks();
});

final downloadedBookEntriesProvider = FutureProvider<List<OfflineBookEntry>>((
  ref,
) async {
  final service = ref.watch(offlineServiceProvider);
  await service.init();
  return service.getDownloadedBookEntries();
});
