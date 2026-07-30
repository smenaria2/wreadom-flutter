import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/widgets/hindi_input_wrapper.dart';

void main() {
  group('HindiInputWrapper Widget Tests', () {
    late TextEditingController controller;
    late FocusNode focusNode;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget buildTestWidget({double bottomInset = 0.0}) {
      return MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: bottomInset)),
            child: SizedBox(
              width: 800,
              height: 600,
              child: HindiInputWrapper(
                controller: controller,
                focusNode: focusNode,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Toggle button appears only when focused and keyboard is open', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // 1. Initially closed & unfocused: no toggle button
      await tester.pumpWidget(buildTestWidget(bottomInset: 0.0));
      expect(find.text('अ'), findsNothing);

      // 2. Focused but keyboard closed: no toggle button
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('अ'), findsNothing);

      // 3. Focused and keyboard open (bottomInset > 0): toggle button is visible
      await tester.pumpWidget(buildTestWidget(bottomInset: 300.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('अ'), findsOneWidget);
    });

    testWidgets('Toggling Hindi mode enables suggestion bar on typing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(buildTestWidget(bottomInset: 300.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      final toggleFinder = find.text('अ');
      expect(toggleFinder, findsOneWidget);

      // Tap toggle button to enable Hindi mode
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Type "namaste" into text field using enterText
      await tester.enterText(find.byType(TextField), 'namaste');
      await tester.pumpAndSettle();

      // Verify that suggestions are visible (namaste should show Devanagari "नमस्ते")
      expect(find.text('नमस्ते'), findsOneWidget);
    });

    testWidgets('Tapping suggestion chip commits Devanagari replacement', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(buildTestWidget(bottomInset: 300.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Enable Hindi mode
      await tester.tap(find.text('अ'));
      await tester.pumpAndSettle();

      // Type "namaste"
      await tester.enterText(find.byType(TextField), 'namaste');
      await tester.pumpAndSettle();

      final chipFinder = find.text('नमस्ते');
      expect(chipFinder, findsOneWidget);

      // Tap suggestion chip
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Verify text is committed and suggestion bar is dismissed
      expect(controller.text, equals('नमस्ते'));
      expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_HindiSuggestionChip'), findsNothing);
    });
  });
}
