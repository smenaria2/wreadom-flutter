import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/widgets/primary_button.dart';
import 'package:librebook_flutter/src/presentation/providers/auth_providers.dart';

void main() {
  Widget testApp(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  testWidgets('PrimaryButton renders with correct semantics label when loading and not loading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        PrimaryButton(
          text: 'Submit Comment',
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check semantic node label is "Submit Comment"
    expect(find.bySemanticsLabel('Submit Comment'), findsOneWidget);

    // Re-pump with loading state
    await tester.pumpWidget(
      testApp(
        PrimaryButton(
          text: 'Submit Comment',
          onPressed: () {},
          isLoading: true,
        ),
      ),
    );
    await tester.pump();

    // Check semantic node label announces loading state
    expect(find.bySemanticsLabel('Submit Comment, loading'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('PageView horizontal scroll semantics support', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    final controller = PageController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            children: [
              Semantics(
                label: 'Page 1',
                child: const SizedBox(width: 100, height: 100),
              ),
              Semantics(
                label: 'Page 2',
                child: const SizedBox(width: 100, height: 100),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Get semantics node for Page 1 and verify its parent (the scrollable viewport) has the scrollLeft action
    final page1Node = tester.getSemantics(find.bySemanticsLabel('Page 1'));
    final parentNode = page1Node.parent;
    expect(parentNode, isNotNull);
    expect(parentNode!.getSemanticsData().hasAction(SemanticsAction.scrollLeft), true);
    semantics.dispose();
  });

  testWidgets('Theme Option wrapper renders with correct semantics properties', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();
    var tapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            container: true,
            button: true,
            label: 'Sepia',
            selected: true,
            onTap: () {
              tapped = true;
            },
            child: GestureDetector(
              onTap: () {
                tapped = true;
              },
              child: const Text('Sepia'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify semantics label, selected, and button properties
    final node = tester.getSemantics(find.bySemanticsLabel('Sepia').first);
    expect(node.label, 'Sepia');
    expect(node.hasFlag(SemanticsFlag.isSelected), true);
    expect(node.hasFlag(SemanticsFlag.isButton), true);

    // Trigger tap through semantics
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    expect(tapped, true);
    semantics.dispose();
  });
}
