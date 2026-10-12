import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../components/book_card.dart';
import '../providers/book_providers.dart';
import '../routing/app_routes.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  childAspectRatio: 0.44,
  crossAxisSpacing: 12,
  mainAxisSpacing: 28,
);

class SavedBooksScreen extends ConsumerWidget {
  const SavedBooksScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(savedBooksProvider);
    try {
      await ref.read(savedBooksProvider.future);
    } catch (_) {
      // The error state below offers a retry.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(savedBooksProvider);
    final l10n = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(l10n.savedBooksTitle),
        actions: [
          IconButton(
            tooltip: l10n.tryAgain,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(savedBooksProvider),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: _SavedBooksMessage(
                      icon: Icons.bookmark_border_rounded,
                      message: l10n.noSavedOrDownloadedBooksYet,
                      actionLabel: l10n.discover,
                      onAction: () =>
                          Navigator.of(context).pushNamed(AppRoutes.discovery),
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: _gridDelegate,
              itemCount: books.length,
              itemBuilder: (context, index) => BookCard(book: books[index]),
            ),
          );
        },
        loading: () => const _SavedBooksSkeleton(),
        error: (error, _) => _SavedBooksMessage(
          icon: Icons.error_outline_rounded,
          message: l10n.somethingWentWrong,
          actionLabel: l10n.tryAgain,
          onAction: () => ref.invalidate(savedBooksProvider),
        ),
      ),
    );
  }
}

class _SavedBooksSkeleton extends StatelessWidget {
  const _SavedBooksSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7);
    return ExcludeSemantics(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: _gridDelegate,
        itemCount: 9,
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(width: 70, height: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBooksMessage extends StatelessWidget {
  const _SavedBooksMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          strong: true,
          padding: const EdgeInsets.all(22),
          borderRadius: BorderRadius.circular(22),
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
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
