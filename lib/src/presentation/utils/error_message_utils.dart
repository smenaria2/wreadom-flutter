import 'package:firebase_auth/firebase_auth.dart';

import '../../localization/generated/app_localizations.dart';
import '../../utils/app_log_collector.dart';

String userFacingErrorMessage(AppLocalizations l10n, Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return l10n.authInvalidCredentials;
      case 'network-request-failed':
        return l10n.networkRequestFailed;
      case 'too-many-requests':
        return l10n.tooManyRequests;
      default:
        return l10n.authActionFailed;
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return l10n.permissionDeniedMessage;
      case 'unavailable':
      case 'deadline-exceeded':
        return l10n.networkRequestFailed;
      default:
        return l10n.somethingWentWrong;
    }
  }
  return l10n.somethingWentWrong;
}

void logUiError(String context, Object error, StackTrace? stackTrace) {
  AppLogCollector.add('error', '$context: $error');
  if (stackTrace != null) {
    AppLogCollector.recordZoneError(error, stackTrace);
  }
}
