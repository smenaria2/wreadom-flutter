import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/notification_service.dart';

void main() {
  RemoteMessage message(Map<String, dynamic> data) =>
      RemoteMessage(data: data);

  test('prefers imageUrl, falls back to coverUrl', () {
    expect(
      NotificationService.notificationImageUrl(
        message({'imageUrl': 'https://a.com/i.jpg', 'coverUrl': 'https://b'}),
      ),
      'https://a.com/i.jpg',
    );
    expect(
      NotificationService.notificationImageUrl(
        message({'coverUrl': 'https://b.com/c.jpg'}),
      ),
      'https://b.com/c.jpg',
    );
  });

  test('rejects missing, blank and non-http urls', () {
    expect(NotificationService.notificationImageUrl(message({})), isNull);
    expect(
      NotificationService.notificationImageUrl(message({'imageUrl': ' '})),
      isNull,
    );
    expect(
      NotificationService.notificationImageUrl(
        message({'imageUrl': 'file:///etc/passwd'}),
      ),
      isNull,
    );
  });
}
