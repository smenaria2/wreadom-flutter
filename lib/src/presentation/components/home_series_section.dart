import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/series_books_provider.dart';
import '../screens/home_books_screen.dart';
import '../routing/app_routes.dart';
import '../screens/category_books_screen.dart';

class HomeSeriesSection extends ConsumerWidget {
  const HomeSeriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(homepageSeriesBooksProvider);
    final l10n = AppLocalizations.of(context)!;

    return BookshelfSection(
      title: l10n.shelfSeries,
      booksAsync: seriesAsync,
      sectionId: 'series',
      onRetry: () => ref.invalidate(homepageSeriesBooksProvider),
      onSeeAll: () => Navigator.of(context).pushNamed(
        AppRoutes.category,
        arguments: CategoryBooksArguments(
          category: 'series',
          displayName: l10n.shelfSeries,
        ),
      ),
    );
  }
}
