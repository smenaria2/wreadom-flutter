import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../../domain/models/app_notification.dart';
import '../../presentation/routing/app_routes.dart';
import '../../presentation/routing/app_router.dart';
import '../../utils/notification_target_resolver.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using them.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigator(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialise background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Initialise local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTapNotification,
    );

    // 3. Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message, channel);
      }
    });

    // 5. Handle background interaction (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.data}');
      _handleRemoteMessageNavigation(message);
    });

    // 6. Handle initial message (when app is killed and opened from notification)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state: ${initialMessage.data}');
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        () => _handleRemoteMessageNavigation(initialMessage),
      );
    }

    _isInitialized = true;
  }

  Future<void> _showLocalNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
            importance: channel.importance,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onTapNotification(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      debugPrint('Tapped local notification with data: $data');
      _navigateFromData(data);
    }
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final rawLink =
        data['url']?.toString() ??
        data['link']?.toString() ??
        data['click_action']?.toString() ??
        '';
    final notification = AppNotification(
      id: data['notificationId']?.toString(),
      userId: data['userId']?.toString() ?? '',
      actorId: data['actorId']?.toString() ?? '',
      actorName: data['actorName']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      link: rawLink,
      targetId:
          data['targetId']?.toString() ?? data['conversationId']?.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isRead: false,
      metadata: data,
    );
    final target = NotificationTargetResolver.resolve(notification);
    final navigator = _navigatorKey?.currentState;
    if (target == null || navigator == null) return;

    switch (target.route) {
      case AppRoutes.publicProfile:
        navigator.pushNamed(
          target.route,
          arguments: PublicProfileArguments(userId: target.payload),
        );
        return;
      case AppRoutes.bookDetail:
        navigator.pushNamed(target.route, arguments: target.payload);
        return;
      case AppRoutes.postDetail:
        navigator.pushNamed(target.route, arguments: target.payload);
        return;
      case AppRoutes.conversation:
        navigator.pushNamed(
          target.route,
          arguments: ConversationArguments(
            conversationId: target.payload,
            title: data['actorName']?.toString() ?? '',
          ),
        );
        return;
      case AppRoutes.collaborationRequest:
        navigator.pushNamed(
          target.route,
          arguments: CollaborationRequestArguments(bookId: target.payload),
        );
        return;
      case AppRoutes.dailyTopic:
        navigator.pushNamed(target.route, arguments: target.payload);
        return;
      default:
        navigator.pushNamed(target.route, arguments: target.payload);
    }
  }

  Future<String?> getFcmToken() async {
    return await _fcm.getToken();
  }

  Future<bool> requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      return true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
      return true;
    } else {
      debugPrint('User declined or has not accepted permission');
      return false;
    }
  }

  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
