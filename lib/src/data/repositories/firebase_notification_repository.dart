import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_notification.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/repositories/notification_repository.dart';
import '../utils/firestore_utils.dart';
import '../../utils/map_utils.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createNotification(AppNotification notification) async {
    if (notification.userId == notification.actorId) return;
    final data = notification.toJson();
    data.removeWhere((key, value) => value == null);
    await _firestore.collection('notifications').add(data);
  }

  @override
  Future<void> createNotifications(List<AppNotification> notifications) async {
    final batch = _firestore.batch();
    for (final notification in notifications) {
      if (notification.userId == notification.actorId) continue;
      final data = notification.toJson();
      data.removeWhere((key, value) => value == null);
      batch.set(_firestore.collection('notifications').doc(), data);
    }
    await batch.commit();
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var i = 0; i < snapshot.docs.length; i += 450) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs.skip(i).take(450)) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map((doc) {
            final data = mapFirestoreData(doc.data(), doc.id);
            return AppNotification.fromJson(data);
          }).toList();
          return items;
        });
  }

  @override
  Future<PagedResult<AppNotification>> getNotificationsPage(
    String userId, {
    int limit = 25,
    Object? cursor,
  }) async {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (cursor is DocumentSnapshot) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final pageDocs = snapshot.docs.take(limit).toList();
    final items = pageDocs.map((doc) {
      final data = mapFirestoreData(asStringMap(doc.data()), doc.id);
      return AppNotification.fromJson(data);
    }).toList();
    return PagedResult(
      items: items,
      hasMore: snapshot.docs.length > limit,
      nextCursor: pageDocs.isEmpty ? cursor : pageDocs.last,
    );
  }
}
