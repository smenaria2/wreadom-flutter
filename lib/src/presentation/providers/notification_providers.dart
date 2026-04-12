import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_notification_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});
