import 'package:flutter/material.dart';

/// Shows a themed snackbar. Errors use the color scheme's error colors
/// instead of ad hoc `Colors.red` backgrounds.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: isError ? TextStyle(color: scheme.onError) : null,
      ),
      backgroundColor: isError ? scheme.error : null,
    ),
  );
}
