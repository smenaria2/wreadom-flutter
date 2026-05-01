import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showSwipeHintOnce({
  required BuildContext context,
  required String key,
  required String message,
  required String actionLabel,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(key) == true || !context.mounted) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(label: actionLabel, onPressed: () {}),
    ),
  );
}
