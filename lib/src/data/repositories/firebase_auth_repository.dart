import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/analytics_service.dart';
import '../utils/firestore_utils.dart';

class FirebaseAuthRepository implements AuthRepository {
  firebase.FirebaseAuth get _auth => firebase.FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseFunctions get _functions => FirebaseFunctions.instance;
  static const int _maxFanOutWritesPerBatch = 450;
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

      await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .set(userModel.toJson());

      AnalyticsService.logSignUp(method: 'email');
      return userModel;
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
        final raw = userDoc.data()!;
        final hadNotificationSettings = raw['notificationSettings'] != null;
        final patch = <String, dynamic>{
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        };
        if (!hadNotificationSettings) {
          patch['notificationSettings'] = defaultNotificationSettingsMap();
        }
        try {
          await _firestore
              .collection('users')
              .doc(fbUser.uid)
              .update(patch)
              .timeout(_profileWriteTimeout);
        } catch (e) {
          debugPrint('Signed in, but user profile update failed: $e');
        }

        final data = normalizeUserMapForModel({
          ...raw,
          ...patch,
          'id': fbUser.uid,
        }, fbUser.uid);
        AnalyticsService.logLogin(method: 'email');
        return UserModel.fromJson(data);
      } else {
        // Handle legacy or missing doc
        await _setUserProfileIfPossible(fallbackUser);
        AnalyticsService.logLogin(method: 'email');
        return fallbackUser;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      return await _handleGoogleSignInResult(googleUser);
    } on GoogleSignInException {
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
        final raw = userDoc.data()!;
        final hadNotificationSettings = raw['notificationSettings'] != null;
        final patch = <String, dynamic>{
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        };
        if (!hadNotificationSettings) {
          patch['notificationSettings'] = defaultNotificationSettingsMap();
        }
        try {
          await _firestore
              .collection('users')
              .doc(fbUser.uid)
              .update(patch)
              .timeout(_profileWriteTimeout);
        } catch (e) {
          debugPrint('Signed in with Google, but profile update failed: $e');
        }

        final data = normalizeUserMapForModel({
          ...raw,
          ...patch,
          'id': fbUser.uid,
        }, fbUser.uid);
        AnalyticsService.logLogin(method: 'google');
        return UserModel.fromJson(data);
      } else {
        await _setUserProfileIfPossible(fallbackUser);

        AnalyticsService.logSignUp(method: 'google');
        return fallbackUser;
      }
    } catch (e) {
      throw Exception(e.toString());
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
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(_profileWriteTimeout);
      if (doc.exists) {
        final data = normalizeUserMapForModel(doc.data()!, doc.id);
        return UserModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('User profile load failed: $e');
    }

    final fallbackUser = _fallbackCurrentUserModel(userId);
    if (fallbackUser != null) {
      unawaited(_setUserProfileIfPossible(fallbackUser));
    }
    return fallbackUser;
  }

  UserModel _userModelFromFirebaseUser(firebase.User fbUser, {String? email}) {
    return UserModel(
      id: fbUser.uid,
      username: fbUser.displayName ?? 'Reader',
      email: fbUser.email ?? email ?? '',
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

  Future<void> _setUserProfileIfPossible(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson())
          .timeout(_profileWriteTimeout);
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
    try {
      await for (final doc
          in _firestore.collection('users').doc(userId).snapshots()) {
        if (doc.exists) {
          final data = normalizeUserMapForModel(doc.data()!, doc.id);
          yield UserModel.fromJson(data);
          continue;
        }
        final fallbackUser = _fallbackCurrentUserModel(userId);
        if (fallbackUser != null) {
          unawaited(_setUserProfileIfPossible(fallbackUser));
        }
        yield fallbackUser;
      }
    } catch (e) {
      debugPrint('User profile watch failed: $e');
      final fallbackUser = _fallbackCurrentUserModel(userId);
      if (fallbackUser != null) {
        unawaited(_setUserProfileIfPossible(fallbackUser));
      }
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

    await _firestore.collection('users').doc(userId).update(updates);
    await _fanOutProfileUpdates(userId, updates);
  }

  Future<void> _fanOutProfileUpdates(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    final feedUpdates = <String, dynamic>{};
    final commentUpdates = <String, dynamic>{};
    final notificationUpdates = <String, dynamic>{};
    final conversationUpdates = <String, dynamic>{};
    if (updates.containsKey('displayName')) {
      feedUpdates['displayName'] = updates['displayName'];
      commentUpdates['userName'] = updates['displayName'];
      notificationUpdates['actorName'] = updates['displayName'];
      conversationUpdates['participantDetails.$userId.displayName'] =
          updates['displayName'];
    }
    if (updates.containsKey('photoURL')) {
      feedUpdates['userPhotoURL'] = updates['photoURL'];
      commentUpdates['userPhotoURL'] = updates['photoURL'];
      notificationUpdates['actorPhotoURL'] = updates['photoURL'];
      conversationUpdates['participantDetails.$userId.photoURL'] =
          updates['photoURL'];
    }
    if (feedUpdates.isEmpty && commentUpdates.isEmpty) return;

    final batches = <WriteBatch>[];
    var currentWriteCount = 0;

    WriteBatch activeBatch() {
      if (batches.isEmpty || currentWriteCount >= _maxFanOutWritesPerBatch) {
        batches.add(_firestore.batch());
        currentWriteCount = 0;
      }
      return batches.last;
    }

    void queueUpdate(
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data,
    ) {
      if (data.isEmpty) return;
      if (currentWriteCount >= _maxFanOutWritesPerBatch) {
        batches.add(_firestore.batch());
        currentWriteCount = 0;
      }
      activeBatch().update(ref, data);
      currentWriteCount++;
    }

    Future<void> queueQuery(
      Query<Map<String, dynamic>> query,
      Map<String, dynamic> data,
    ) async {
      if (data.isEmpty) return;
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        queueUpdate(doc.reference, data);
      }
    }

    await queueQuery(
      _firestore.collection('feed_posts').where('userId', isEqualTo: userId),
      feedUpdates,
    );
    await queueQuery(
      _firestore.collection('comments').where('userId', isEqualTo: userId),
      commentUpdates,
    );
    await queueQuery(
      _firestore
          .collection('notifications')
          .where('actorId', isEqualTo: userId),
      notificationUpdates,
    );
    await queueQuery(
      _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId),
      conversationUpdates,
    );

    for (final batch in batches) {
      await batch.commit();
    }
  }

  @override
  Future<void> updateUserSavedBooks(
    String userId,
    List<dynamic> savedBooks,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'savedBooks': savedBooks,
    });
  }

  @override
  Future<void> updateUserReadingHistory(
    String userId,
    List<dynamic> readingHistory,
  ) async {
    await _firestore.collection('users').doc(userId).update({
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
