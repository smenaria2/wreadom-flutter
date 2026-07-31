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

    Widget buildTestWidget({
      double bottomInset = 0.0,
      bool enabled = true,
      bool readOnly = false,
      double topPadding = 100.0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: bottomInset)),
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: SizedBox(
                width: 800,
                height: 50,
                child: HindiInputWrapper(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  readOnly: readOnly,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Toggle button is always visible inside active input field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // 1. Initially unfocused: toggle button is visible inside input field
      await tester.pumpWidget(buildTestWidget(bottomInset: 0.0));
      expect(find.text('अ'), findsOneWidget);

      // 2. Focused and keyboard closed: toggle button is visible
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('अ'), findsOneWidget);

      // 3. Focused and keyboard open (bottomInset > 0): toggle button is visible
      await tester.pumpWidget(buildTestWidget(bottomInset: 300.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('अ'), findsOneWidget);
    });

    testWidgets('Toggle button hides when enabled is false or readOnly is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(enabled: false));
      expect(find.text('अ'), findsNothing);

      await tester.pumpWidget(buildTestWidget(readOnly: true));
      expect(find.text('अ'), findsNothing);
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

    testWidgets('Suggestion bar renders via CompositedTransformFollower above input container', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(buildTestWidget(bottomInset: 0.0, topPadding: 100.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      await tester.tap(find.text('अ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'namaste');
      await tester.pumpAndSettle();

      expect(find.ancestor(of: find.text('नमस्ते'), matching: find.byType(CompositedTransformFollower)), findsOneWidget);
      expect(find.text('नमस्ते'), findsOneWidget);
    });

    testWidgets('Suggestion bar renders below search bar when near top of screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(buildTestWidget(bottomInset: 0.0, topPadding: 0.0));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      await tester.tap(find.text('अ'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'namaste');
      await tester.pumpAndSettle();

      expect(find.ancestor(of: find.text('नमस्ते'), matching: find.byType(CompositedTransformFollower)), findsOneWidget);
      expect(find.text('नमस्ते'), findsOneWidget);
    });

    testWidgets('Tapping suggestion chip commits Devanagari replacement', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(buildTestWidget(bottomInset: 300.0, topPadding: 100.0));
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
