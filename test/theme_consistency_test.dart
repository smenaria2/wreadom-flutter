import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/widgets/themed_empty_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final themes = [
    ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A3E85)),
    ),
    ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A3E85),
        brightness: Brightness.dark,
      ),
    ),
  ];

  for (final theme in themes) {
    final mode = theme.brightness.name;

    testWidgets('themed empty state follows $mode color scheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: ThemedEmptyState(
              icon: Icons.inbox_outlined,
              message: 'Nothing here',
            ),
          ),
        ),
      );

      final expected = theme.colorScheme.onSurfaceVariant;
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      final text = tester.widget<Text>(find.text('Nothing here'));

      expect(icon.color, expected.withValues(alpha: 0.72));
      expect(text.style?.color, expected);
    });

    test('semantic colors remain readable in $mode mode', () {
      expect(
        ThemeData.estimateBrightnessForColor(theme.colorScheme.error),
        isNot(ThemeData.estimateBrightnessForColor(theme.colorScheme.onError)),
      );
      expect(
        ThemeData.estimateBrightnessForColor(theme.colorScheme.surface),
        isNot(
          ThemeData.estimateBrightnessForColor(theme.colorScheme.onSurface),
        ),
      );
    });
  }
}
