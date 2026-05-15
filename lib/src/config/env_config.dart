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

  // Add other sensitive values here only as dart-define keys, not defaults.
}
