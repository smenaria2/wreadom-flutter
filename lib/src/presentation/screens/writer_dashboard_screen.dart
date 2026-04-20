import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/writer/writer_book_card.dart';
import '../components/writer/writer_dashboard_header.dart';
import '../providers/writer_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class WriterDashboardScreen extends ConsumerWidget {
  const WriterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTab = ref.watch(writerDashboardTabProvider);
    final booksAsync = ref.watch(filteredMyBooksProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(filteredMyBooksProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.primaryColor,
              title: const Text(
                'Writer Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: WriterDashboardHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'published',
                      label: Text('Published'),
                      icon: Icon(Icons.public_rounded),
                    ),
                    ButtonSegment(
                      value: 'draft',
                      label: Text('Drafts'),
                      icon: Icon(Icons.edit_note_rounded),
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
                                ? 'No published stories yet'
                                : 'No drafts yet',
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
                        onDeleteDraft: isPublished
                            ? null
                            : () => _confirmDeleteDraft(context, ref, book.id),
                      );
                    }, childCount: books.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('Failed to load: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(
            AppRoutes.writerPad,
            arguments: const WriterPadArguments(),
          );
        },
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text(
          'Create Content',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Future<void> _confirmDeleteDraft(
    BuildContext context,
    WidgetRef ref,
    String bookId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete draft?'),
        content: const Text('This draft will be removed from your dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
      ).showSnackBar(const SnackBar(content: Text('Draft deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete draft: $error')));
    }
  }
}
