import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/book_card.dart';
import '../providers/homepage_providers.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class CategoryBooksArguments {
  const CategoryBooksArguments({required this.category, this.displayName});

  final String category;
  final String? displayName;
}

class CategoryBooksScreen extends ConsumerWidget {
  const CategoryBooksScreen({
    super.key,
    required this.category,
    this.displayName,
  });

  final String category;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final normalized = category.toLowerCase();
    Future<void> refresh() async {
      await refreshHomepage(ref);
      ref.invalidate(homepageGenreProvider(category));
    }

    final booksAsync = switch (normalized) {
      'wreadom originals' ||
      'originals' ||
      'wreadom-originals' => ref.watch(homepageOriginalsProvider),
      'trending works' ||
      'trending' ||
      'trending-works' => ref.watch(homepageTrendingWorksProvider),
      'popular now' ||
      'popular' ||
      'popular-now' => ref.watch(homepagePopularProvider),
      'recently added' ||
      'recent' ||
      'recently-added' => ref.watch(homepageRecentProvider),
      'community classics' ||
      'archive' ||
      'community-classics' => ref.watch(homepageIABooksProvider),
      _ => ref.watch(homepageGenreProvider(category)),
    };

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(displayName ?? category),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: refresh,
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.65,
                    child: _CategoryMessage(
                      icon: Icons.auto_stories_outlined,
                      message: l10n.noBooksFoundIn(displayName ?? category),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.56,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) => BookCard(book: books[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CategoryMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.errorWithDetails(error.toString()),
        ),
      ),
    );
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
