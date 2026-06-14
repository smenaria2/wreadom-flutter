// ignore_for_file: avoid_web_libraries_in_flutter

// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/services.dart';

Future<bool> writeClipboardTextImpl(String text) async {
  final body = html.document.body;
  if (body != null) {
    final textArea = html.TextAreaElement()
      ..value = text
      ..setAttribute('readonly', 'true')
      ..style.position = 'fixed'
      ..style.left = '-10000px'
      ..style.top = '0';
    body.append(textArea);
    textArea.select();
    try {
      if (html.document.execCommand('copy')) return true;
    } finally {
      textArea.remove();
    }
  }

  await Clipboard.setData(ClipboardData(text: text));
  return true;
}
