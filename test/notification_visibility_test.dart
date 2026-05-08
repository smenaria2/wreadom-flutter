import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/notification_service.dart';
import 'package:librebook_flutter/src/domain/models/app_notification.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/screens/notifications_screen.dart';

void main() {
  AppNotification notification({required String type, required String text}) {
    return AppNotification(
      id: 'n1',
      userId: 'owner',
      actorId: 'actor',
      actorName: 'Sumit Menaria',
      type: type,
      text: text,
      link: '/book?id=book1',
      targetId: 'book1',
      timestamp: 1,
      isRead: false,
      metadata: const {'bookId': 'book1', 'commentId': 'comment1'},
    );
  }

  Future<AppLocalizations> loadL10n(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return l10n;
  }

  test('notification service emits FCM notification ids', () async {
    final events = <String>[];
    final sub = NotificationService.instance.notificationEvents.listen(
      events.add,
    );

    NotificationService.instance.debugEmitNotificationEvent('review_doc_1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(events, contains('review_doc_1'));
  });

  testWidgets('canonical book review notification text is shown in full', (
    tester,
  ) async {
    final l10n = await loadL10n(tester);
    const text =
        'Sumit Menaria has left a review on chapter "मन की बात" of article "मन की बात".';

    expect(
      localizedNotificationText(
        notification(type: 'book_review', text: text),
        l10n,
      ),
      text,
    );
  });

  testWidgets('legacy review notification text still localizes safely', (
    tester,
  ) async {
    final l10n = await loadL10n(tester);

    expect(
      localizedNotificationText(
        notification(
          type: 'book_review',
          text: 'left a review on your content',
        ),
        l10n,
      ),
      l10n.reviewedYourBook,
    );
  });

  testWidgets('book notification actions localize in Hindi', (tester) async {
    final l10n = await loadL10n(tester, locale: const Locale('hi'));

    expect(
      localizedNotificationText(
        notification(
          type: 'book_comment',
          text: 'Sumit Menaria has commented on article "Title".',
        ),
        l10n,
      ),
      l10n.commentedOnYourContent,
    );
    expect(
      localizedNotificationText(
        notification(
          type: 'book_reply',
          text: 'Sumit Menaria has replied to your review on "Title".',
        ),
        l10n,
      ),
      l10n.repliedToYourBookComment,
    );
  });

  test(
    'notification event provider is wired to refresh notification lists',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final providerSource = File(
        'lib/src/presentation/providers/notification_providers.dart',
      ).readAsStringSync();

      expect(providerSource, contains('final notificationEventProvider'));
      expect(mainSource, contains('ref.listen(notificationEventProvider'));
      expect(mainSource, contains('ref.invalidate(notificationsProvider)'));
      expect(
        mainSource,
        contains('ref.invalidate(pagedNotificationsProvider)'),
      );
    },
  );

  test('review notifications are not included in message grouping', () {
    final source = File(
      'lib/src/presentation/screens/notifications_screen.dart',
    ).readAsStringSync();

    final messageMatcher = RegExp(
      r"bool _isMessageNotification[\s\S]*?text\.contains\(\s*'message'\s*\);",
    );
    final match = messageMatcher.firstMatch(source);
    expect(match, isNotNull);
    expect(match!.group(0), isNot(contains('book_review')));
    expect(match.group(0), isNot(contains('review')));
  });

  test('content comment duplicates are hidden when a review exists', () {
    final source = File(
      'lib/src/presentation/screens/notifications_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_dedupeSupersededContentNotifications'));
    expect(
      source,
      contains("notification.type.toLowerCase() == 'book_review'"),
    );
    expect(source, contains("type != 'book_comment' && type != 'comment'"));
    expect(source, contains('_contentCommentKey'));
  });
}
