import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/navigation_providers.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import '../utils/error_message_utils.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/section_error.dart';
import '../../utils/notification_target_resolver.dart';
import '../../utils/format_utils.dart';
import '../../utils/app_haptics.dart';
import '../../domain/models/app_notification.dart';

enum _NotificationFilter {
  all,
  content,
  posts,
  messages;

  String label(AppLocalizations l10n) {
    return switch (this) {
      _NotificationFilter.all => l10n.all,
      _NotificationFilter.content => l10n.notificationContentFilter,
      _NotificationFilter.posts => l10n.posts,
      _NotificationFilter.messages => l10n.messages,
    };
  }

  bool matches(AppNotification notification) {
    if (this == _NotificationFilter.all) return true;

    return switch (this) {
      _NotificationFilter.content => _isContentNotification(notification),
      _NotificationFilter.posts => _isPostNotification(notification),
      _NotificationFilter.messages => _isMessageNotification(notification),
      _NotificationFilter.all => true,
    };
  }
}

bool _isContentNotification(AppNotification notification) {
  final type = notification.type.toLowerCase();
  const contentTypes = {
    'book_comment',
    'book_review',
    'book_reply',
    'new_creation',
    'published',
    'chapter_update',
  };
  if (contentTypes.contains(type)) return true;
  if (!_isAmbiguousActivityType(type)) return false;

  final targetType = notification.metadata?['targetType']
      ?.toString()
      .trim()
      .toLowerCase();
  if (targetType == 'book' || targetType == 'content') return true;
  return NotificationTargetResolver.resolve(notification)?.route ==
      AppRoutes.bookDetail;
}

bool _isPostNotification(AppNotification notification) {
  final type = notification.type.toLowerCase();
  const postTypes = {'post_like', 'feed_comment', 'feed_reply'};
  if (postTypes.contains(type)) return true;
  if (!_isAmbiguousActivityType(type)) return false;

  final targetType = notification.metadata?['targetType']
      ?.toString()
      .trim()
      .toLowerCase();
  if (targetType == 'post' ||
      targetType == 'feed' ||
      targetType == 'feedpost') {
    return true;
  }
  return NotificationTargetResolver.resolve(notification)?.route ==
      AppRoutes.postDetail;
}

