import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../utils/firestore_utils.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _maxFanOutWritesPerBatch = 450;

  FirebaseAuthRepository() {
    // Web-only: GIS renderButton delivers sign-in via authenticationEvents.
    // On Android/iOS, signInWithGoogle() already calls authenticate(); a second
    // listener causes duplicate/racy signInWithCredential calls and can leave
    // Firebase unsigned-in while the account picker has already completed.
    if (kIsWeb) {
      GoogleSignIn.instance.authenticationEvents.listen((
        GoogleSignInAuthenticationEvent event,
      ) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          if (_auth.currentUser == null) {
            try {
              await _handleGoogleSignInResult(event.user);
            } catch (e) {
              debugPrint('Auto Firebase sign-in from Google failed: $e');
            }
          }
        }
      });
    }
  }

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

      final userDoc = await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .get();

      if (userDoc.exists) {
        final raw = userDoc.data()!;
        final hadNotificationSettings = raw['notificationSettings'] != null;
        final patch = <String, dynamic>{
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        };
        if (!hadNotificationSettings) {
          patch['notificationSettings'] = defaultNotificationSettingsMap();
        }
        await _firestore.collection('users').doc(fbUser.uid).update(patch);

        final data = normalizeUserMapForModel({
          ...raw,
          ...patch,
          'id': fbUser.uid,
        }, fbUser.uid);
        return UserModel.fromJson(data);
      } else {
        // Handle legacy or missing doc
        final userModel = UserModel(
          id: fbUser.uid,
          username: fbUser.displayName ?? 'Reader',
          email: fbUser.email ?? email,
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
        return userModel;
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

      final firebase.AuthCredential credential =
          firebase.GoogleAuthProvider.credential(idToken: idToken);

      final result = await _auth.signInWithCredential(credential);
      final fbUser = result.user!;

      final userDoc = await _firestore
          .collection('users')
          .doc(fbUser.uid)
          .get();

      if (userDoc.exists) {
        final raw = userDoc.data()!;
        final hadNotificationSettings = raw['notificationSettings'] != null;
        final patch = <String, dynamic>{
          'lastLogin': DateTime.now().millisecondsSinceEpoch,
        };
        if (!hadNotificationSettings) {
          patch['notificationSettings'] = defaultNotificationSettingsMap();
        }
        await _firestore.collection('users').doc(fbUser.uid).update(patch);

        final data = normalizeUserMapForModel({
          ...raw,
          ...patch,
          'id': fbUser.uid,
        }, fbUser.uid);
        return UserModel.fromJson(data);
      } else {
        final userModel = UserModel(
          id: fbUser.uid,
          username: fbUser.displayName ?? 'Reader',
          email: fbUser.email ?? '',
          photoURL: fbUser.photoURL,
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

        return userModel;
      }
    } on GoogleSignInException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final data = normalizeUserMapForModel(doc.data()!, doc.id);
    return UserModel.fromJson(data);
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
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final registryRaw = data['fcmTokenRegistry'];
      final registry = registryRaw is List
          ? registryRaw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .where((item) => item['token']?.toString() != token)
                .toList()
          : <Map<String, dynamic>>[];
      registry.insert(0, {
        'token': token,
        'platform': _fcmPlatformLabel(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      transaction.set(userRef, {
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenRegistry': registry.take(10).toList(),
      }, SetOptions(merge: true));
    });
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
