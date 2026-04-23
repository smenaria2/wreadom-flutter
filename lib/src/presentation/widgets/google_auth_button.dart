import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import '../providers/auth_controller.dart';
import 'google_sign_in_stub.dart'
    if (dart.library.html) 'google_sign_in_web_impl.dart'
    if (dart.library.js_interop) 'google_sign_in_web_impl.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        alignment: Alignment.center,
        child: getGoogleSignInButton(
          onPressed: () {}, // Ignored on Web as GIS handles it
        ),
      );
    }

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
  }
}
