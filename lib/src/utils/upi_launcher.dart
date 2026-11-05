import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outcome of trying to open a UPI app.
enum UpiLaunchResult {
  /// An app (or the system chooser) was opened.
  opened,

  /// The browser was asked to open the link but cannot report the outcome
  /// (web). Treat as "probably opened".
  requested,

  /// Nothing on this device can handle the link.
  noApp,
}

/// Opens a `upi://pay` link in the reader's UPI app.
///
/// - Android app: system chooser of installed UPI apps (native channel), then
///   a plain external launch as a fallback.
/// - Web: navigates the current tab to the `upi://` link. This must run
///   synchronously from the tap (no `await` before it), otherwise browsers
///   drop the user gesture and ignore the custom scheme.
class UpiLauncher {
  const UpiLauncher._();

  static const _channel = MethodChannel('in.wreadom.app/upi');

  /// Test seam for the plain URL launch.
  @visibleForTesting
  static Future<bool> Function(Uri uri, {String? webWindowName}) launch =
      _defaultLaunch;

  static Future<bool> _defaultLaunch(Uri uri, {String? webWindowName}) {
    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: webWindowName,
    );
  }

  static Future<UpiLaunchResult> pay(String upiLink) {
    if (kIsWeb) {
      // No await before this call: keep the user gesture.
      return launch(Uri.parse(upiLink), webWindowName: '_self').then(
        (_) => UpiLaunchResult.requested,
        onError: (_) => UpiLaunchResult.noApp,
      );
    }
    return _payNative(upiLink);
  }

  static Future<UpiLaunchResult> _payNative(String upiLink) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final reason = await _channel.invokeMethod<String>('pay', {
          'uri': upiLink,
        });
        if (reason == 'ok') return UpiLaunchResult.opened;
        debugPrint('UPI launch via chooser: $reason');
      } catch (error) {
        debugPrint('UPI launch channel failed: $error');
      }
    }
    try {
      final ok = await launch(Uri.parse(upiLink));
      return ok ? UpiLaunchResult.opened : UpiLaunchResult.noApp;
    } catch (_) {
      return UpiLaunchResult.noApp;
    }
  }
}
