class EnvConfig {
  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: '',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: '',
  );

  static const String firebaseWindowsApiKey = String.fromEnvironment(
    'FIREBASE_WINDOWS_API_KEY',
    defaultValue: '',
  );

  static const bool useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  static const String firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static const int firebaseFirestoreEmulatorPort = int.fromEnvironment(
    'FIREBASE_FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );

  static const int firebaseAuthEmulatorPort = int.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );

  static const int firebaseFunctionsEmulatorPort = int.fromEnvironment(
    'FIREBASE_FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );

  static const bool enableAppCheckWebDebug = bool.fromEnvironment(
    'ENABLE_APPCHECK_WEB_DEBUG',
    defaultValue: false,
  );

  static const bool enableAppCheck = bool.fromEnvironment(
    'ENABLE_APPCHECK',
    defaultValue: true,
  );

  static const String unsplashAccessKey = String.fromEnvironment(
    'UNSPLASH_ACCESS_KEY',
    defaultValue: '',
  );

  static const String testUserEmail = String.fromEnvironment(
    'TEST_USER_EMAIL',
    defaultValue: '',
  );

  static const String testUserPassword = String.fromEnvironment(
    'TEST_USER_PASSWORD',
    defaultValue: '',
  );

  // Add other sensitive values here only as dart-define keys, not defaults.
}
