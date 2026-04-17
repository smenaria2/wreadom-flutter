import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/presentation/providers/auth_providers.dart';
import 'src/presentation/routing/app_router.dart';
import 'src/presentation/screens/login_screen.dart';
import 'src/presentation/screens/main_navigation_shell.dart';
import 'src/data/services/offline_service.dart';
import 'firebase_options.dart';

import 'package:google_sign_in/google_sign_in.dart';

const String _googleServerClientId =
    '601247128838-qp60rioakq1s65j51e5t2utq4n9gmoad.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineService().init(); // Open the offline boxes
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple:
        kDebugMode ? const AppleDebugProvider() : const AppleDeviceCheckProvider(),
    providerWeb: ReCaptchaV3Provider('6Lfm-SsqAAAAAA8G1o1I1y7Y5_7yQ1yX7o1yX7o1'),
  );
  if (kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId: _googleServerClientId,
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
  }
  runApp(const ProviderScope(child: MyApp()));
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
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

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('Handling deep link: $uri');
    // We pass the full string to pushNamed, as AppRouter will resolve it
    // using AppLinkHelper. This works for both http/https and custom schemes.
    _navigatorKey.currentState?.pushNamed(uri.toString());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Wreadom',
          debugShowCheckedModeBanner: false,
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
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainNavigationShell();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Scaffold(
        body: Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
