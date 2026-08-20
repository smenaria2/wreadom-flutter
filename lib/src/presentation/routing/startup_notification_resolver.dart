import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/app_notification.dart';
import '../../utils/notification_target_resolver.dart';
import '../providers/feed_providers.dart';
import 'app_router.dart';
import 'app_routes.dart';

class StartupNotificationLaunch {
  const StartupNotificationLaunch({
    required this.hasInitialNotification,
    this.target,
    this.data,
  });

  final bool hasInitialNotification;
  final RouteSettings? target;
  final Map<String, dynamic>? data;
}

class StartupNotificationResolver {
  static Future<StartupNotificationLaunch> inspectInitialNotification() async {
    if (kIsWeb) {
      return const StartupNotificationLaunch(hasInitialNotification: false);
    }

    try {
      // 1. Check FCM initial message
      final fcmMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);

      if (fcmMessage != null && fcmMessage.data.isNotEmpty) {
        final target = _routeSettingsFromData(fcmMessage.data);
        return StartupNotificationLaunch(
          hasInitialNotification: true,
          target: target,
          data: fcmMessage.data,
        );
      }

      // 2. Check local notifications launch details
      final localPlugin = FlutterLocalNotificationsPlugin();
      final launchDetails = await localPlugin
          .getNotificationAppLaunchDetails()
          .timeout(const Duration(milliseconds: 600), onTimeout: () => null);

      final payload = launchDetails?.notificationResponse?.payload;
      if (launchDetails?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.trim().isNotEmpty) {
        if (payload != 'reader_tts' && payload != 'audio_post') {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              final data = decoded.map(
                (k, v) => MapEntry(k.toString(), v),
              );
              final target = _routeSettingsFromData(data);
              return StartupNotificationLaunch(
                hasInitialNotification: true,
                target: target,
                data: data,
              );
            }
          } catch (e) {
            debugPrint('Failed to decode local notification launch payload: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error inspecting initial notification: $e');
    }

    return const StartupNotificationLaunch(hasInitialNotification: false);
  }

  static RouteSettings? _routeSettingsFromData(Map<String, dynamic> data) {
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
    if (target == null) return null;

    switch (target.route) {
      case AppRoutes.publicProfile:
        return RouteSettings(
          name: target.route,
          arguments: PublicProfileArguments(userId: target.payload),
        );
      case AppRoutes.bookDetail:
        return RouteSettings(
          name: target.route,
          arguments: BookDetailArguments(
            bookId: target.payload,
            targetCommentId: target.commentId,
            targetReplyId: target.replyId,
            targetLeafId: target.leafId,
            initialReaderChapterIndex: target.chapterIndex,
          ),
        );
      case AppRoutes.postDetail:
        return RouteSettings(
          name: target.route,
          arguments: PostDetailArguments(
            postId: target.payload,
            targetCommentId: target.commentId,
            targetReplyId: target.replyId,
          ),
        );
      case AppRoutes.conversation:
        return RouteSettings(
          name: target.route,
          arguments: ConversationArguments(
            conversationId: target.payload,
            title: data['actorName']?.toString() ?? '',
          ),
        );
      case AppRoutes.collaborationRequest:
        return RouteSettings(
          name: target.route,
          arguments: CollaborationRequestArguments(bookId: target.payload),
        );
      case AppRoutes.dailyTopic:
        return RouteSettings(name: target.route, arguments: target.payload);
      case AppRoutes.questionAnswers:
        if (target.payload.isNotEmpty &&
            target.leafId != null &&
            target.leafId!.isNotEmpty) {
          return RouteSettings(
            name: target.route,
            arguments: QuestionAnswersLinkArguments(
              bookId: target.payload,
              leafId: target.leafId!,
            ),
          );
        } else if (target.question != null && target.question!.isNotEmpty) {
          return RouteSettings(
            name: target.route,
            arguments: QuestionLeafAnswersQuery(
              bookId: target.payload,
              leafId: target.leafId ?? '',
              question: target.question!,
            ),
          );
        } else {
          return RouteSettings(name: target.route, arguments: target.payload);
        }
      default:
        return RouteSettings(name: target.route, arguments: target.payload);
    }
  }
}
