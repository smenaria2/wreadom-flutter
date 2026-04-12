import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';

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
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.actorPhotoURL != null
                      ? NetworkImage(item.actorPhotoURL!)
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
