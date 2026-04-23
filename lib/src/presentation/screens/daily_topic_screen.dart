import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/book.dart';
import '../../domain/models/homepage/homepage_metadata.dart';
import '../../utils/app_link_helper.dart';
import '../components/book_card.dart';
import '../providers/book_providers.dart';
import '../providers/daily_topic_providers.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

class DailyTopicArguments {
  const DailyTopicArguments({this.topicId, this.topic});

  final String? topicId;
  final DailyTopic? topic;
}

final dailyTopicByIdProvider = FutureProvider.family<DailyTopic?, String?>((
  ref,
  topicId,
) async {
  final topics = await ref.watch(dailyTopicsProvider.future);
  if (topics.isEmpty) return null;
  if (topicId == null || topicId.isEmpty) return topics.first;
  for (final topic in topics) {
    if (topic.id == topicId) return topic;
  }
  return null;
});

final dailyTopicBooksProvider = FutureProvider.family<List<Book>, DailyTopic>((
  ref,
  topic,
) async {
  if (topic.topicName.trim().isEmpty) return [];
  final repo = ref.watch(bookRepositoryProvider);
  final topicName = topic.topicName.trim();
  return (await repo.getOriginalBooksByTopic(topicName, limit: 40))..sort(
    (a, b) => (b.updatedAt ?? b.createdAt ?? 0).compareTo(
      a.updatedAt ?? a.createdAt ?? 0,
    ),
  );
});

class DailyTopicScreen extends ConsumerWidget {
  const DailyTopicScreen({super.key, this.topicId, this.preloadedTopic});

  final String? topicId;
  final DailyTopic? preloadedTopic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topicAsync = preloadedTopic != null
        ? AsyncValue.data(preloadedTopic)
        : ref.watch(dailyTopicByIdProvider(topicId));

    return Scaffold(
      body: topicAsync.when(
        data: (topic) {
          if (topic == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.dailyTopic)),
              body: Center(child: Text(l10n.dailyTopicNotFound)),
            );
          }
          return _DailyTopicBody(topic: topic);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text(l10n.dailyTopic)),
          body: Center(child: Text(l10n.failedToLoadTopic(error.toString()))),
        ),
      ),
    );
  }
}

class _DailyTopicBody extends ConsumerWidget {
  const _DailyTopicBody({required this.topic});

  final DailyTopic topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(dailyTopicBooksProvider(topic));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          title: Text(l10n.dailyTopic),
          actions: [
            IconButton(
              tooltip: l10n.sharePost,
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final id = topic.id.isNotEmpty ? topic.id : topic.topicName;
                Share.share(
                  l10n.writeOnDailyTopic(
                    topic.topicName,
                    AppLinkHelper.dailyTopic(id),
                  ),
                  subject: topic.topicName,
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (topic.coverImageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: topic.coverImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _TopicFallback(topic: topic),
                  )
                else
                  _TopicFallback(topic: topic),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.dailyTopic,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topic.topicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
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
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (topic.fullDescription.isNotEmpty) ...[
                Text(
                  l10n.aboutThisTopic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  topic.fullDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.participateNow),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.writerPad,
                    arguments: WriterPadArguments(
                      initialTopic: topic.topicName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    l10n.submissionsReceived,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  booksAsync.maybeWhen(
                    data: (books) => Chip(
                      label: Text('${books.length}'),
                      visualDensity: VisualDensity.compact,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        booksAsync.when(
          data: (books) {
            if (books.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(l10n.noSubmissionsYet)),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.56,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => BookCard(book: books[index]),
                  childCount: books.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(l10n.failedToLoadSubmissions(error.toString())),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicFallback extends StatelessWidget {
  const _TopicFallback({required this.topic});

  final DailyTopic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_stories_rounded,
        size: 72,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
