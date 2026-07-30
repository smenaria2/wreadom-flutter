import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:librebook_flutter/src/presentation/controllers/hindi_transliteration_controller.dart';
import 'package:librebook_flutter/src/presentation/widgets/writer_custom_toolbar.dart';
import 'package:librebook_flutter/src/presentation/widgets/writer_hindi_suggestion_bar.dart';

Widget _buildTestApp(Widget body) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  );
}

void main() {
  group('Writer Hindi Transliteration Widget Tests', () {
    late QuillController quillController;
    late FocusNode focusNode;
    late HindiTransliterationController transliterationController;

    setUp(() {
      quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
      focusNode = FocusNode();
      transliterationController = HindiTransliterationController();
    });

    tearDown(() {
      quillController.dispose();
      focusNode.dispose();
      transliterationController.dispose();
    });

    testWidgets('Hindi mode is disabled by default in toolbar',
        (WidgetTester tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        _buildTestApp(
          WriterCustomToolbar(
            controller: quillController,
            focusNode: focusNode,
            onInsertImage: () {},
            isUploadingInlineImage: false,
            onInsertVideo: () {},
            onVersionHistory: () {},
            onAiEdit: () {},
            isHindiModeEnabled: transliterationController.isEnabled,
            onToggleHindi: () {
              toggled = true;
            },
          ),
        ),
      );

      expect(find.text('अ'), findsOneWidget);
      await tester.tap(find.text('अ'));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets(
        'WriterHindiSuggestionBar displays suggestions and replaces token on tap',
        (WidgetTester tester) async {
      transliterationController.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );
      transliterationController.updateForSelection(quillController);

      await tester.pumpWidget(
        _buildTestApp(
          Column(
            children: [
              WriterHindiSuggestionBar(
                transliterationController: transliterationController,
                quillController: quillController,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('नमस्ते'), findsWidgets);

      await tester.tap(find.text('नमस्ते').first);
      await tester.pumpAndSettle();

      expect(quillController.document.toPlainText(), contains('नमस्ते'));
      expect(transliterationController.hasSuggestion, isFalse);
    });

    testWidgets(
        'WriterHindiSuggestionBar dismisses suggestion when raw English word is tapped',
        (WidgetTester tester) async {
      transliterationController.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );
      transliterationController.updateForSelection(quillController);

      await tester.pumpWidget(
        _buildTestApp(
          Column(
            children: [
              WriterHindiSuggestionBar(
                transliterationController: transliterationController,
                quillController: quillController,
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      final rawEnglishFinder = find.text('Namaste');
      expect(rawEnglishFinder, findsOneWidget);

      await tester.tap(rawEnglishFinder);
      await tester.pumpAndSettle();

      expect(transliterationController.hasSuggestion, isFalse);
      expect(quillController.document.toPlainText(), equals('Namaste\n'));
    });
  });
}
