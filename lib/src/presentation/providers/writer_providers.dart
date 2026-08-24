import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/image_upload_service.dart';
import '../../data/services/writer_draft_service.dart';
import '../../data/repositories/firebase_writer_repository.dart';
import '../../domain/models/book.dart';
import '../../domain/repositories/writer_repository.dart';
import '../../data/services/startup_data_cache.dart';
import 'auth_providers.dart';
import 'startup_cache_provider.dart';

const _writerOverviewScope = 'writer_overview';
const _writerRefreshCooldown = Duration(seconds: 2);
final Map<String, Future<List<Book>>> _writerRefreshes = {};
final Map<String, DateTime> _writerLastRefresh = {};

void clearWriterOverviewMemory(String userId) {
  _writerRefreshes.remove(userId);
  _writerLastRefresh.remove(userId);
}

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

  final books = await _loadWriterOverview(ref, user.id);
  return books.where((book) => writerBookMatchesTab(book, activeTab)).toList();
});

/// Keep myBooksProvider for backwards compatibility if needed, but pointing to 'all'
final myBooksProvider = FutureProvider<List<Book>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return _loadWriterOverview(ref, user.id);
});

Future<List<Book>> _loadWriterOverview(Ref ref, String userId) async {
  final cache = ref.read(startupDataCacheProvider);
  if (cache == null) {
    return ref
        .read(writerRepositoryProvider)
        .getUserBooks(userId)
        .timeout(const Duration(seconds: 4));
  }
  final cached = cache.read<List<Book>>(
    scope: _writerOverviewScope,
    userId: userId,
    decode: (json) => (json! as List)
        .map((item) => Book.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false),
  );
  if (cached != null) {
    unawaited(
      _refreshWriterOverview(ref, cache, userId).catchError((_) => cached),
    );
    return cached;
  }
  return _refreshWriterOverview(ref, cache, userId);
}

Future<List<Book>> _refreshWriterOverview(
  Ref ref,
  StartupDataCache cache,
  String userId,
) {
  final active = _writerRefreshes[userId];
  if (active != null) return active;
  final lastRefresh = _writerLastRefresh[userId];
  if (lastRefresh != null &&
      DateTime.now().difference(lastRefresh) < _writerRefreshCooldown) {
    return Future.value(
      cache.read<List<Book>>(
            scope: _writerOverviewScope,
            userId: userId,
            decode: (json) => (json! as List)
                .map(
                  (item) =>
                      Book.fromJson(Map<String, dynamic>.from(item as Map)),
                )
                .toList(growable: false),
          ) ??
          const [],
    );
  }
  final refresh = ref
      .read(writerRepositoryProvider)
      .getUserBooks(userId)
      .timeout(const Duration(seconds: 4))
      .then((books) async {
        // The startup overview intentionally excludes manuscript bodies.
        final overview = books
            .map((book) => book.copyWith(chapters: null))
            .toList(growable: false);
        final persisted = await cache.write(
          scope: _writerOverviewScope,
          userId: userId,
          value: overview.map((book) => book.toJson()).toList(),
        );
        if (!persisted) return overview;
        _writerLastRefresh[userId] = DateTime.now();
        scheduleMicrotask(() {
          if (ref.mounted) ref.invalidateSelf();
        });
        return overview;
      });
  _writerRefreshes[userId] = refresh;
  unawaited(
    refresh.then<void>(
      (_) => _writerRefreshes.remove(userId),
      onError: (Object error, StackTrace stackTrace) =>
          _writerRefreshes.remove(userId),
    ),
  );
  return refresh;
}
