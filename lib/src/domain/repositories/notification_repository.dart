import '../models/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> createNotification(AppNotification notification);
  Future<void> createNotifications(List<AppNotification> notifications);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}
