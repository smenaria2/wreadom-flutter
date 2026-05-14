import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/presentation/providers/auth_providers.dart';
import 'src/presentation/providers/notification_providers.dart';
import 'src/presentation/providers/theme_provider.dart';
import 'src/presentation/routing/app_router.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/main_navigation_shell.dart';
import 'src/presentation/screens/onboarding_gate.dart';
import 'src/presentation/widgets/shake_to_report_listener.dart';
import 'src/data/services/analytics_service.dart';
import 'src/data/services/offline_service.dart';
import 'firebase_options.dart';
import 'src/data/services/notification_service.dart';
import 'src/utils/app_log_collector.dart';
import 'src/utils/app_haptics.dart';
import 'src/presentation/providers/locale_provider.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';

import 'package:google_sign_in/google_sign_in.dart';

const String _googleServerClientId =
    '601247128838-qp60rioakq1s65j51e5t2utq4n9gmoad.apps.googleusercontent.com';

void main() {
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
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MyApp(),
      ),
    );
  }, AppLogCollector.recordZoneError);
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastDeepLinkKey;
  DateTime? _lastDeepLinkAt;
  bool _firebaseReady = false;

  static const Duration _duplicateDeepLinkWindow = Duration(seconds: 5);
  static const Duration _startupTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
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
    final firebaseReady = await _guardedStartupStep('Firebase', () {
      if (Firebase.apps.isNotEmpty) return Future<void>.value();
      return Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });
    if (firebaseReady) {
      await _guardedStartupStep('Firestore cache', _configureFirestoreCache);
    }
    if (firebaseReady && mounted) {
      setState(() => _firebaseReady = true);
    }
    if (firebaseReady) {
      await _guardedStartupStep('Firebase App Check', () {
        return FirebaseAppCheck.instance.activate(
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
      });
      NotificationService.instance.attachNavigator(_navigatorKey);
      await _guardedStartupStep(
        'Notifications',
        NotificationService.instance.init,
      );
    }
    await _guardedStartupStep('Google Sign-In', () {
      if (kIsWeb) {
        return GoogleSignIn.instance.initialize(
          clientId: _googleServerClientId,
        );
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return GoogleSignIn.instance.initialize(
          serverClientId: _googleServerClientId,
        );
      }
      return Future<void>.value();
    });
    unawaited(_initDeepLinks());
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
        // Delay navigation slightly to ensure the app is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleUri(initialUri);
        });
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

  Future<void> _configureFirestoreCache() async {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 80 * 1024 * 1024,
    );
  }

  void _handleUri(Uri uri) {
    if (_isDuplicateDeepLink(uri)) return;
    debugPrint('Handling deep link: $uri');
    // We pass the full string to pushNamed, as AppRouter will resolve it
    // using AppLinkHelper. This works for both http/https and custom schemes.
    _navigatorKey.currentState?.pushNamed(uri.toString());
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
        return MaterialApp(
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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EE),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6200EE),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          ),
          themeMode: themeMode,
          navigatorObservers: [if (_firebaseReady) AnalyticsService.observer],
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: ShakeToReportListener(
            navigatorKey: _navigatorKey,
            child: AuthWrapper(firebaseReady: _firebaseReady),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) return const LoginScreen();

    ref.listen(authStateProvider, (previous, next) {
      final previousId = previous?.asData?.value?.uid;
      final nextId = next.asData?.value?.uid;
      if (previousId != nextId) {
        ref.invalidate(currentUserProvider);
        ref.invalidate(notificationsProvider);
        ref.invalidate(pagedNotificationsProvider);
        if (nextId != null) {
          unawaited(
            ref.read(localeControllerProvider.notifier).syncPreferredLanguage(),
          );
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
        return Scaffold(
          body: Center(
            child: Text(AppLocalizations.of(context)!.somethingWentWrong),
          ),
        );
      },
    );
  }
}
