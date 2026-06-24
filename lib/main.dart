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
import 'src/presentation/routing/pending_navigation_coordinator.dart';
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
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.audioservice.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    );
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
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 80 * 1024 * 1024,
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
  await FirebaseAuth.instance.useAuthEmulator(host, EnvConfig.firebaseAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(host, EnvConfig.firebaseFirestoreEmulatorPort);
  FirebaseFunctions.instance.useFunctionsEmulator(host, EnvConfig.firebaseFunctionsEmulatorPort);
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
  late bool _firebaseRetrying;
  final _pendingNavigation = PendingNavigationCoordinator();

  static const Duration _duplicateDeepLinkWindow = Duration(seconds: 5);
  static const Duration _startupTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _firebaseReady = widget.firebaseBootstrap.ready;
    _firebaseEmulatorsConfigured = widget.firebaseBootstrap.emulatorsConfigured;
    _appCheckConfigured = widget.firebaseBootstrap.appCheckConfigured;
    _firestoreCacheConfigured = widget.firebaseBootstrap.cacheConfigured;
    _firebaseRetrying = !_firebaseReady;
    _pendingNavigation.updateReadiness(firebaseReady: _firebaseReady);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingNavigation.updateReadiness(
        navigatorReady: _navigatorKey.currentState != null,
      );
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
    if (mounted) {
      setState(() {
        _firebaseReady = firebaseReady;
        _firebaseRetrying = false;
      });
      _pendingNavigation.updateReadiness(firebaseReady: firebaseReady);
      _drainPendingDeepLinkTarget();
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

  Future<void> _retryFirebaseStartup() async {
    if (_firebaseRetrying) return;
    setState(() => _firebaseRetrying = true);
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
      if (!_appCheckConfigured && !EnvConfig.useFirebaseEmulators) {
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
    if (!mounted) return;
    setState(() {
      _firebaseReady = firebaseReady;
      _firebaseRetrying = false;
    });
    _pendingNavigation.updateReadiness(firebaseReady: firebaseReady);
    _drainPendingDeepLinkTarget();
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
        _handleUri(initialUri);
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

  void _handleUri(Uri uri) {
    if (_isDuplicateDeepLink(uri)) return;
    debugPrint('Handling deep link: $uri');

    final target =
        AppRouter.routeSettingsForAppLink(uri.toString()) ??
        (!_isRootLink(uri)
            ? AppRouter.notFoundRouteSettingsForAppLink(uri.toString())
            : const RouteSettings(name: AppRoutes.main));
    if (target == null) return;
    _pendingNavigation.setTarget(target);
    _drainPendingDeepLinkTarget();
  }

  void _openResolvedDeepLinkTarget(RouteSettings target) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    if (target.name != null &&
        target.name != AppRoutes.main &&
        target.name != AppRoutes.root) {
      navigator.pushNamed(target.name!, arguments: target.arguments);
    }
  }

  void _drainPendingDeepLinkTarget() {
    _pendingNavigation.updateReadiness(
      firebaseReady: _firebaseReady,
      navigatorReady: _navigatorKey.currentState != null,
    );
    final target = _pendingNavigation.takeReadyTarget();
    if (target == null) return;
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
    _pendingNavigation.dispose();
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
                firebaseRetrying: _firebaseRetrying,
                onRetryFirebase: _retryFirebaseStartup,
                onReadinessChanged:
                    ({
                      required authenticated,
                      required emailVerified,
                      required onboardingReady,
                    }) {
                      _pendingNavigation.updateReadiness(
                        authenticated: authenticated,
                        emailVerified: emailVerified,
                        onboardingReady: onboardingReady,
                      );
                      _drainPendingDeepLinkTarget();
                    },
                onSignedOut: () {
                  _pendingNavigation
                    ..clear()
                    ..updateReadiness(
                      authenticated: false,
                      emailVerified: false,
                      onboardingReady: false,
                    );
                },
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
    required this.firebaseRetrying,
    required this.onRetryFirebase,
    required this.onReadinessChanged,
    required this.onSignedOut,
  });

  final bool firebaseReady;
  final bool firebaseRetrying;
  final Future<void> Function() onRetryFirebase;
  final void Function({
    required bool authenticated,
    required bool emailVerified,
    required bool onboardingReady,
  })
  onReadinessChanged;
  final VoidCallback onSignedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) {
      if (firebaseRetrying) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.somethingWentWrong),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetryFirebase,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
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
        }
      }
      if (previousId != null && nextId == null) {
        onSignedOut();
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
            _notifyReadiness(
              authenticated: true,
              emailVerified: false,
              onboardingReady: false,
            );
            return EmailVerificationScreen(userId: user.uid);
          }
          return OnboardingGate(
            userId: user.uid,
            onReady: () {
              unawaited(warmUserHomepageCache(ref));
              NotificationService.instance.drainPendingNavigation();
              onReadinessChanged(
                authenticated: true,
                emailVerified: true,
                onboardingReady: true,
              );
            },
            child: const MainNavigationShell(),
          );
        }
        _notifyReadiness(
          authenticated: false,
          emailVerified: false,
          onboardingReady: false,
        );
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

  void _notifyReadiness({
    required bool authenticated,
    required bool emailVerified,
    required bool onboardingReady,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onReadinessChanged(
        authenticated: authenticated,
        emailVerified: emailVerified,
        onboardingReady: onboardingReady,
      );
    });
  }
}
