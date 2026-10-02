import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        defaultTargetPlatform,
        kIsWeb,
        debugPrint,
        visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/analytics_service.dart';
import '../services/google_sign_in_initializer.dart';
import '../utils/firestore_utils.dart';
import '../utils/profile_search_utils.dart';
import '../services/user_private_account_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseFirestore? firestore})
    : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  firebase.FirebaseAuth get _auth => firebase.FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;
  UserPrivateAccountService get _privateAccountService =>
      UserPrivateAccountService(firestore: _firestore);
  static const Duration _profileWriteTimeout = Duration(seconds: 8);

  @override
  Stream<firebase.User?> get authStateChanges => _auth.authStateChanges();

  final NotificationSettings _defaultNotificationSettings =
      const NotificationSettings(
        messages: NotificationPreference(app: true, browser: false),
        groupMessages: NotificationPreference(app: true, browser: false),
        comments: NotificationPreference(app: true, browser: false),
        replies: NotificationPreference(app: true, browser: false),
        followers: NotificationPreference(app: true, browser: false),
        testimonials: NotificationPreference(app: true, browser: false),
        likes: NotificationPreference(app: true, browser: false),
        followedAuthorPosts: NotificationPreference(app: true, browser: false),
        newCreations: NotificationPreference(app: true, browser: false),
        dailyTopics: NotificationPreference(app: true, browser: false),
        recommendedContent: NotificationPreference(app: true, browser: false),
        browserNotifications: false,
      );

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;

      // Update display name
      await fbUser.updateDisplayName(username);
      await fbUser.reload();

      // Send verification email
      try {
        await fbUser.sendEmailVerification();
      } catch (e) {
        debugPrint('Failed to send email verification: $e');
      }

      final userModel = UserModel(
        id: fbUser.uid,
        username: username,
        email: email,
        privacyLevel: 'public',
        readingHistory: [],
        savedBooks: [],
        bookmarks: [],
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastLogin: DateTime.now().millisecondsSinceEpoch,
        notificationSettings: _defaultNotificationSettings,
      );

      final json = userModel.toJson();
      json.remove('email');
      json.remove('readingHistory');
      json.remove('savedBooks');
      json.remove('bookmarks');
      json.remove('notificationSettings');
      json.remove('readingProgress');
      json.remove('fcmTokens');

      json['searchTerms'] = buildProfileSearchTerms(
        username: userModel.username,
        email: '',
        displayName: userModel.displayName,
        penName: userModel.penName,
      );

      await _firestore.collection('users').doc(fbUser.uid).set(json);

      await _privateAccountService.setPrivateAccount(fbUser.uid, {
        'email': email,
        'readingHistory': [],
        'savedBooks': [],
        'bookmarks': [],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
        'notificationSettings': _notificationSettingsToMap(
          _defaultNotificationSettings,
        ),
      });

      AnalyticsService.logSignUp(method: 'email');
      return userModel;
    } on firebase.FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;

      final fallbackUser = _userModelFromFirebaseUser(fbUser, email: email);
      DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(fbUser.uid)
            .get()
            .timeout(_profileWriteTimeout);
      } catch (e) {
        debugPrint('Signed in, but user profile load failed: $e');
        AnalyticsService.logLogin(method: 'email');
        return fallbackUser;
      }

      if (userDoc.exists) {
        final user = await completeSignIn(
          uid: fbUser.uid,
          displayName: fbUser.displayName,
          authEmail: fbUser.email,
          raw: userDoc.data()!,
          fallbackUser: fallbackUser,
          fallbackEmail: email,
        );
        AnalyticsService.logLogin(method: 'email');
        return user;
      } else {
        // Handle legacy or missing doc
        await _setUserProfileIfPossible(fallbackUser);
        AnalyticsService.logLogin(method: 'email');
        return fallbackUser;
      }
    } on firebase.FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = firebase.GoogleAuthProvider();
        final result = await _auth.signInWithPopup(googleProvider);
        final fbUser = result.user;
        if (fbUser == null) {
          throw Exception('Google Sign-In failed: User is null.');
        }
        return await _processGoogleUser(fbUser);
      }

      await GoogleSignInInitializer.ensureInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      return await _handleGoogleSignInResult(googleUser);
    } on GoogleSignInException {
      rethrow;
    } on firebase.FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> _handleGoogleSignInResult(
    GoogleSignInAccount googleUser,
  ) async {
    try {
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        debugPrint(
          'Google Sign-In Error: idToken is null. Check Firebase SHA-1 configuration.',
        );
        throw Exception(
          'Google Sign-In did not return an ID token. For Android, add your '
          'debug/release SHA-1 in Firebase Console for this package, download '
          'an updated google-services.json (it must include an Android OAuth '
          'client, not only the Web client), and ensure GoogleSignIn.initialize '
          'uses your Web client ID as serverClientId.',
        );
      }

      return signInWithGoogleIdToken(idToken);
    } on GoogleSignInException {
      rethrow;
    } on firebase.FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogleIdToken(String idToken) async {
    try {
      final firebase.AuthCredential credential =
          firebase.GoogleAuthProvider.credential(idToken: idToken);

      final result = await _auth.signInWithCredential(credential);
      final fbUser = result.user!;

      return await _processGoogleUser(fbUser);
    } on firebase.FirebaseAuthException {
      rethrow;
    } on FirebaseException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Finishes a sign-in for a user whose public profile already exists.
  ///
  /// Only public fields are healed on users/{id}. Email, reading data,
  /// bookmarks and notification settings live in users/{id}/private/account and
  /// are seeded there (from any legacy root values) when that document is
  /// missing. Nothing private is ever written back to the public document.
  @visibleForTesting
  Future<UserModel> completeSignIn({
    required String uid,
    String? displayName,
    String? authEmail,
    required Map<String, dynamic> raw,
    required UserModel fallbackUser,
    String? fallbackEmail,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final needsHeal = raw['username'] == null;
    final patch = <String, dynamic>{'lastLogin': now};
    if (needsHeal) {
      patch['username'] =
          raw['username'] ?? displayName ?? fallbackUser.username;
      patch['createdAt'] = raw['createdAt'] ?? now;
      patch['privacyLevel'] = raw['privacyLevel'] ?? 'public';
    }
    if (raw['searchTerms'] is! List || needsHeal) {
      patch['searchTerms'] = buildProfileSearchTerms(
        username:
            patch['username']?.toString() ??
            raw['username']?.toString() ??
            fallbackUser.username,
        email: '',
        displayName: raw['displayName']?.toString() ?? displayName,
        penName: raw['penName']?.toString(),
      );
    }
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update(patch)
          .timeout(_profileWriteTimeout);
    } catch (e) {
      debugPrint('Signed in, but user profile update failed: $e');
    }

    var privateData = await _privateAccountService.getPrivateAccount(uid);
    if (privateData == null) {
      privateData = {
        'email':
            raw['email'] ?? authEmail ?? fallbackEmail ?? fallbackUser.email,
        'readingHistory': raw['readingHistory'] ?? [],
        'savedBooks': raw['savedBooks'] ?? [],
        'bookmarks': raw['bookmarks'] ?? [],
        'notificationSettings':
            raw['notificationSettings'] ?? defaultNotificationSettingsMap(),
        'readingProgress': raw['readingProgress'] ?? {},
        'fcmTokens': raw['fcmTokens'] ?? [],
        'lastLogin': now,
      };
      await _privateAccountService.setPrivateAccount(uid, privateData);
    } else {
      final update = <String, dynamic>{'lastLogin': now};
      if (privateData['notificationSettings'] == null) {
        update['notificationSettings'] = defaultNotificationSettingsMap();
      }
      await _privateAccountService.updatePrivateAccount(uid, update);
      privateData = {...privateData, ...update};
    }

    final merged = UserPrivateAccountService.mergeUserWithPrivate({
      ...raw,
      ...patch,
      'id': uid,
    }, privateData);
    return UserModel.fromJson(normalizeUserMapForModel(merged, uid));
  }

  Future<UserModel> _processGoogleUser(firebase.User fbUser) async {
    final fallbackUser = _userModelFromFirebaseUser(fbUser);
    DocumentSnapshot<Map<String, dynamic>> userDoc;
    try {
      userDoc = await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .get()
          .timeout(_profileWriteTimeout);
    } catch (e) {
      debugPrint('Signed in with Google, but user profile load failed: $e');
      AnalyticsService.logLogin(method: 'google');
      return fallbackUser;
    }

    if (userDoc.exists) {
      final user = await completeSignIn(
        uid: fbUser.uid,
        displayName: fbUser.displayName,
        authEmail: fbUser.email,
        raw: userDoc.data()!,
        fallbackUser: fallbackUser,
      );
      AnalyticsService.logLogin(method: 'google');
      return user;
    } else {
      await _setUserProfileIfPossible(fallbackUser);

      AnalyticsService.logSignUp(method: 'google');
      return fallbackUser;
    }
  }

  @override
  Future<void> logout() async {
    final currentUser = _auth.currentUser;
    final userId = currentUser?.uid;
    if (userId != null) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          await removeFcmToken(userId, token);
        }
      } catch (e) {
        debugPrint('Failed to remove FCM token during logout: $e');
      }
    }
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    try {
      final isSelf = _auth.currentUser?.uid == userId;
      final docFuture = _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(_profileWriteTimeout);
      final privateFuture = isSelf
          ? _privateAccountService.getPrivateAccount(userId)
          : Future<Map<String, dynamic>?>.value(null);

      final results = await Future.wait([docFuture, privateFuture]);
      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final privateData = results[1] as Map<String, dynamic>?;

      if (doc.exists && doc.data() != null) {
        var raw = doc.data()!;
        if (isSelf) {
          raw = UserPrivateAccountService.mergeUserWithPrivate(
            raw,
            privateData,
          );
        }
        final data = normalizeUserMapForModel(raw, doc.id);
        return UserModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('User profile load failed: $e');
    }

    final fallbackUser = _fallbackCurrentUserModel(userId);
    return fallbackUser;
  }

  UserModel _userModelFromFirebaseUser(firebase.User fbUser, {String? email}) {
    final emailVal = fbUser.email ?? email;
    final fallbackUsername = emailVal != null && emailVal.contains('@')
        ? emailVal.split('@').first
        : 'Reader';
    return UserModel(
      id: fbUser.uid,
      username: fbUser.displayName ?? fallbackUsername,
      email: emailVal ?? '',
      displayName: fbUser.displayName,
      photoURL: fbUser.photoURL,
      privacyLevel: 'public',
      readingHistory: [],
      savedBooks: [],
      bookmarks: [],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastLogin: DateTime.now().millisecondsSinceEpoch,
      notificationSettings: _defaultNotificationSettings,
    );
  }

  Map<String, dynamic> _notificationSettingsToMap(
    NotificationSettings settings,
  ) {
    Map<String, bool> preference(NotificationPreference value) => {
      'app': value.app,
      'browser': value.browser,
    };

    return {
      'messages': preference(settings.messages),
      'groupMessages': preference(settings.groupMessages),
      'comments': preference(settings.comments),
      'replies': preference(settings.replies),
      'followers': preference(settings.followers),
      'testimonials': preference(settings.testimonials),
      'likes': preference(settings.likes),
      'followedAuthorPosts': preference(settings.followedAuthorPosts),
      'newCreations': preference(settings.newCreations),
      'dailyTopics': preference(settings.dailyTopics),
      'recommendedContent': preference(settings.recommendedContent),
      'browserNotifications': settings.browserNotifications,
    };
  }

  Future<void> _setUserProfileIfPossible(UserModel userModel) async {
    try {
      final json = userModel.toJson();
      json.remove('email');
      json.remove('readingHistory');
      json.remove('savedBooks');
      json.remove('bookmarks');
      json.remove('notificationSettings');
      json.remove('readingProgress');
      json.remove('fcmTokens');

      json['searchTerms'] = buildProfileSearchTerms(
        username: userModel.username,
        email: '',
        displayName: userModel.displayName,
        penName: userModel.penName,
      );
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(json)
          .timeout(_profileWriteTimeout);

      await _privateAccountService.setPrivateAccount(userModel.id, {
        'email': userModel.email,
        'readingHistory': userModel.readingHistory,
        'savedBooks': userModel.savedBooks,
        'bookmarks': userModel.bookmarks,
        'createdAt':
            userModel.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
        if (userModel.notificationSettings != null)
          'notificationSettings': _notificationSettingsToMap(
            userModel.notificationSettings!,
          ),
      });
    } catch (e) {
      debugPrint('Signed in, but user profile creation failed: $e');
    }
  }

  UserModel? _fallbackCurrentUserModel(String userId) {
    final fbUser = _auth.currentUser;
    if (fbUser == null || fbUser.uid != userId) return null;
    return _userModelFromFirebaseUser(fbUser);
  }

  @override
  Stream<UserModel?> watchUser(String userId) async* {
    final isSelf = _auth.currentUser?.uid == userId;
    try {
      Map<String, dynamic>? privateData;
      if (isSelf) {
        privateData = await _privateAccountService.getPrivateAccount(userId);
      }

      await for (final doc
          in _firestore.collection('users').doc(userId).snapshots()) {
        if (doc.exists && doc.data() != null) {
          var raw = doc.data()!;
          if (isSelf) {
            raw = UserPrivateAccountService.mergeUserWithPrivate(
              raw,
              privateData,
            );
          }
          final data = normalizeUserMapForModel(raw, doc.id);
          yield UserModel.fromJson(data);
          continue;
        }
        final fallbackUser = _fallbackCurrentUserModel(userId);
        yield fallbackUser;
      }
    } catch (e) {
      debugPrint('User profile watch failed: $e');
      final fallbackUser = _fallbackCurrentUserModel(userId);
      yield fallbackUser;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final curUser = _auth.currentUser;
    if (curUser == null) return null;
    return getUser(curUser.uid);
  }

  @override
  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? photoURL,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoURL != null) updates['photoURL'] = photoURL;

    if (updates.isEmpty) return;

    if (displayName != null) {
      final current = await _firestore.collection('users').doc(userId).get();
      final data = current.data() ?? const <String, dynamic>{};
      updates['searchTerms'] = buildProfileSearchTerms(
        username: data['username']?.toString() ?? '',
        email: '',
        displayName: displayName,
        penName: data['penName']?.toString(),
      );
    }
    await _firestore.collection('users').doc(userId).update(updates);
  }

  @override
  Future<void> updateUserSavedBooks(
    String userId,
    List<dynamic> savedBooks,
  ) async {
    await _privateAccountService.updatePrivateAccount(userId, {
      'savedBooks': savedBooks,
    });
  }

  @override
  Future<void> updateUserReadingHistory(
    String userId,
    List<dynamic> readingHistory,
  ) async {
    await _privateAccountService.updatePrivateAccount(userId, {
      'readingHistory': readingHistory,
    });
  }

  @override
  Future<void> updateFcmToken(String userId, String token) async {
    await claimFcmToken(userId, token);
  }

  @override
  Future<void> claimFcmToken(String userId, String token) async {
    final trimmedToken = token.trim();
    if (userId.trim().isEmpty || trimmedToken.isEmpty) return;
    try {
      await _functions.httpsCallable('claimFcmToken').call({
        'token': trimmedToken,
        'platform': _fcmPlatformLabel(),
      });
    } catch (e) {
      debugPrint('claimFcmToken callable failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFcmToken(String userId, String token) async {
    final trimmedToken = token.trim();
    if (userId.trim().isEmpty || trimmedToken.isEmpty) return;
    try {
      await _functions.httpsCallable('removeFcmToken').call({
        'token': trimmedToken,
      });
    } catch (e) {
      debugPrint('removeFcmToken callable failed: $e');
      rethrow;
    }
  }

  String _fcmPlatformLabel() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  @override
  Future<List<UserModel>> searchUsers(
    String searchTerm, {
    int maxResults = 5,
  }) async {
    if (searchTerm.isEmpty) return [];

    final term = searchTerm.toLowerCase();

    // Simple direct match for now, or prefix match
    final query = _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: term)
        .where('username', isLessThanOrEqualTo: '$term\uf8ff')
        .limit(maxResults);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = normalizeUserMapForModel(doc.data(), doc.id);
      return UserModel.fromJson(data);
    }).toList();
  }
}
