import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _notificationEvents =
      StreamController<String>.broadcast();
  final StreamController<String> _ttsActionEvents =
      StreamController<String>.broadcast();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, dynamic>? _pendingNavigationData;
  String? _pendingNavigationKey;
  String? _lastNavigationKey;
  DateTime? _lastNavigationAt;

  static const Duration _duplicateNavigationWindow = Duration(seconds: 5);
  static const int _ttsNotificationId = 4101;
  static const String ttsActionPause = 'reader_tts_pause';
  static const String ttsActionResume = 'reader_tts_resume';
  static const String ttsActionStop = 'reader_tts_stop';

  Stream<String> get notificationEvents => _notificationEvents.stream;
  Stream<String> get ttsActionEvents => _ttsActionEvents.stream;

  @visibleForTesting
  void debugEmitNotificationEvent(String notificationId) {
    _emitNotificationEvent({'notificationId': notificationId});
  }

  void attachNavigator(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _drainPendingNavigation();
  }

  void drainPendingNavigation() {
    _drainPendingNavigation();
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

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse?.payload != null) {
      _onTapNotification(launchResponse!);
    }

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
      if (kDebugMode) {
        debugPrint('Got a message whilst in the foreground!');
      }

      _emitNotificationEvent(message.data);
      if (message.notification != null) {
        _showLocalNotification(message, channel);
      }
    });

    // 5. Handle background interaction (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('App opened from notification');
      }
      _emitNotificationEvent(message.data);
      _handleRemoteMessageNavigation(message);
    });

    // 6. Handle initial message (when app is killed and opened from notification)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint('App opened from terminated state');
      }
      _emitNotificationEvent(initialMessage.data);
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        () => _handleRemoteMessageNavigation(initialMessage),
      );
    }

    _isInitialized = true;
  }

  void _emitNotificationEvent(Map<String, dynamic> data) {
    final notificationId = data['notificationId']?.toString().trim();
    if (notificationId == null || notificationId.isEmpty) return;
    if (!_notificationEvents.isClosed) {
      _notificationEvents.add(notificationId);
    }
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

  Future<void> showTtsMiniPlayer({
    required String title,
    required String body,
    required bool isPaused,
  }) async {
    if (kIsWeb) return;

    final playbackAction = isPaused
        ? const AndroidNotificationAction(
            ttsActionResume,
            'Resume',
            cancelNotification: false,
            showsUserInterface: true,
          )
        : const AndroidNotificationAction(
            ttsActionPause,
            'Pause',
            cancelNotification: false,
            showsUserInterface: true,
          );

    await _localNotifications.show(
      id: _ttsNotificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'reader_tts_channel',
          'Read aloud',
          channelDescription: 'Controls for active read-aloud playback.',
          importance: Importance.low,
          priority: Priority.low,
          category: AndroidNotificationCategory.transport,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          actions: <AndroidNotificationAction>[
            playbackAction,
            const AndroidNotificationAction(
              ttsActionStop,
              'Stop',
              cancelNotification: false,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      payload: 'reader_tts',
    );
  }

  Future<void> cancelTtsMiniPlayer() async {
    if (kIsWeb) return;
    await _localNotifications.cancel(id: _ttsNotificationId);
  }

  void _onTapNotification(NotificationResponse response) {
    if (_isTtsAction(response.actionId)) {
      _emitTtsAction(response.actionId!);
      return;
    }
    if (response.payload == 'reader_tts') return;
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint('Tapped local notification');
      }
      _navigateFromData(data);
    }
  }

  bool _isTtsAction(String? actionId) {
    return actionId == ttsActionPause ||
        actionId == ttsActionResume ||
        actionId == ttsActionStop;
  }

  void _emitTtsAction(String actionId) {
    if (!_ttsActionEvents.isClosed) {
      _ttsActionEvents.add(actionId);
    }
  }

  void _handleRemoteMessageNavigation(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    unawaited(_markNotificationDataRead(data));
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
    if (target == null) return;
    final navigationKey = _navigationKey(target, data);
    if (navigator == null) {
      if (_pendingNavigationKey == navigationKey) return;
      _pendingNavigationData = Map<String, dynamic>.from(data);
      _pendingNavigationKey = navigationKey;
      return;
    }
    if (fb_auth.FirebaseAuth.instance.currentUser == null) {
      if (_pendingNavigationKey == navigationKey) return;
      _pendingNavigationData = Map<String, dynamic>.from(data);
      _pendingNavigationKey = navigationKey;
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      return;
    }
    if (_isDuplicateNavigationKey(navigationKey)) return;

    switch (target.route) {
      case AppRoutes.publicProfile:
        navigator.pushNamed(
          target.route,
          arguments: PublicProfileArguments(userId: target.payload),
        );
        return;
      case AppRoutes.bookDetail:
        navigator.pushNamed(
          target.route,
          arguments: BookDetailArguments(
            bookId: target.payload,
            targetCommentId: target.commentId,
            targetReplyId: target.replyId,
            initialReaderChapterIndex: target.chapterIndex,
          ),
        );
        return;
      case AppRoutes.postDetail:
        navigator.pushNamed(
          target.route,
          arguments: PostDetailArguments(
            postId: target.payload,
            targetCommentId: target.commentId,
            targetReplyId: target.replyId,
          ),
        );
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

  @visibleForTesting
  void resetNavigationDedupeForTest() {
    _pendingNavigationData = null;
    _pendingNavigationKey = null;
    _lastNavigationKey = null;
    _lastNavigationAt = null;
  }

  @visibleForTesting
  bool isDuplicateNavigationForTest(
    NotificationTarget target,
    Map<String, dynamic> data,
  ) {
    return _isDuplicateNavigation(target, data);
  }

  bool _isDuplicateNavigation(
    NotificationTarget target,
    Map<String, dynamic> data,
  ) {
    return _isDuplicateNavigationKey(_navigationKey(target, data));
  }

  bool _isDuplicateNavigationKey(String key) {
    final now = DateTime.now();
    final lastAt = _lastNavigationAt;
    final isDuplicate =
        _lastNavigationKey == key &&
        lastAt != null &&
        now.difference(lastAt) < _duplicateNavigationWindow;

    _lastNavigationKey = key;
    _lastNavigationAt = now;
    return isDuplicate;
  }

  String _navigationKey(NotificationTarget target, Map<String, dynamic> data) {
    final notificationId =
        data['notificationId']?.toString().trim().isNotEmpty == true
        ? data['notificationId'].toString().trim()
        : data['id']?.toString().trim();
    return [
      notificationId?.isNotEmpty == true ? notificationId : null,
      target.route,
      target.payload,
      target.commentId,
      target.replyId,
      target.chapterIndex?.toString(),
    ].whereType<String>().join('|');
  }

  void _drainPendingNavigation() {
    final data = _pendingNavigationData;
    if (data == null) return;
    _pendingNavigationData = null;
    _pendingNavigationKey = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey?.currentState == null ||
          fb_auth.FirebaseAuth.instance.currentUser == null) {
        _pendingNavigationData = data;
        final notification = AppNotification(
          id: data['notificationId']?.toString(),
          userId: data['userId']?.toString() ?? '',
          actorId: data['actorId']?.toString() ?? '',
          actorName: data['actorName']?.toString() ?? '',
          type: data['type']?.toString() ?? '',
          text: data['text']?.toString() ?? '',
          link:
              data['url']?.toString() ??
              data['link']?.toString() ??
              data['click_action']?.toString() ??
              '',
          targetId:
              data['targetId']?.toString() ??
              data['conversationId']?.toString(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isRead: false,
          metadata: data,
        );
        final target = NotificationTargetResolver.resolve(notification);
        _pendingNavigationKey = target == null
            ? null
            : _navigationKey(target, data);
        return;
      }
      _navigateFromData(data);
    });
  }

  Future<void> _markNotificationDataRead(Map<String, dynamic> data) async {
    final notificationId =
        data['notificationId']?.toString().trim().isNotEmpty == true
        ? data['notificationId'].toString().trim()
        : data['id']?.toString().trim();
    if (notificationId == null || notificationId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Could not mark notification read: $error');
      }
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
