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

      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      expect(repository.savedPrivacyLevel, 'private');
    },
  );
}

class _FakeProfileRepository implements ProfileRepository {
  String? savedPrivacyLevel;

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
}
