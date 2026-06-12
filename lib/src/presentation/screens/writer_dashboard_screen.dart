import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../../utils/book_collaboration_utils.dart';
import '../components/writer/writer_book_card.dart';
import '../components/writer/writer_dashboard_header.dart';
import '../providers/auth_providers.dart';
import '../providers/writer_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';

class WriterDashboardScreen extends ConsumerWidget {
  const WriterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final activeTab = ref.watch(writerDashboardTabProvider);
    final booksAsync = ref.watch(filteredMyBooksProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;

    if (currentUserAsync.isLoading) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerDashboard)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return GlassScaffold(
        appBar: glassAppBar(title: Text(l10n.writerDashboard)),
        body: const AuthRequiredView(icon: Icons.edit_note_outlined),
      );
    }

    return GlassScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(filteredMyBooksProvider.future),
        child: CustomScrollView(
          slivers: [
            glassSliverAppBar(
              title: Text(
                l10n.writerDashboard,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              floating: true,
              pinned: true,
            ),
            const SliverToBoxAdapter(child: WriterDashboardHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Column(
                  children: [
                    GlassControlSurface(
                      borderRadius: BorderRadius.circular(26),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'published',
                            label: Text(l10n.published),
                            icon: const Icon(Icons.public_rounded),
                          ),
                          ButtonSegment(
                            value: 'draft',
                            label: Text(l10n.drafts),
                            icon: const Icon(Icons.edit_note_rounded),
                          ),
                        ],
                        selected: {activeTab},
                        onSelectionChanged: (selection) {
                          ref
                              .read(writerDashboardTabProvider.notifier)
                              .setTab(selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassSurface(
                      strong: true,
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.writerPad,
                          arguments: const WriterPadArguments(),
                        );
                      },
                      semanticButton: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l10n.createContent,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            activeTab == 'published'
                                ? l10n.noPublishedStoriesYet
                                : l10n.noDraftsYet,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 132),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final book = books[index];
                      final isPublished = book.status == 'published';
                      void openEditor() {
                        Navigator.of(context).pushNamed(
                          AppRoutes.writerPad,
                          arguments: WriterPadArguments(book: book),
                        );
                      }

                      void openStoryPage() {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: BookDetailArguments(
                            bookId: book.id,
                            book: book,
                          ),
                        );
                      }

                      return WriterBookCard(
                        book: book,
                        onTap: isPublished ? openStoryPage : openEditor,
                        onEditStory: isPublished ? openEditor : null,
                        onDeleteDraft:
                            isPublished ||
                                !canDeleteCollaborativeBook(
                                  book,
                                  currentUser.id,
                                )
                            ? null
                            : () => _confirmDeleteDraft(context, ref, book.id),
                        onDeleteBlocked:
                            !isPublished &&
                                isAcceptedCollaboration(book) &&
                                book.authorId?.trim() == currentUser.id
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.removeCollabBeforeDelete),
                                ),
                              )
                            : null,
                      );
                    }, childCount: books.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Text(l10n.failedToLoadWithError(error.toString())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDraft(
    BuildContext context,
    WidgetRef ref,
    String bookId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDraftTitle),
        content: Text(l10n.deleteDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(writerRepositoryProvider).deleteBook(bookId);
      ref.invalidate(myBooksProvider);
      ref.invalidate(filteredMyBooksProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.draftDeleted)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotDeleteDraft(error.toString()))),
      );
    }
  }
}