bool _isAmbiguousActivityType(String type) {
  return type == 'comment' ||
      type == 'reply' ||
      type == 'like' ||
      type == 'mention';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;
  String? _openingNotificationKey;
  late final PageController _pageController;
  late final _LifecycleRefreshObserver _lifecycleRefreshObserver;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _lifecycleRefreshObserver = _LifecycleRefreshObserver(_refresh);
    WidgetsBinding.instance.addObserver(_lifecycleRefreshObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleRefreshObserver);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(pagedNotificationsProvider.notifier).refresh();
  }

  void _selectFilter(_NotificationFilter filter) {
    setState(() => _filter = filter);
    _pageController.animateToPage(
      _NotificationFilter.values.indexOf(filter),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    AppHaptics.selection();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(pagedNotificationsProvider);
    final notificationsController = ref.read(
      pagedNotificationsProvider.notifier,
    );
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.asData?.value;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (currentUser != null)
            TextButton(
              onPressed: () async {
                await ref
                    .read(notificationRepositoryProvider)
                    .markAllAsRead(currentUser.id);
                await notificationsController.refresh();
              },
              child: Text(l10n.markAllRead),
            ),
        ],
      ),
      body: currentUserAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentUser == null
          ? const AuthRequiredView(icon: Icons.notifications_none_rounded)
          : RefreshIndicator(
              onRefresh: notificationsController.refresh,
              child: Builder(
                builder: (context) {
                  if (notificationsState.isInitialLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (notificationsState.error != null) {
                    logUiError(
                      'Notifications load failed',
                      notificationsState.error!,
                      null,
                    );
                    return SectionError(title: l10n.notifications);
                  }
                  final items = notificationsState.items;

                  return Column(
                    children: [
                      _NotificationFilterBar(
                        selected: _filter,
                        onSelected: _selectFilter,
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _NotificationFilter.values.length,
                          onPageChanged: (index) {
                            setState(
                              () => _filter = _NotificationFilter.values[index],
                            );
                            AppHaptics.selection();
                          },
                          itemBuilder: (context, pageIndex) {
                            final pageFilter =
                                _NotificationFilter.values[pageIndex];
                            final filteredItems = _groupNotificationItems(
                              items.where(pageFilter.matches).toList(),
                            );
                            if (filteredItems.isEmpty) {
                              return Center(
                                child: Text(
                                  _emptyText(
                                    context,
                                    items.isEmpty,
                                    pageFilter,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  filteredItems.length +
                                  (notificationsState.hasMore ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                if (index == filteredItems.length &&
                                    notificationsState.hasMore) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed:
                                            notificationsState.isLoadingMore
                                            ? null
                                            : notificationsController.loadMore,
                                        icon: notificationsState.isLoadingMore
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(Icons.add_rounded),
                                        label: Text(l10n.loadMore),
                                      ),
                                    ),
                                  );
                                }
                                final displayItem = filteredItems[index];
                                final item = displayItem.latest;
                                final openKey = _notificationOpenKey(
                                  displayItem,
                                );
                                final isOpening =
                                    _openingNotificationKey == openKey;
                                return ListTile(
                                  enabled: !isOpening,
                                  leading: CircleAvatar(
                                    backgroundImage: item.actorPhotoURL != null
                                        ? CachedNetworkImageProvider(
                                            item.actorPhotoURL!,
                                          )
                                        : null,
                                    child: item.actorPhotoURL == null
                                        ? Text(
                                            item.actorName.isEmpty
                                                ? '?'
                                                : item.actorName[0]
                                                      .toUpperCase(),
                                          )
                                        : null,
                                  ),
                                  title: Text(item.actorName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(displayItem.subtitle(l10n)),
                                      Text(
                                        FormatUtils.relativeTime(
                                          item.timestamp,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  trailing: displayItem.isRead
                                      ? null
                                      : const Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: Colors.blue,
                                        ),
                                  onTap: isOpening
                                      ? null
                                      : () async {
                                          setState(() {
                                            _openingNotificationKey = openKey;
                                          });
                                          try {
                                            final target =
                                                NotificationTargetResolver.resolve(
                                                  item,
                                                );
                                            unawaited(
                                              _markNotificationItemRead(
                                                ref,
                                                displayItem,
                                              ),
                                            );
                                            if (!context.mounted) return;

                                            if (target != null) {
                                              unawaited(
                                                _markMatchingCommentNotificationsRead(
                                                  ref,
                                                  displayItem.notifications,
                                                  target,
                                                ),
                                              );
                                              if (!context.mounted) return;

                                              final routeArgs = switch (target
                                                  .route) {
                                                AppRoutes.publicProfile =>
                                                  PublicProfileArguments(
                                                    userId: target.payload,
                                                  ),
                                                AppRoutes.bookDetail =>
                                                  BookDetailArguments(
                                                    bookId: target.payload,
                                                    targetCommentId:
                                                        target.commentId,
                                                    targetReplyId:
                                                        target.replyId,
                                                  ),
                                                AppRoutes.postDetail =>
                                                  PostDetailArguments(
                                                    postId: target.payload,
                                                    targetCommentId:
                                                        target.commentId,
                                                    targetReplyId:
                                                        target.replyId,
                                                  ),
                                                AppRoutes.conversation =>
                                                  ConversationArguments(
                                                    conversationId:
                                                        target.payload,
                                                    title: item.actorName,
                                                  ),
                                                AppRoutes
                                                    .collaborationRequest =>
                                                  CollaborationRequestArguments(
                                                    bookId: target.payload,
                                                  ),
                                                _ => target.payload,
                                              };
                                              Navigator.of(context).pushNamed(
                                                target.route,
                                                arguments: routeArgs,
                                              );
                                            } else {
                                              ref
                                                  .read(
                                                    selectedTabProvider
                                                        .notifier,
                                                  )
                                                  .setTab(1);
                                              Navigator.of(context).popUntil(
                                                (route) =>
                                                    route.settings.name ==
                                                        AppRoutes.main ||
                                                    route.isFirst,
                                              );
                                            }
                                          } finally {
                                            if (mounted &&
                                                _openingNotificationKey ==
                                                    openKey) {
                                              setState(() {
                                                _openingNotificationKey = null;
                                              });
                                            }
                                          }
                                        },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  String _notificationOpenKey(_NotificationListItem item) {
    final ids = item.notifications
        .map((notification) => notification.id?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .join('|');
    if (ids.isNotEmpty) return ids;
    final latest = item.latest;
    return '${latest.type}:${latest.targetId}:${latest.timestamp}';
  }

  String _emptyText(
    BuildContext context,
    bool noNotifications,
    _NotificationFilter filter,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (noNotifications) return l10n.noNotificationsYet;
    return switch (filter) {
      _NotificationFilter.all => l10n.noNotificationsYet,
      _NotificationFilter.content => l10n.noBookNotificationsYet,
      _NotificationFilter.posts => l10n.noPostNotificationsYet,
      _NotificationFilter.messages => l10n.noMessageNotificationsYet,
    };
  }
}

Future<void> _markMatchingCommentNotificationsRead(
  WidgetRef ref,
  List<AppNotification> notifications,
  NotificationTarget target,
) async {
  final commentId = target.commentId?.trim();
  if (commentId == null || commentId.isEmpty) return;

  final repository = ref.read(notificationRepositoryProvider);
  final seen = <String>{};
  for (final notification in notifications) {
    final id = notification.id;
    if (id == null || notification.isRead || !seen.add(id)) continue;
    final notificationTarget = NotificationTargetResolver.resolve(notification);
    if (notificationTarget?.commentId == commentId) {
      await repository.markAsRead(id);
    }
  }
}

Future<void> _markNotificationItemRead(
  WidgetRef ref,
  _NotificationListItem item,
) async {
  final repository = ref.read(notificationRepositoryProvider);
  final ids = <String>{};
  for (final notification in item.notifications) {
    final id = notification.id?.trim();
    if (id == null || id.isEmpty || notification.isRead || !ids.add(id)) {
      continue;
    }
    await _ignoreRefresh(repository.markAsRead(id));
  }
}

Future<Object?> _ignoreRefresh<T>(Future<T> future) async {
  try {
    return await future;
  } catch (_) {
    return null;
  }
}

List<_NotificationListItem> _groupNotificationItems(
  List<AppNotification> notifications,
) {
  final result = <_NotificationListItem>[];
  final messageGroups = <String, List<AppNotification>>{};
  final visibleNotifications = _dedupeSupersededContentNotifications(
    notifications,
  );

  for (final notification in visibleNotifications) {
    if (!_isMessageNotification(notification)) {
      result.add(_NotificationListItem.single(notification));
      continue;
    }
    final metadata = notification.metadata ?? const <String, dynamic>{};
    final conversationId =
        metadata['conversationId']?.toString().trim().isNotEmpty == true
        ? metadata['conversationId'].toString().trim()
        : NotificationTargetResolver.resolve(notification)?.payload;
    final key = conversationId == null || conversationId.isEmpty
        ? notification.actorId
        : '${notification.actorId}:$conversationId';
    messageGroups.putIfAbsent(key, () => <AppNotification>[]).add(notification);
  }

  for (final group in messageGroups.values) {
    group.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    result.add(_NotificationListItem.group(group));
  }

  result.sort((a, b) => b.latest.timestamp.compareTo(a.latest.timestamp));
  return result;
}

List<AppNotification> _dedupeSupersededContentNotifications(
  List<AppNotification> notifications,
) {
  final reviewKeys = notifications
      .where((notification) => notification.type.toLowerCase() == 'book_review')
      .map(_contentCommentKey)
      .whereType<String>()
      .toSet();
  if (reviewKeys.isEmpty) return notifications;

  return notifications.where((notification) {
    final type = notification.type.toLowerCase();
    if (type != 'book_comment' && type != 'comment') return true;
    final text = notification.text.toLowerCase();
    final looksLikeBookComment =
        text == 'commented on your content' ||
        text.startsWith('commented on your book:') ||
        text.contains(' has commented on ');
    if (!looksLikeBookComment && type != 'book_comment') return true;
    final key = _contentCommentKey(notification);
    return key == null || !reviewKeys.contains(key);
  }).toList();
}

String? _contentCommentKey(AppNotification notification) {
  final target = NotificationTargetResolver.resolve(notification);
  final metadata = notification.metadata ?? const <String, dynamic>{};
  final bookId = _firstNonEmptyString([
    metadata['bookId'],
    metadata['book'],
    metadata['contentId'],
    target?.payload,
    notification.targetId,
  ]);
  final commentId = _firstNonEmptyString([
    metadata['commentId'],
    metadata['parentCommentId'],
    metadata['targetCommentId'],
    target?.commentId,
  ]);
  if (bookId == null || commentId == null) return null;
  return '${notification.userId}|${notification.actorId}|$bookId|$commentId';
}

String? _firstNonEmptyString(Iterable<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

bool _isMessageNotification(AppNotification notification) {
  final type = notification.type.toLowerCase();
  final text = notification.text.toLowerCase();
  return type == 'message' ||
      type == 'groupmessage' ||
      text.contains('message');
}

class _NotificationListItem {
  const _NotificationListItem._(this.notifications);

  factory _NotificationListItem.single(AppNotification notification) =>
      _NotificationListItem._([notification]);

  factory _NotificationListItem.group(List<AppNotification> notifications) =>
      _NotificationListItem._(notifications);

  final List<AppNotification> notifications;

  AppNotification get latest => notifications.first;
  bool get isRead => notifications.every((notification) => notification.isRead);
  bool get isMessageGroup =>
      notifications.length > 1 && _isMessageNotification(latest);

  String subtitle(AppLocalizations l10n) {
    if (!isMessageGroup && !_isMessageNotification(latest)) {
      return _localizedNotificationText(latest, l10n);
    }
    final preview = _messagePreview(latest.text, l10n);
    if (latest.text.trim().toLowerCase() == 'sent you a book') {
      return l10n.sentYouBook;
    }
    if (preview.isEmpty) return l10n.sentYouAMessage;
    return '${l10n.sentYouAMessage} $preview';
  }

  String _localizedNotificationText(
    AppNotification notification,
    AppLocalizations l10n,
  ) {
    return localizedNotificationText(notification, l10n);
  }

  String _messagePreview(String text, AppLocalizations l10n) {
    var preview = text.trim();
    final marker = l10n.sentYouAMessage.replaceAll('.', '').trim();
    preview = preview.replaceFirst(
      RegExp(RegExp.escape(marker), caseSensitive: false),
      '',
    );
    preview = preview.replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
    return preview;
  }
}

class _LifecycleRefreshObserver extends WidgetsBindingObserver {
  _LifecycleRefreshObserver(this.onResume);

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResume());
    }
  }
}

String localizedNotificationText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final type = notification.type.toLowerCase();
  final text = notification.text.trim().toLowerCase();
  final isHindi = l10n.localeName.toLowerCase().startsWith('hi');
  if (type == 'follow' || text == 'started following you') {
    return l10n.startedFollowingYou;
  }
  if (type == 'post_like' || text == 'liked your post') {
    return l10n.likedYourPost;
  }
  if (type == 'feed_comment' || text == 'commented on your post') {
    return l10n.commentedOnYourPost;
  }
  if (type == 'feed_reply' || text == 'replied to your comment') {
    return l10n.repliedToYourComment;
  }
  if ((isHindi && type == 'book_reply') ||
      text == 'replied to your discussion') {
    final detailedReplyText = isHindi
        ? _localizedHindiBookReplyText(notification, l10n)
        : null;
    if (detailedReplyText != null) return detailedReplyText;
    return l10n.repliedToYourBookComment;
  }
  if ((isHindi && type == 'book_review') ||
      text == 'left a review on your content' ||
      text == 'submitted an audio review on your content') {
    final detailedReviewText = isHindi
        ? _localizedHindiBookReviewText(notification, l10n)
        : null;
    if (detailedReviewText != null) return detailedReviewText;
    return l10n.reviewedYourBook;
  }
  if ((isHindi && type == 'book_comment') ||
      text == 'commented on your content') {
    final detailedCommentText = isHindi
        ? _localizedHindiBookCommentText(notification, l10n)
        : null;
    if (detailedCommentText != null) return detailedCommentText;
    return l10n.commentedOnYourContent;
  }
  if (isHindi && (type == 'new_creation' || type == 'published')) {
    final detailedPublishedText = _localizedHindiPublishedText(
      notification,
      l10n,
    );
    if (detailedPublishedText != null) return detailedPublishedText;
  }
  if (isHindi && type == 'chapter_update') {
    final detailedChapterText = _localizedHindiChapterUpdateText(
      notification,
      l10n,
    );
    if (detailedChapterText != null) return detailedChapterText;
  }
  if (type == 'message') {
    if (text == 'sent you a book') return l10n.sentYouBook;
    return l10n.sentYouAMessage;
  }
  if (type == 'collaboration_request' ||
      text.endsWith('wants to collaborate with you.')) {
    return l10n.wantsToCollaborate;
  }
  if (type == 'collaboration_removed') {
    if (text.contains('removed themselves')) {
      return l10n.removedThemselfAsCoAuthor;
    }
    return l10n.removedYouAsCoAuthor;
  }
  return notification.text;
}

String? _localizedHindiBookReplyText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final title = _firstQuotedValueAfter(
    notification.text,
    'has replied to your review on',
  );
  if (title == null) return null;
  return l10n.repliedToContentReviewNotification(title);
}

String? _localizedHindiBookCommentText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final title = _firstQuotedValueAfter(notification.text, 'has commented on');
  if (title == null) return null;
  return l10n.commentedOnContentNotification(title);
}

String? _localizedHindiBookReviewText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final text = notification.text.trim();
  final chapterReviewMatch = RegExp(
    r'''^.+?\s+has left a review on\s+(?:chapter\s+)?['"]([^'"]+)['"]\s+of\s+[^'"]+['"]([^'"]+)['"]\.?$''',
    caseSensitive: false,
  ).firstMatch(text);
  if (chapterReviewMatch != null) {
    return l10n.reviewedChapterNotification(
      chapterReviewMatch.group(1)!.trim(),
      chapterReviewMatch.group(2)!.trim(),
    );
  }

  final contentReviewMatch = RegExp(
    r'''^.+?\s+has left a review on\s+[^'"]+['"]([^'"]+)['"]\.?$''',
    caseSensitive: false,
  ).firstMatch(text);
  if (contentReviewMatch != null) {
    return l10n.reviewedContentNotification(
      contentReviewMatch.group(1)!.trim(),
    );
  }

  return null;
}

String? _localizedHindiPublishedText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final title = _firstQuotedValueAfter(notification.text, 'has published');
  if (title == null) return null;
  return l10n.publishedBookNotification(title);
}

String? _localizedHindiChapterUpdateText(
  AppNotification notification,
  AppLocalizations l10n,
) {
  final match = RegExp(
    r'''^.+?\s+has published a new chapter\s+['"]([^'"]+)['"]\s+to\s+[^'"]+['"]([^'"]+)['"]\.?$''',
    caseSensitive: false,
  ).firstMatch(notification.text.trim());
  if (match == null) return null;
  return l10n.publishedChapterNotification(
    match.group(1)!.trim(),
    match.group(2)!.trim(),
  );
}

String? _firstQuotedValueAfter(String text, String marker) {
  final match = RegExp(
    '${RegExp.escape(marker)}[^\'"]*[\'"]([^\'"]+)[\'"]',
    caseSensitive: false,
  ).firstMatch(text);
  return match?.group(1)?.trim();
}

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _NotificationFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _NotificationFilter.values[index];
          return FilterChip(
            label: Text(filter.label(l10n)),
            selected: selected == filter,
            showCheckmark: false,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}
