import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/models/user_model.dart';
import '../providers/notification_providers.dart';

Future<void> createAppNotification(
  WidgetRef ref, {
  required String userId,
  required UserModel actor,
  required String type,
  required String text,
  required String link,
  String? targetId,
  Map<String, dynamic>? metadata,
}) async {
  if (userId == actor.id) return;
  try {
    await ref
        .read(notificationRepositoryProvider)
        .createNotification(
          AppNotification(
            userId: userId,
            actorId: actor.id,
            actorName: actor.displayName ?? actor.username,
            actorPhotoURL: actor.photoURL,
            type: type,
            text: text,
            link: link,
            targetId: targetId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isRead: false,
            metadata: metadata,
          ),
        );
  } catch (error) {
    debugPrint('Notification write skipped: $error');
  }
}
