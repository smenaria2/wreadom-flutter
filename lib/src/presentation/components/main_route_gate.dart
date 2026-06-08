import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';
import 'package:librebook_flutter/src/presentation/providers/email_verification_provider.dart';
import 'package:librebook_flutter/src/presentation/providers/homepage_providers.dart';
import 'package:librebook_flutter/src/data/services/notification_service.dart';
import 'package:librebook_flutter/src/presentation/screens/email_verification_screen.dart';
import 'package:librebook_flutter/src/presentation/screens/login_screen.dart';
import 'package:librebook_flutter/src/presentation/screens/onboarding_gate.dart';
import 'package:librebook_flutter/src/presentation/screens/main_navigation_shell.dart';

class MainRouteGate extends ConsumerWidget {
  const MainRouteGate({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          final isVerified = ref.watch(emailVerifiedProvider(user.uid));
          if (!isVerified) {
            return EmailVerificationScreen(userId: user.uid);
          }
          
          // Trigger post-auth actions when verified
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(warmUserHomepageCache(ref));
            NotificationService.instance.drainPendingNavigation();
          });

          return OnboardingGate(
            userId: user.uid,
            child: MainNavigationShell(initialIndex: initialIndex),
          );
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => const LoginScreen(),
    );
  }
}
