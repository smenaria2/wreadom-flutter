import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_providers.dart';
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

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                // Logo placeholder
                Icon(
                  Icons.auto_stories,
                  size: 80.r,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 24.h),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _isLogin ? 'Sign in to continue reading' : 'Join our community of readers',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 48.h),
                if (!_isLogin)
                  AuthTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                  ),
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => (val == null || !val.contains('@')) ? 'Invalid email' : null,
                ),
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (val) => (val == null || val.length < 6) ? 'Min 6 chars' : null,
                ),
                SizedBox(height: 32.h),
                PrimaryButton(
                  text: _isLogin ? 'LOGIN' : 'SIGN UP',
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
                        'OR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Enter your email first')),
                        );
                        return;
                      }
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .resetPassword(email);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent'),
                          ),
                        );
                      } on firebase_auth.FirebaseAuthException catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? e.code),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                    child: const Text('Forgot password?'),
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
                      text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14.sp,
                      ),
                      children: [
                        TextSpan(
                          text: _isLogin ? "Sign Up" : "Login",
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
    );
  }
}
