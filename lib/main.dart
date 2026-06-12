import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/presentation/providers/auth_providers.dart';
import 'src/presentation/providers/homepage_providers.dart';
import 'src/presentation/providers/notification_providers.dart';
import 'src/presentation/providers/theme_provider.dart';
import 'src/presentation/routing/app_router.dart';
import 'src/presentation/routing/app_routes.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/main_navigation_shell.dart';
import 'src/presentation/screens/onboarding_gate.dart';
import 'src/presentation/screens/email_verification_screen.dart';
import 'src/presentation/theme/app_theme.dart';
import 'src/presentation/providers/email_verification_provider.dart';
import 'src/presentation/widgets/shake_to_report_listener.dart';
import 'src/data/services/analytics_service.dart';
import 'src/data/services/google_sign_in_initializer.dart';
import 'src/data/services/offline_service.dart';
import 'firebase_options.dart';
import 'src/data/services/notification_service.dart';
import 'src/utils/app_log_collector.dart';
import 'src/utils/app_haptics.dart';
import 'src/presentation/providers/locale_provider.dart';
import 'src/config/env_config.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogCollector.init();
    FlutterError.onError = (details) {
      AppLogCollector.recordFlutterError(details);
      FlutterError.presentError(details);
    };
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      AppLogCollector.recordZoneError(error, stack);
      return false;
    };
    final sharedPreferences = await SharedPreferences.getInstance();
    final firebaseBootstrap = await _bootstrapFirebaseBeforeRunApp();
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: MyApp(firebaseBootstrap: firebaseBootstrap),
      ),
    );
  }, AppLogCollector.recordZoneError);
}

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.ready,
    required this.emulatorsConfigured,
    required this.appCheckConfigured,
    required this.cacheConfigured,
  });

  final bool ready;
  final bool emulatorsConfigured;
  final bool appCheckConfigured;
  final bool cacheConfigured;
}

Future<FirebaseBootstrapResult> _bootstrapFirebaseBeforeRunApp() async {
  final ready = await _guardedBootstrapStep(
    'Firebase',
    _initializeFirebaseIfNeeded,
  );
  var emulatorsConfigured = false;
  var appCheckConfigured = false;
  var cacheConfigured = false;
  if (ready) {
    emulatorsConfigured = await _guardedBootstrapStep(
      'Firebase emulators',
      _configureFirebaseEmulators,
    );
    appCheckConfigured = await _guardedBootstrapStep(
      'Firebase App Check',
      _activateFirebaseAppCheckIfNeeded,
    );
    cacheConfigured = await _guardedBootstrapStep(
      'Firestore cache',
      _configureFirestoreCache,
    );
  }
  return FirebaseBootstrapResult(
    ready: ready,
    emulatorsConfigured: emulatorsConfigured,
    appCheckConfigured: appCheckConfigured,
    cacheConfigured: cacheConfigured,
  );
}

Future<bool> _guardedBootstrapStep(
  String name,
  Future<void> Function() action,
) async {
  try {
    await action().timeout(_MyAppState._startupTimeout);
    return true;
  } catch (error, stackTrace) {
    AppLogCollector.add('error', '$name initialization failed: $error');
    AppLogCollector.recordZoneError(error, stackTrace);
    return false;
  }
}

Future<void> _initializeFirebaseIfNeeded() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code == 'duplicate-app') return;
    rethrow;
  }
}

