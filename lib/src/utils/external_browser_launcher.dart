import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link in a browser app. On Android wreadom.in is an app link, so a
/// plain launch would route straight back into this app; the native side
/// targets a browser package explicitly.
class ExternalBrowserLauncher {
  static const _channel = MethodChannel('in.wreadom.app/external_browser');

  static Future<bool> open(Uri uri) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final ok = await _channel.invokeMethod<bool>('open', {
          'url': uri.toString(),
        });
        if (ok == true) return true;
      } catch (_) {}
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
