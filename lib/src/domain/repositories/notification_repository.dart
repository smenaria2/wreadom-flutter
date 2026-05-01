import '../models/app_notification.dart';
import '../models/paged_result.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<PagedResult<AppNotification>> getNotificationsPage(
    String userId, {
    int limit = 25,
    Object? cursor,
  });
  Future<void> createNotification(AppNotification notification);
  Future<void> createNotifications(List<AppNotification> notifications);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
