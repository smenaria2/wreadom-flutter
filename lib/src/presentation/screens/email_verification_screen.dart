import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../localization/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../providers/email_verification_provider.dart';
import '../widgets/glass_scaffold.dart';
import '../widgets/glass_surface.dart';
import '../widgets/primary_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String userId;

  const EmailVerificationScreen({super.key, required this.userId});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  int _cooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;
  bool _checking = false;
  bool _resending = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto check status every 5 seconds
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus(isAuto: true);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown > 1) {
        setState(() {
          _cooldown--;
        });
      } else {
        setState(() {
          _cooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendVerification() async {
    if (_cooldown > 0 || _resending) return;

    setState(() {
      _resending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        setState(() {
          _successMessage = l10n.resendSuccess;
        });
        _startCooldown();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  Future<void> _checkStatus({bool isAuto = false}) async {
    if (_checking) return;

    if (!isAuto) {
      setState(() {
        _checking = true;
        _errorMessage = null;
        _successMessage = null;
      });
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        // Get fresh user reference after reload
        final updatedUser = fb_auth.FirebaseAuth.instance.currentUser;
        if (updatedUser != null && updatedUser.emailVerified) {
          _autoCheckTimer?.cancel();
          _cooldownTimer?.cancel();
          ref
              .read(emailVerifiedProvider(widget.userId).notifier)
              .setVerified(true);
        } else if (!isAuto) {
          setState(() {
            _errorMessage = l10n.verificationFailed;
          });
        }
      }
    } catch (e) {
      if (!isAuto) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted && !isAuto) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      _autoCheckTimer?.cancel();
      _cooldownTimer?.cancel();
      await ref.read(authRepositoryProvider).logout();
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GlassSurface(
              strong: true,
              borderRadius: BorderRadius.circular(24.r),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.h),
                  // Animated-like mail icon
                  Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48.r,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    l10n.emailVerificationTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    l10n.emailVerificationDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.emailVerificationInstruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  if (_successMessage != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: colorScheme.error.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (_successMessage != null || _errorMessage != null)
                    SizedBox(height: 24.h),
                  PrimaryButton(
                    text: l10n.checkVerificationStatus,
                    isLoading: _checking,
                    onPressed: () => _checkStatus(),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          onPressed: (_cooldown > 0 || _resending)
                              ? null
                              : _resendVerification,
                          child: _resending
                              ? SizedBox(
                                  height: 16.h,
                                  width: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                )
                              : Text(
                                  _cooldown > 0
                                      ? l10n.resendCooldown(_cooldown)
                                      : l10n.resendVerification,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          onPressed: _logout,
                          child: Text(
                            l10n.logout,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
