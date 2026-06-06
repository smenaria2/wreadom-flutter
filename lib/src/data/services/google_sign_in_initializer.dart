import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInInitializer {
  GoogleSignInInitializer._();

  static const String serverClientId =
      '601247128838-qp60rioakq1s65j51e5t2utq4n9gmoad.apps.googleusercontent.com';

  static Future<void>? _initializeFuture;

  static Future<void> ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  static Future<void> _initialize() {
    if (kIsWeb) {
      return GoogleSignIn.instance.initialize(clientId: serverClientId);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    }
    return GoogleSignIn.instance.initialize();
  }
}
