import 'package:flutter/services.dart';

Future<bool> writeClipboardTextImpl(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  return true;
}
