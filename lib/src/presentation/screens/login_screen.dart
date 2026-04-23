import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_auth_button.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    if (_isLogin) {
      controller.signIn(_emailController.text, _passwordController.text);
    } else {
      controller.signUp(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (e, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(appThemeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.w,
                      children: [
                        _LoginMenuButton<ThemeMode>(
                          tooltip: l10n.theme,
                          icon: themeMode == ThemeMode.dark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          value: themeMode,
                          items: [
                            PopupMenuItem(
                              value: ThemeMode.light,
                              child: _MenuChoice(
                                icon: Icons.light_mode_outlined,
                                label: l10n.light,
                                selected: themeMode == ThemeMode.light,
                              ),
                            ),
                            PopupMenuItem(
                              value: ThemeMode.dark,
                              child: _MenuChoice(
                                icon: Icons.dark_mode_outlined,
                                label: l10n.dark,
                                selected: themeMode == ThemeMode.dark,
                              ),
                            ),
                          ],
                          onSelected: (value) => ref
                              .read(appThemeControllerProvider.notifier)
                              .setThemeMode(value),
                        ),
                        _LoginMenuButton<Locale>(
                          tooltip: l10n.language,
                          icon: Icons.language_rounded,
                          value: locale,
                          items: [
                            PopupMenuItem(
                              value: const Locale('en'),
                              child: _MenuChoice(
                                icon: Icons.translate_rounded,
                                label: l10n.english,
                                selected: locale.languageCode == 'en',
                              ),
                            ),
                            PopupMenuItem(
                              value: const Locale('hi'),
                              child: _MenuChoice(
                                icon: Icons.translate_rounded,
                                label: l10n.hindi,
                                selected: locale.languageCode == 'hi',
                              ),
                            ),
                          ],
                          onSelected: (value) => ref
                              .read(localeControllerProvider.notifier)
                              .setLocale(value),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 52.h),
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 86.r,
                    height: 86.r,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.auto_stories,
                      size: 80.r,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    _isLogin ? l10n.welcomeBack : l10n.createAccount,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _isLogin ? l10n.signInToContinue : l10n.joinCommunity,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 48.h),
                  if (!_isLogin)
                    AuthTextField(
                      controller: _usernameController,
                      hintText: l10n.username,
                      prefixIcon: Icons.person_outline,
                      validator: (val) => (val == null || val.isEmpty)
                          ? l10n.requiredField
                          : null,
                    ),
                  AuthTextField(
                    controller: _emailController,
                    hintText: l10n.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => (val == null || !val.contains('@'))
                        ? l10n.invalidEmail
                        : null,
                  ),
                  AuthTextField(
                    controller: _passwordController,
                    hintText: l10n.password,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (val) =>
                        (val == null || val.length < 6) ? l10n.minChars : null,
                  ),
                  SizedBox(height: 32.h),
                  PrimaryButton(
                    text: _isLogin ? l10n.loginBtn : l10n.signupBtn,
                    isLoading: authState.isLoading,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          l10n.orDivider,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final colorScheme = Theme.of(context).colorScheme;
                        final email = _emailController.text.trim();
                        if (email.isEmpty) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.enterEmailFirst)),
                          );
                          return;
                        }
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .resetPassword(email);
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.passwordResetSent)),
                          );
                        } on firebase_auth.FirebaseAuthException catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e.message ?? e.code),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      },
                      child: Text(l10n.forgotPassword),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Google Sign In Button
                  const GoogleSignInButton(),
                  SizedBox(height: 40.h),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: RichText(
                      text: TextSpan(
                        text: _isLogin
                            ? l10n.dontHaveAccount
                            : l10n.alreadyHaveAccount,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14.sp,
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin ? l10n.signUpLink : l10n.loginLink,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginMenuButton<T> extends StatelessWidget {
  const _LoginMenuButton({
    required this.tooltip,
    required this.icon,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final String tooltip;
  final IconData icon;
  final T value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: PopupMenuButton<T>(
          tooltip: tooltip,
          initialValue: value,
          onSelected: onSelected,
          itemBuilder: (context) => items,
          icon: Icon(icon, color: colorScheme.primary),
        ),
      ),
    );
  }
}

class _MenuChoice extends StatelessWidget {
  const _MenuChoice({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check_rounded, size: 20, color: colorScheme.primary),
        ],
      ],
    );
  }
}
