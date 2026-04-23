import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/navigation_providers.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import '../../utils/notification_target_resolver.dart';
import '../../utils/format_utils.dart';
import '../../domain/models/app_notification.dart';

enum _NotificationFilter {
  all,
  messages,
  posts,
  books;

  String label(AppLocalizations l10n) {
    return switch (this) {
      _NotificationFilter.all => l10n.all,
      _NotificationFilter.messages => l10n.messages,
      _NotificationFilter.posts => l10n.posts,
      _NotificationFilter.books => l10n.books,
    };
  }

  bool matches(AppNotification notification) {
    if (this == _NotificationFilter.all) return true;

    final type = notification.type.toLowerCase();
    final text = notification.text.toLowerCase();
    final link = notification.link.toLowerCase();
    final targetType = notification.metadata?['targetType']
        ?.toString()
        .toLowerCase();
    final haystack = '$type $text $link ${targetType ?? ''}';

    return switch (this) {
      _NotificationFilter.messages =>
        type == 'message' ||
            haystack.contains('message') ||
            haystack.contains('chat'),
      _NotificationFilter.posts =>
        haystack.contains('post') ||
            haystack.contains('comment') ||
            haystack.contains('like') ||
            haystack.contains('follow'),
      _NotificationFilter.books =>
        haystack.contains('book') ||
            haystack.contains('story') ||
            haystack.contains('chapter') ||
            haystack.contains('review') ||
            haystack.contains('quote'),
      _NotificationFilter.all => true,
    };
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _limit = 25;
  static const int _increment = 25;
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              final user = await ref.read(currentUserProvider.future);
              if (user == null) return;
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead(user.id);
            },
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          final filteredItems = items.where(_filter.matches).toList();

          final displayCount = (_limit < filteredItems.length)
              ? _limit
              : filteredItems.length;
          final hasMore = _limit < filteredItems.length;

          return Column(
            children: [
              _NotificationFilterBar(
                selected: _filter,
                onSelected: (filter) {
                  setState(() {
                    _filter = filter;
                    _limit = _increment;
                  });
                },
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(child: Text(_emptyText(context, items.isEmpty)))
                    : ListView.separated(
                        itemCount: displayCount + (hasMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == displayCount && hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _limit += _increment),
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(l10n.loadMore),
                                ),
                              ),
                            );
                          }
                          final item = filteredItems[index];
                          return ListTile(
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
                                          : item.actorName[0].toUpperCase(),
                                    )
                                  : null,
                            ),
                            title: Text(item.actorName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.text),
                                Text(
                                  '${FormatUtils.relativeTime(item.timestamp)} ago',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            trailing: item.isRead
                                ? null
                                : const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.blue,
                                  ),
                            onTap: () async {
                              if (item.id != null) {
                                await ref
                                    .read(notificationRepositoryProvider)
                                    .markAsRead(item.id!);
                              }

                              if (!context.mounted) return;

                              final metadata = item.metadata ?? {};
                              if (item.type == 'message') {
                                final convId =
                                    metadata['conversationId']?.toString() ??
                                    metadata['id']?.toString() ??
                                    (item.targetId != null &&
                                            item.targetId!.isNotEmpty
                                        ? item.targetId
                                        : null) ??
                                    '';

                                if (convId.isNotEmpty &&
                                    convId != 'null' &&
                                    convId != 'undefined' &&
                                    !convId.contains('/') &&
                                    convId.length > 5) {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.conversation,
                                    arguments: ConversationArguments(
                                      conversationId: convId,
                                      title: item.actorName,
                                    ),
                                  );
                                } else {
                                  debugPrint(
                                    'Invalid conversationId in notification: $convId',
                                  );
                                }
                                return;
                              }

                              final target = NotificationTargetResolver.resolve(
                                item,
                              );
                              if (target != null) {
                                final routeArgs =
                                    target.route == AppRoutes.publicProfile
                                    ? PublicProfileArguments(
                                        userId: target.payload,
                                      )
                                    : target.payload;
                                Navigator.of(
                                  context,
                                ).pushNamed(target.route, arguments: routeArgs);
                              } else {
                                ref
                                    .read(selectedTabProvider.notifier)
                                    .setTab(1);
                                Navigator.of(context).popUntil(
                                  (route) =>
                                      route.settings.name == AppRoutes.main ||
                                      route.isFirst,
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }

  String _emptyText(BuildContext context, bool noNotifications) {
    final l10n = AppLocalizations.of(context)!;
    if (noNotifications) return l10n.noNotificationsYet;
    return switch (_filter) {
      _NotificationFilter.all => l10n.noNotificationsYet,
      _NotificationFilter.messages => l10n.noMessageNotificationsYet,
      _NotificationFilter.posts => l10n.noPostNotificationsYet,
      _NotificationFilter.books => l10n.noBookNotificationsYet,
    };
  }
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
