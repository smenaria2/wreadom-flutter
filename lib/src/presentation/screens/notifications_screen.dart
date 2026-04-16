import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/navigation_providers.dart';
import '../routing/app_routes.dart';
import '../routing/app_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
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

                  // Navigation debug
                  debugPrint('Notification tapped: ID=${item.id}, Type=${item.type}, TargetId=${item.targetId}');
                  debugPrint('Metadata: ${item.metadata}');
                  debugPrint('Link: ${item.link}');

                  // Navigation logic
                  final metadata = item.metadata ?? {};
                  final link = item.link;
                  final targetId = item.targetId;
                  
                  // Priority check for bookId in metadata or link
                  final bookIdFromMeta = metadata['bookId']?.toString();
                  String? bookIdFromLink;
                  if (link.contains('/book/')) {
                    bookIdFromLink = link.split('/book/').last.split('?').first;
                  } else if (link.contains('/b/')) {
                    bookIdFromLink = link.split('/b/').last.split('?').first;
                  }
                  
                  final effectiveBookId = bookIdFromMeta ?? bookIdFromLink;

                  final isBookRelated = effectiveBookId != null || 
                                      ['chapter', 'book_review', 'book_quote', 'published'].contains(item.type);

                  switch (item.type) {
                    case 'post':
                    case 'feedPost':
                    case 'like':
                    case 'comment':
                    case 'reply':
                      // Prioritize post detail if we have a targetId (the post ID)
                      // unless it's explicitly a book-only notification
                      if (targetId != null && targetId.isNotEmpty && targetId != 'null') {
                        Navigator.of(context).pushNamed(
                          AppRoutes.postDetail,
                          arguments: targetId,
                        );
                      } else if (isBookRelated && effectiveBookId != null) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: effectiveBookId,
                        );
                      } else {
                        // Fallback to Feed tab (index 1) without pushing new shell
                        ref.read(selectedTabProvider.notifier).setTab(1);
                        Navigator.of(context).popUntil((route) => 
                          route.settings.name == AppRoutes.main || route.isFirst);
                      }
                      break;
                    case 'published':
                    case 'chapter':
                      final id = effectiveBookId ?? targetId;
                      if (id != null && id.isNotEmpty) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: id,
                        );
                      }
                      break;
                    case 'follow':
                    case 'following':
                      String? followerId = item.actorId.isNotEmpty ? item.actorId : null;
                      
                      // Fallback: check link for userId if actorId is missing
                      if (followerId == null || followerId.isEmpty) {
                        if (link.contains('/user/')) {
                          followerId = link.split('/user/').last.split('?').first;
                        } else if (link.contains('/u/')) {
                          followerId = link.split('/u/').last.split('?').first;
                        }
                      }
                      
                      // Last resort: targetId if it's a valid ID
                      followerId ??= (targetId != null && targetId.isNotEmpty && targetId != 'null') ? targetId : null;

                      if (followerId != null && followerId.isNotEmpty) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.publicProfile,
                          arguments: PublicProfileArguments(userId: followerId),
                        );
                      }
                      break;
                    case 'message':
                      final convId = metadata['conversationId']?.toString() ?? 
                                   metadata['id']?.toString() ?? 
                                   (targetId != null && targetId.isNotEmpty ? targetId : null) ??
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
                      break;
                    case 'book_review':
                    case 'book_quote':
                      final id = effectiveBookId ?? targetId;
                      if (id != null && id.isNotEmpty) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.bookDetail,
                          arguments: id,
                        );
                      }
                      break;
                    default:
                      if (link.isNotEmpty) {
                        // Optional: hande as deep link if nothing else matches
                        Navigator.of(context).pushNamed(link);
                      }
                      break;
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
