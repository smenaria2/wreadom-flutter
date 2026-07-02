import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/auth_controller.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return OutlinedButton.icon(
          onPressed: () =>
              ref.read(authControllerProvider.notifier).signInWithGoogle(),
          icon: const Icon(Icons.g_mobiledata, size: 30),
          label: Text(AppLocalizations.of(context)!.continueWithGoogle),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 56.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }
}
