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
}
