import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:librebook_flutter/src/domain/models/user_model.dart';
import 'package:librebook_flutter/src/domain/repositories/profile_repository.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/profile_providers.dart';
import 'package:librebook_flutter/src/presentation/screens/profile_settings_screen.dart';

void main() {
  testWidgets(
    'profile privacy selection survives rebuild and saves new value',
    (tester) async {
      final repository = _FakeProfileRepository();
      final user = UserModel(
        id: 'user-1',
        username: 'reader',
        email: 'reader@example.com',
        displayName: 'Reader',
        privacyLevel: 'public',
        readingHistory: const [],
        savedBooks: const [],
        bookmarks: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => Stream.value(user)),
            profileRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Public'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private').last);
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsOneWidget);

      await tester.pump();
      expect(find.text('Private'), findsOneWidget);

      await _tapSaveSettings(tester);
      await tester.pumpAndSettle();

      expect(repository.savedPrivacyLevel, 'private');
    },
  );

  testWidgets(
    'notification category toggle saves app preference and preserves browser values',
    (tester) async {
      final repository = _FakeProfileRepository();
      final user = _testUser(
        notificationSettings: _notificationSettings(
          comments: const NotificationPreference(app: true, browser: true),
          browserNotifications: true,
        ),
      );

      await _pumpProfileSettings(tester, repository, user);

      await _scrollUntilTextVisible(tester, 'Comments and reviews');
      await tester.tap(
        find
            .ancestor(
              of: find.text('Comments and reviews'),
              matching: find.byType(ListTile),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await _tapSaveSettings(tester);
      await tester.pumpAndSettle();

      final saved = repository.savedNotificationSettings;
      expect(saved, isNotNull);
      expect(saved!.comments.app, isFalse);
      expect(saved.comments.browser, isTrue);
      expect(saved.browserNotifications, isTrue);
    },
  );

  testWidgets('legacy users render default notification controls', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    final user = _testUser();

    await _pumpProfileSettings(tester, repository, user);

    expect(find.text('Notification preferences'), findsOneWidget);
    expect(find.text('Direct messages'), findsOneWidget);
    await _scrollUntilTextVisible(tester, 'New creations and chapters');
    expect(find.text('New creations and chapters'), findsOneWidget);

    await _tapSaveSettings(tester);
    await tester.pumpAndSettle();

    final saved = repository.savedNotificationSettings;
    expect(saved, isNotNull);
    expect(saved!.messages.app, isTrue);
    expect(saved.messages.browser, isFalse);
    expect(saved.browserNotifications, isFalse);
  });
}

Future<void> _tapSaveSettings(WidgetTester tester) async {
  await _scrollUntilTextVisible(tester, 'Save Settings');
  await tester.pumpAndSettle();
  final saveButton = find.text('Save Settings');
  await tester.tap(saveButton);
}

Future<void> _scrollUntilTextVisible(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _FakeProfileRepository implements ProfileRepository {
  String? savedPrivacyLevel;
  NotificationSettings? savedNotificationSettings;

  @override
  Future<void> updateProfileDetails({
    required String userId,
    String? bio,
    String? penName,
    String? displayName,
  }) async {}

  @override
  Future<void> updatePrivacyLevel(String userId, String privacyLevel) async {
    savedPrivacyLevel = privacyLevel;
  }

  @override
  Future<void> deactivateProfile(String userId) async {}

  @override
  Future<UserModel?> getPublicProfile(
    String userId, {
    String? viewerUserId,
  }) async {
    return null;
  }

  @override
  Future<List<UserModel>> getPublicProfilesByIds(
    List<String> userIds, {
    String? viewerUserId,
  }) async {
    return const [];
  }

  @override
  Future<void> reactivateProfile(String userId) async {}

  @override
  Future<List<UserModel>> searchProfiles(String query, {int limit = 10}) async {
    return const [];
  }

  @override
  Future<void> updateCoverPhoto(String userId, String? coverPhotoURL) async {}

  @override
  Future<void> updateNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    savedNotificationSettings = settings;
  }
}

Future<void> _pumpProfileSettings(
  WidgetTester tester,
  _FakeProfileRepository repository,
  UserModel user,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(user)),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileSettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

UserModel _testUser({NotificationSettings? notificationSettings}) {
  return UserModel(
    id: 'user-1',
    username: 'reader',
    email: 'reader@example.com',
    displayName: 'Reader',
    privacyLevel: 'public',
    readingHistory: const [],
    savedBooks: const [],
    bookmarks: const [],
    notificationSettings: notificationSettings,
  );
}

NotificationSettings _notificationSettings({
  NotificationPreference messages = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference groupMessages = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference comments = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference replies = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference followers = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference testimonials = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference likes = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference followedAuthorPosts = const NotificationPreference(
    app: true,
    browser: false,
  ),
  NotificationPreference newCreations = const NotificationPreference(
    app: true,
    browser: false,
  ),
  bool browserNotifications = false,
}) {
  return NotificationSettings(
    messages: messages,
    groupMessages: groupMessages,
    comments: comments,
    replies: replies,
    followers: followers,
    testimonials: testimonials,
    likes: likes,
    followedAuthorPosts: followedAuthorPosts,
    newCreations: newCreations,
    browserNotifications: browserNotifications,
  );
}
