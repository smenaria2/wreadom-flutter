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
              title: const Text('Writer Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print_outlined, color: Colors.white),
                  onPressed: () {
                    // Placeholder for Print Book action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Print service coming soon to mobile!')),
                    );
                  },
                  tooltip: 'Print Book',
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: WriterDashboardHeader(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Published',
                      isActive: activeTab == 'published',
                      onTap: () => ref.read(writerDashboardTabProvider.notifier).setTab('published'),
                    ),
                    const SizedBox(width: 12),
                    _TabButton(
                      label: 'Drafts',
                      isActive: activeTab == 'draft',
                      onTap: () => ref.read(writerDashboardTabProvider.notifier).setTab('draft'),
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
                          Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No status ${activeTab}s',
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
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        return WriterBookCard(
                          book: book,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.writerPad,
                              arguments: WriterPadArguments(book: book),
                            );
                          },
                        );
                      },
                      childCount: books.length,
                    ),
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
        label: const Text('Create Story', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: theme.primaryColor,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
