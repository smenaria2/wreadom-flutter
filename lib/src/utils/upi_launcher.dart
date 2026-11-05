import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a `upi://pay` link in the reader's UPI app. On Android this shows the
/// system chooser of installed UPI apps (the NPCI-recommended approach);
/// elsewhere it falls back to a plain external launch.
class UpiLauncher {
  const UpiLauncher._();

  static const _channel = MethodChannel('in.wreadom.app/upi');

  /// Returns true when an app was opened.
  static Future<bool> pay(String upiLink) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final ok = await _channel.invokeMethod<bool>('pay', {'uri': upiLink});
        if (ok == true) return true;
      } catch (_) {}
    }
    try {
      return await launchUrl(
        Uri.parse(upiLink),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
