import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/presentation/widgets/modal_feedback_scope.dart';

void main() {
  testWidgets('modal feedback renders inside the active sheet route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => ModalFeedbackScope(
                  child: Builder(
                    builder: (sheetContext) => SizedBox(
                      height: 240,
                      child: Center(
                        child: FilledButton(
                          onPressed: () => ModalFeedbackScope.show(
                            sheetContext,
                            const SnackBar(
                              content: Text('Visible sheet warning'),
                            ),
                          ),
                          child: const Text('Trigger warning'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger warning'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(ModalFeedbackScope),
        matching: find.text('Visible sheet warning'),
      ),
      findsOneWidget,
    );
  });
}
