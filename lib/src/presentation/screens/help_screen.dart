import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_HelpCategory> _categories = [
    _HelpCategory(
      title: 'Reading',
      icon: Icons.menu_book_rounded,
      color: Colors.blue,
      faqs: [
        _FAQ(
          question: 'How do I customize the reader?',
          answer:
              'Open any book and tap the "Aa" icon in the top toolbar. You can change the font size, switch between Serif and Sans fonts, and choose a theme (Light, Sepia, or Dark).',
        ),
        _FAQ(
          question: 'Can I read books offline?',
          answer:
              'Yes! Tap the download icon on the book details page. Once downloaded, you can access the book from your "Saved" tab even without an internet connection.',
        ),
        _FAQ(
          question: 'How do bookmarks work?',
          answer:
              'Wreadom automatically saves your progress as you read. To manually mark a specific spot, tap the bookmark icon in the reader\'s top toolbar.',
        ),
        _FAQ(
          question: 'What is "Quote & Comment"?',
          answer:
              'Highlight any text in a book to see the selection menu. You can "Quote & Comment" to share your thoughts on a specific passage with the community.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Writing',
      icon: Icons.edit_note_rounded,
      color: Colors.orange,
      faqs: [
        _FAQ(
          question: 'How do I start a new story?',
          answer:
              'Go to the "Writer Dashboard" from your profile menu and tap the "Add" icon. This will open the Writer Pad where you can start drafting your first chapter.',
        ),
        _FAQ(
          question: 'Is there an auto-save feature?',
          answer:
              'Yes, the Writer Pad automatically saves your drafts every 10 seconds. You can see the "Last Saved" status at the top of the editor.',
        ),
        _FAQ(
          question: 'How do I publish my work?',
          answer:
              'Once your story is ready, tap "Publish" in the Writer Pad. You\'ll be asked to provide a title, synopsis, and relevant topics before it goes live for the community.',
        ),
        _FAQ(
          question: 'Can I organize chapters?',
          answer:
              'Absolutely! Use the chapter menu (list icon) in the editor to add new chapters, switch between them, or reorder your story structure.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Discovery',
      icon: Icons.explore_rounded,
      color: Colors.green,
      faqs: [
        _FAQ(
          question: 'How do I find new books?',
          answer:
              'Use the "Discover" tab to browse by trending genres like Fantasy, Romance, and Sci-Fi. You can also search specifically for titles or authors.',
        ),
        _FAQ(
          question: 'What are "Originals"?',
          answer:
              'Originals are stories written and published directly by authors within the Wreadom community.',
        ),
        _FAQ(
          question: 'What is the Internet Archive integration?',
          answer:
              'Wreadom connects to the Internet Archive to give you access to millions of classic books and public domain works alongside community originals.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Community',
      icon: Icons.people_alt_rounded,
      color: Colors.purple,
      faqs: [
        _FAQ(
          question: 'What is the Daily Topic?',
          answer:
              'Every day, Wreadom features a new writing or discussion prompt. Tap the banner on the Home feed to participate and see what others are sharing.',
        ),
        _FAQ(
          question: 'How do I follow an author?',
          answer:
              'Tap on an author\'s name or avatar to visit their public profile, then tap "Follow" to see their latest posts and story updates in your feed.',
        ),
        _FAQ(
          question: 'Can I message other users?',
          answer:
              'Yes, you can start direct conversations with other users. Visit their profile or use the "Messages" icon on your navigation bar to manage your chats.',
        ),
      ],
    ),
    _HelpCategory(
      title: 'Account',
      icon: Icons.account_circle_rounded,
      color: Colors.red,
      faqs: [
        _FAQ(
          question: 'How do I change the app theme?',
          answer:
              'Go to Profile -> Menu (top-right) -> Theme. You can choose between Light, Dark, or System default modes.',
        ),
        _FAQ(
          question: 'How do I update my profile?',
          answer:
              'In the "Edit Profile" section of your settings, you can update your display name, pen name, and bio.',
        ),
        _FAQ(
          question: 'Where are my notifications?',
          answer:
              'Tap the bell icon on the home screen or profile to see updates about likes, comments, and new followers.',
        ),
      ],
    ),
  ];

  List<_HelpCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    
    return _categories.map((category) {
      final matchesFaqs = category.faqs.where((faq) =>
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      
      if (category.title.toLowerCase().contains(_searchQuery.toLowerCase()) || matchesFaqs.isNotEmpty) {
        return _HelpCategory(
          title: category.title,
          icon: category.icon,
          color: category.color,
          faqs: matchesFaqs.isNotEmpty ? matchesFaqs : category.faqs,
        );
      }
      return null;
    }).whereType<_HelpCategory>().toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchHeader(theme),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return _buildCategorySection(context, category, theme);
                    },
                  ),
          ),
          _buildSupportFooter(theme),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search for help topics...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, _HelpCategory category, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 24),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...category.faqs.map((faq) => _buildFAQTile(faq, theme)),
      ],
    );
  }

  Widget _buildFAQTile(_FAQ faq, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            faq.answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Our community team is here to assist.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support contact feature coming soon!')),
              );
            },
            icon: const Icon(Icons.mail_outline_rounded, size: 18),
            label: const Text('Contact Us'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No help topics found for "$_searchQuery"',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _HelpCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_FAQ> faqs;

  _HelpCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.faqs,
  });
}

class _FAQ {
  final String question;
  final String answer;

  _FAQ({required this.question, required this.answer});
}
