import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/widgets/submit_error_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<_HelpCategory> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _HelpCategory(
        title: l10n.helpCategoryReading,
        icon: Icons.menu_book_rounded,
        color: Colors.blue,
        faqs: [
          _FAQ(
            question: l10n.faqCustomizeReaderQ,
            answer: l10n.faqCustomizeReaderA,
          ),
          _FAQ(
            question: l10n.faqOfflineReadingQ,
            answer: l10n.faqOfflineReadingA,
          ),
          _FAQ(question: l10n.faqBookmarksQ, answer: l10n.faqBookmarksA),
          _FAQ(question: l10n.faqQuoteCommentQ, answer: l10n.faqQuoteCommentA),
          _FAQ(question: l10n.faqWhatAreReadsQ, answer: l10n.faqWhatAreReadsA),
          _FAQ(question: l10n.faqTapToSeekQ, answer: l10n.faqTapToSeekA),
          _FAQ(
            question: l10n.faqShareQuoteImageQ,
            answer: l10n.faqShareQuoteImageA,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryWriting,
        icon: Icons.edit_note_rounded,
        color: Colors.orange,
        faqs: [
          _FAQ(question: l10n.faqStartStoryQ, answer: l10n.faqStartStoryA),
          _FAQ(question: l10n.faqAutoSaveQ, answer: l10n.faqAutoSaveA),
          _FAQ(question: l10n.faqPublishWorkQ, answer: l10n.faqPublishWorkA),
          _FAQ(
            question: l10n.faqOrganizeChaptersQ,
            answer: l10n.faqOrganizeChaptersA,
          ),
          _FAQ(
            question: l10n.faqMultiChapterWriterQ,
            answer: l10n.faqMultiChapterWriterA,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryCollaboration,
        icon: Icons.handshake_outlined,
        color: Colors.indigo,
        faqs: [
          _FAQ(
            question: l10n.faqCollaborationQ,
            answer: l10n.faqCollaborationA,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryDiscovery,
        icon: Icons.explore_rounded,
        color: Colors.green,
        faqs: [
          _FAQ(question: l10n.faqFindBooksQ, answer: l10n.faqFindBooksA),
          _FAQ(question: l10n.faqOriginalsQ, answer: l10n.faqOriginalsA),
          _FAQ(
            question: l10n.faqInternetArchiveQ,
            answer: l10n.faqInternetArchiveA,
          ),
          _FAQ(question: l10n.faqFeedUpdatesQ, answer: l10n.faqFeedUpdatesA),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryCommunity,
        icon: Icons.people_alt_rounded,
        color: Colors.purple,
        faqs: [
          _FAQ(question: l10n.faqDailyTopicQ, answer: l10n.faqDailyTopicA),
          _FAQ(
            question: l10n.faqDailyTopicsParticipationQ,
            answer: l10n.faqDailyTopicsParticipationA,
          ),
          _FAQ(question: l10n.faqFollowAuthorQ, answer: l10n.faqFollowAuthorA),
          _FAQ(question: l10n.faqMessagingQ, answer: l10n.faqMessagingA),
          _FAQ(
            question: l10n.faqMessagingRulesQ,
            answer: l10n.faqMessagingRulesA,
          ),
          _FAQ(question: l10n.faqPinUnpinQ, answer: l10n.faqPinUnpinA),
          _FAQ(
            question: l10n.faqReportContentQ,
            answer: l10n.faqReportContentA,
          ),
        ],
      ),
      _HelpCategory(
        title: l10n.helpCategoryAccount,
        icon: Icons.account_circle_rounded,
        color: Colors.red,
        faqs: [
          _FAQ(question: l10n.faqChangeThemeQ, answer: l10n.faqChangeThemeA),
          _FAQ(
            question: l10n.faqChangeLanguageQ,
            answer: l10n.faqChangeLanguageA,
          ),
          _FAQ(
            question: l10n.faqUpdateProfileQ,
            answer: l10n.faqUpdateProfileA,
          ),
          _FAQ(
            question: l10n.faqProfilePicturesQ,
            answer: l10n.faqProfilePicturesA,
          ),
          _FAQ(
            question: l10n.faqNotificationsQ,
            answer: l10n.faqNotificationsA,
          ),
        ],
      ),
    ];
  }

  List<_HelpCategory> _filteredCategories(BuildContext context) {
    final categories = _getCategories(context);
    if (_searchQuery.isEmpty) return categories;

    return categories
        .map((category) {
          final matchesFaqs = category.faqs
              .where(
                (faq) =>
                    faq.question.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    faq.answer.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

          if (category.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              matchesFaqs.isNotEmpty) {
            return _HelpCategory(
              title: category.title,
              icon: category.icon,
              color: category.color,
              faqs: matchesFaqs.isNotEmpty ? matchesFaqs : category.faqs,
            );
          }
          return null;
        })
        .whereType<_HelpCategory>()
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredCategories(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle), centerTitle: true),
      body: Column(
        children: [
          _buildSearchHeader(theme, l10n),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return _buildCategorySection(context, category, theme);
                    },
                  ),
          ),
          _buildSupportFooter(theme, l10n),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme, AppLocalizations l10n) {
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
          hintText: l10n.helpSearchHint,
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
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    _HelpCategory category,
    ThemeData theme,
  ) {
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
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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

  Widget _buildSupportFooter(ThemeData theme, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.stillNeedHelp,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l10n.communitySupportAssist,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => const SubmitErrorDialog(),
                    );
                  },
                  icon: const Icon(Icons.bug_report_outlined, size: 18),
                  label: Text(l10n.submitError),
                ),
                FilledButton.icon(
                  onPressed: () => _emailSupport(context, l10n),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: Text(l10n.emailSupport),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _emailSupport(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contact@wreadom.in',
      queryParameters: {'subject': 'Wreadom support'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetails('contact@wreadom.in'))),
      );
    }
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noHelpTopicsFound(_searchQuery),
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
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
