import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/navigation_providers.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';
import '../../utils/notification_target_resolver.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _limit = 25;
  static const int _increment = 25;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final user = await ref.read(currentUserProvider.future);
              if (user == null) return;
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead(user.id);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final displayCount = (_limit < items.length) ? _limit : items.length;
          final hasMore = _limit < items.length;

          return ListView.separated(
            itemCount: displayCount + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == displayCount && hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _limit += _increment),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Load More'),
                    ),
                  ),
                );
              }
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.actorPhotoURL != null
                      ? CachedNetworkImageProvider(item.actorPhotoURL!)
                      : null,
                  child: item.actorPhotoURL == null
                      ? Text(item.actorName.isEmpty
                          ? '?'
                          : item.actorName[0].toUpperCase())
                      : null,
                ),
                title: Text(item.actorName),
                subtitle: Text(item.text),
                trailing: item.isRead
                    ? null
                    : const Icon(Icons.circle, size: 10, color: Colors.blue),
                onTap: () async {
                  if (item.id != null) {
                    await ref
                        .read(notificationRepositoryProvider)
                        .markAsRead(item.id!);
                  }

                  if (!context.mounted) return;

                  final metadata = item.metadata ?? {};
                  if (item.type == 'message') {
                      final convId = metadata['conversationId']?.toString() ??
                                   metadata['id']?.toString() ??
                                   (item.targetId != null && item.targetId!.isNotEmpty ? item.targetId : null) ??
                                   '';
                      
                      // Robust check to avoid "Invalid document path"
                      if (convId.isNotEmpty && 
                          convId != 'null' && 
                          convId != 'undefined' && 
                          !convId.contains('/') && // Minimal sanity check for Firestore IDs
                          convId.length > 5) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.conversation,
                          arguments: ConversationArguments(
                            conversationId: convId,
                            title: item.actorName,
                          ),
                        );
                      } else {
                        debugPrint('Invalid conversationId in notification: $convId');
                      }
                      return;
                  }

                  final target = NotificationTargetResolver.resolve(item);
                  if (target != null) {
                    final routeArgs = target.route == AppRoutes.publicProfile
                        ? PublicProfileArguments(userId: target.payload)
                        : target.payload;
                    Navigator.of(context).pushNamed(target.route, arguments: routeArgs);
                  } else {
                    ref.read(selectedTabProvider.notifier).setTab(1);
                    Navigator.of(context).popUntil(
                      (route) => route.settings.name == AppRoutes.main || route.isFirst,
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}
