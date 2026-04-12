import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

Widget getGoogleSignInButton({required VoidCallback? onPressed}) {
  return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      shape: web.GSIButtonShape.rectangular,
      size: web.GSIButtonSize.large,
      text: web.GSIButtonText.continueWith,
    ),
  );
}
