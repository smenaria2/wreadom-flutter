class EnvConfig {
  static const String firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyCkiPyC3xawvqek2ZUJPhLIupLKwRwW4t0',
  );

  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyDsm9w_Hkac6sXgBqweqSU_wYjfp4i19dM',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyDZ-K5JtaISPaJ2dmcSRLlTwOZDylhM4Kc',
  );

  static const String firebaseWindowsApiKey = String.fromEnvironment(
    'FIREBASE_WINDOWS_API_KEY',
    defaultValue: 'AIzaSyDOgMpxNGS3sJ6Rnoh2m1l_kwjQPSOu_aw',
  );

  // Add other sensitive values here if needed
}