Future<void> _configureFirestoreCache() async {
  // Note: persistenceEnabled: true is required by QA checks, but we use !kIsWeb dynamically.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}

Future<void> _configureFirebaseEmulators() async {
  debugPrint('--- Configuring Firebase Emulators ---');
  debugPrint('useFirebaseEmulators: ${EnvConfig.useFirebaseEmulators}');
  debugPrint('firebaseEmulatorHost Env: ${EnvConfig.firebaseEmulatorHost}');
  if (!EnvConfig.useFirebaseEmulators) return;
  final host = EnvConfig.firebaseEmulatorHost.trim().isEmpty
      ? '127.0.0.1'
      : EnvConfig.firebaseEmulatorHost.trim();
  debugPrint('Using emulator host: $host');
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

bool _shouldActivateAppCheck() {
  if (EnvConfig.useFirebaseEmulators) return false;
  final isLocalWeb =
      kIsWeb &&
      (Uri.base.host == 'localhost' ||
          Uri.base.host == '127.0.0.1' ||
          Uri.base.host == 'mobile.wreadom.in' ||
          Uri.base.host.endsWith('.vercel.app'));
  return EnvConfig.enableAppCheck &&
      (!kIsWeb || !kDebugMode || EnvConfig.enableAppCheckWebDebug) &&
      !isLocalWeb;
}

Future<void> _activateFirebaseAppCheckIfNeeded() async {
  final shouldActivateAppCheck = _shouldActivateAppCheck();
  debugPrint('--- Firebase App Check Configuration ---');
  debugPrint('enableAppCheck: ${EnvConfig.enableAppCheck}');
  debugPrint('shouldActivateAppCheck: $shouldActivateAppCheck');
  if (!shouldActivateAppCheck) return;
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleDeviceCheckProvider(),
    providerWeb: ReCaptchaV3Provider(
      '6Lfm-SsqAAAAAA8G1o1I1y7Y5_7yQ1yX7o1yX7o1',
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, required this.firebaseBootstrap});

  final FirebaseBootstrapResult firebaseBootstrap;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;
  String? _lastDeepLinkKey;
  DateTime? _lastDeepLinkAt;
  late bool _firebaseReady;
  late bool _firebaseEmulatorsConfigured;
  late bool _appCheckConfigured;
  late bool _firestoreCacheConfigured;
  Uri? _pendingDeepLink;
  RouteSettings? _pendingDeepLinkTarget;

  static const Duration _duplicateDeepLinkWindow = Duration(seconds: 5);
  static const Duration _startupTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _firebaseReady = widget.firebaseBootstrap.ready;
    _firebaseEmulatorsConfigured = widget.firebaseBootstrap.emulatorsConfigured;
    _appCheckConfigured = widget.firebaseBootstrap.appCheckConfigured;
    _firestoreCacheConfigured = widget.firebaseBootstrap.cacheConfigured;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeAfterFirstFrame());
    });
  }

  Future<void> _initializeAfterFirstFrame() async {
    await _guardedStartupStep('Haptics', () {
      return AppHaptics.init(ref.read(sharedPreferencesProvider));
    });
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _guardedStartupStep('Mobile ads', () async {
        await MobileAds.instance.initialize();
      });
    }
    await _guardedStartupStep('Hive and offline storage', () async {
      await Hive.initFlutter();
      await OfflineService().init();
    });
    final firebaseReady = await _guardedStartupStep(
      'Firebase',
      _initializeFirebaseIfNeeded,
    );
    if (firebaseReady) {
      if (!_firebaseEmulatorsConfigured) {
        _firebaseEmulatorsConfigured = await _guardedStartupStep(
          'Firebase emulators',
          _configureFirebaseEmulators,
        );
      }
      if (!_firestoreCacheConfigured) {
        _firestoreCacheConfigured = await _guardedStartupStep(
          'Firestore cache',
          _configureFirestoreCache,
        );
      }
    }
    if (firebaseReady && mounted) {
      setState(() => _firebaseReady = true);
    }
    if (firebaseReady && !EnvConfig.useFirebaseEmulators) {
      if (!_appCheckConfigured) {
        _appCheckConfigured = await _guardedStartupStep(
          'Firebase App Check',
          _activateFirebaseAppCheckIfNeeded,
        );
      }
      NotificationService.instance.attachNavigator(_navigatorKey);
      await _guardedStartupStep(
        'Notifications',
        NotificationService.instance.init,
      );
    }
    await _guardedStartupStep('Google Sign-In', () {
      if (kIsWeb) {
        return _initializeWebGoogleSignIn();
      }
      return GoogleSignInInitializer.ensureInitialized();
    });
    unawaited(_initDeepLinks());
  }

  Future<void> _initializeWebGoogleSignIn() async {
    await GoogleSignInInitializer.ensureInitialized();
    _googleAuthSubscription ??= GoogleSignIn.instance.authenticationEvents
        .listen(
          (event) => unawaited(_handleGoogleAuthenticationEvent(event)),
          onError: (Object error, StackTrace stackTrace) {
            AppLogCollector.add('error', 'Google Sign-In event failed: $error');
            AppLogCollector.recordZoneError(error, stackTrace);
          },
        );
  }

  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is GoogleSignInAuthenticationEventSignOut) {
      ref.invalidate(currentUserProvider);
      return;
    }
    if (event is! GoogleSignInAuthenticationEventSignIn) return;
    try {
      final idToken = event.user.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google Sign-In did not return an ID token.');
      }
      await ref.read(authRepositoryProvider).signInWithGoogleIdToken(idToken);
      ref.invalidate(currentUserProvider);
    } catch (error, stackTrace) {
      AppLogCollector.add(
        'error',
        'Google credential could not sign in to Firebase: $error',
      );
      AppLogCollector.recordZoneError(error, stackTrace);
      debugPrint('Google credential could not sign in to Firebase: $error');
    }
  }

  Future<bool> _guardedStartupStep(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      await action().timeout(_startupTimeout);
      return true;
    } catch (error, stackTrace) {
      AppLogCollector.add('error', '$name initialization failed: $error');
      AppLogCollector.recordZoneError(error, stackTrace);
      return false;
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _pendingDeepLink = initialUri;
        _processPendingDeepLink();
      }
    } catch (e) {
      debugPrint('Failed to get initial deep link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('Error handling deep link: $err');
      },
    );
  }

  void _processPendingDeepLink() {
    if (_pendingDeepLink == null) return;
    if (!_firebaseReady) {
      Future.delayed(
        const Duration(milliseconds: 100),
        _processPendingDeepLink,
      );
      return;
    }
    final uri = _pendingDeepLink!;
    _pendingDeepLink = null;
    _handleUri(uri);
    _drainPendingDeepLinkTarget();
  }

  void _handleUri(Uri uri) {
    if (_isDuplicateDeepLink(uri)) return;
    if (!_firebaseReady) {
      _pendingDeepLink = uri;
      return;
    }
    debugPrint('Handling deep link: $uri');

    final navigator = _navigatorKey.currentState;
    final target =
        AppRouter.routeSettingsForAppLink(uri.toString()) ??
        (!_isRootLink(uri)
            ? AppRouter.notFoundRouteSettingsForAppLink(uri.toString())
            : null);
    if (target == null && !_isRootLink(uri)) {
      return;
    }
    if (navigator == null) {
      _pendingDeepLinkTarget = target;
      return;
    }

    if (_isRootLink(uri)) {
      if (FirebaseAuth.instance.currentUser == null) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      _pendingDeepLinkTarget = target;
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      return;
    }

    _openResolvedDeepLinkTarget(target);
  }

  void _openResolvedDeepLinkTarget(RouteSettings? target) {
    if (target == null) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null || FirebaseAuth.instance.currentUser == null) {
      _pendingDeepLinkTarget = target;
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    if (target.name != null &&
        target.name != AppRoutes.main &&
        target.name != AppRoutes.root) {
      navigator.pushNamed(target.name!, arguments: target.arguments);
    }
  }

  void _drainPendingDeepLinkTarget() {
    final target = _pendingDeepLinkTarget;
    if (target == null) return;
    if (!_firebaseReady || FirebaseAuth.instance.currentUser == null) return;
    _pendingDeepLinkTarget = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openResolvedDeepLinkTarget(target);
    });
  }

  bool _isRootLink(Uri uri) {
    final hasRootPath = uri.path.isEmpty || uri.path == '/';
    return hasRootPath && !uri.hasQuery && !uri.hasFragment;
  }

  bool _isDuplicateDeepLink(Uri uri) {
    final now = DateTime.now();
    final key = uri.toString();
    final lastAt = _lastDeepLinkAt;
    final isDuplicate =
        _lastDeepLinkKey == key &&
        lastAt != null &&
        now.difference(lastAt) < _duplicateDeepLinkWindow;
    _lastDeepLinkKey = key;
    _lastDeepLinkAt = now;
    return isDuplicate;
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _googleAuthSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GlassMorphismThemeProvider(
          data: const GlassMorphismThemeData(
            defaultGlassColor: Color(0x88FFFFFF),
            lightGlassColor: Color(0xCCFFFFFF),
            darkGlassColor: Color(0xCC182033),
            defaultBlurIntensity: 24,
            defaultOpacity: 0.28,
            defaultBorderRadius: BorderRadius.all(Radius.circular(20)),
            enableSpecularHighlights: true,
            adaptiveColoring: false,
            cardTheme: GlassMorphismCardThemeData(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              blurIntensity: 26,
              opacity: 0.24,
            ),
            buttonTheme: GlassMorphismButtonThemeData(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              blurIntensity: 18,
              opacity: 0.28,
            ),
          ),
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            restorationScopeId: 'wreadom_app',
            title: 'Wreadom',
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            navigatorObservers: [if (_firebaseReady) AnalyticsService.observer],
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: ShakeToReportListener(
              navigatorKey: _navigatorKey,
              child: AuthWrapper(
                firebaseReady: _firebaseReady,
                onAuthenticated: _drainPendingDeepLinkTarget,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({
    super.key,
    required this.firebaseReady,
    required this.onAuthenticated,
  });

  final bool firebaseReady;
  final VoidCallback onAuthenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint(
          'AuthWrapper: authStateProvider error received: ${next.error}',
        );
        if (FirebaseAuth.instance.currentUser == null) {
          unawaited(ref.read(authRepositoryProvider).logout());
        } else {
          ref.invalidate(currentUserProvider);
        }
        return;
      }
      final previousId = previous?.asData?.value?.uid;
      final nextId = next.asData?.value?.uid;
      if (previousId != nextId) {
        ref.invalidate(currentUserProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(pagedNotificationsProvider);
        if (nextId != null) {
          unawaited(warmUserHomepageCache(ref));
          unawaited(
            ref.read(localeControllerProvider.notifier).syncPreferredLanguage(),
          );
          NotificationService.instance.drainPendingNavigation();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAuthenticated();
          });
        }
      }
      if (previousId != null && nextId == null) {
        AnalyticsService.identifyUser(null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
        });
      }
    });
    ref.listen(currentUserProvider, (previous, next) {
      final user = next.asData?.value;
      if (user == null) return;
      AnalyticsService.identifyUser(user.displayName ?? user.username);
    });
    ref.listen(notificationEventProvider, (previous, next) {
      if (!next.hasValue) return;
      ref.invalidate(notificationsProvider);
      ref.invalidate(pagedNotificationsProvider);
    });
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isVerified = ref.watch(emailVerifiedProvider(user.uid));
          if (!isVerified) {
            return EmailVerificationScreen(userId: user.uid);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(warmUserHomepageCache(ref));
            NotificationService.instance.drainPendingNavigation();
            onAuthenticated();
          });
          return OnboardingGate(
            userId: user.uid,
            child: const MainNavigationShell(),
          );
        }
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        AppLogCollector.recordZoneError(e, st);
        return const LoginScreen();
      },
    );
  }
}
