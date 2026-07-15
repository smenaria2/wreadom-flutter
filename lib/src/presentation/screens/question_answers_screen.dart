import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../components/create_post_sheet.dart';
import '../components/feed_post_card.dart';
import '../providers/feed_providers.dart';
import '../widgets/glass_scaffold.dart';
import '../../utils/app_link_helper.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/glass_surface.dart';

class QuestionAnswersScreen extends ConsumerWidget {
  final QuestionLeafAnswersQuery query;

  const QuestionAnswersScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final answersAsync = ref.watch(questionLeafAnswersProvider(query));

    return GlassScaffold(
      appBar: glassAppBar(
        title: Text(l10n.answers),
        actions: [
          IconButton(
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(
              AppLinkHelper.questionAnswers(query.bookId, query.leafId),
              subject: query.question,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showCreatePostSheet(
            context,
            initialQuestion: query.question,
            questionLeafId: query.leafId,
            lockQuestion: true,
            bookId: query.bookId,
          );
          ref.invalidate(questionLeafAnswersProvider(query));
        },
        label: Text(l10n.reply),
        icon: const Icon(Icons.edit_outlined),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: GlassSurface(
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.leafQuestion,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              query.question,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(questionLeafAnswersProvider(query));
                  await ref.read(questionLeafAnswersProvider(query).future);
                },
                child: answersAsync.when(
                  data: (posts) {
                    if (posts.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.4,
                            child: Center(
                              child: Text(
                                'No answers yet.\nBe the first to answer this question!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FeedPostCard(
                            post: posts[index],
                            openOnTap: true,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.4,
                        child: Center(
                          child: Text(
                            'Failed to load answers.\n$err',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
