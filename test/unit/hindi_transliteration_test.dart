import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:librebook_flutter/src/data/services/devlipi_hindi_engine.dart';
import 'package:librebook_flutter/src/presentation/controllers/hindi_transliteration_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevlipiHindiEngine Unit Tests', () {
    const engine = DevlipiHindiEngine();

    test('Namaste transliterates to Devanagari नमस्ते', () {
      final results = engine.transliterateToken('Namaste');
      expect(results, isNotEmpty);
      expect(results.first, contains('नमस्ते'));
    });

    test('Generates 3-4 suggestions for words with phonetic variations', () {
      final results = engine.transliterateToken('khushi');
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results.length, lessThanOrEqualTo(4));
    });

    test('Common Hindi words transliterate correctly', () {
      final dhanyavaad = engine.transliterateToken('dhanyavaad');
      final mera = engine.transliterateToken('mera');
      final pyaar = engine.transliterateToken('pyaar');

      expect(dhanyavaad, isNotEmpty);
      expect(mera, isNotEmpty);
      expect(pyaar, isNotEmpty);
    });

    test('Empty input, whitespace, and punctuation return empty list', () {
      expect(engine.transliterateToken(''), isEmpty);
      expect(engine.transliterateToken('   '), isEmpty);
      expect(engine.transliterateToken('!!!'), isEmpty);
      expect(engine.transliterateToken('...'), isEmpty);
    });

    test('Existing Devanagari text is ignored and returned as empty list', () {
      expect(engine.transliterateToken('नमस्ते'), isEmpty);
      expect(engine.transliterateToken('भारत'), isEmpty);
    });

    test('URLs and email addresses are ignored', () {
      expect(engine.transliterateToken('https://example.com'), isEmpty);
      expect(engine.transliterateToken('www.google.com'), isEmpty);
      expect(engine.transliterateToken('user@domain.com'), isEmpty);
    });

    test('Uppercase and lowercase Roman tokens are transliterated', () {
      final lower = engine.transliterateToken('namaste');
      final upper = engine.transliterateToken('NAMASTE');
      expect(lower, isNotEmpty);
      expect(upper, isNotEmpty);
    });
  });

  group('HindiTransliterationController Unit Tests', () {
    late HindiTransliterationController controller;
    late QuillController quillController;

    setUp(() {
      controller = HindiTransliterationController();
      quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
    });

    tearDown(() {
      controller.dispose();
      quillController.dispose();
    });

    test('Disabled by default', () {
      expect(controller.isEnabled, isFalse);
      expect(controller.hasSuggestion, isFalse);
    });

    test('Does not process suggestions while disabled', () {
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isFalse);
    });

    test('Produces suggestions list when enabled and Roman token typed', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);
      expect(controller.activeRomanToken, equals('Namaste'));
      expect(controller.hindiSuggestions, isNotEmpty);
      expect(controller.hindiSuggestion, isNotNull);
    });

    test('Commit suggestion replaces Roman token in Quill document', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);

      final committed = controller.commitSuggestion(
        quillController,
        appendText: ' ',
      );
      expect(committed, isTrue);
      expect(controller.hasSuggestion, isFalse);

      final text = quillController.document.toPlainText();
      expect(text, contains('नमस्ते'));
      expect(text, isNot(contains('Namaste')));
    });

    test('Dismiss suggestion clears active suggestion state without text edit',
        () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);

      controller.dismissSuggestion();
      expect(controller.hasSuggestion, isFalse);
      expect(quillController.document.toPlainText(), equals('Namaste\n'));
    });

    test('Chapter switch clears suggestion but keeps enabled session state',
        () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);

      controller.clearForChapterSwitch();
      expect(controller.hasSuggestion, isFalse);
      expect(controller.isEnabled, isTrue);
    });

    test('Quill replacement can be undone via QuillController.undo()', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Namaste');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      controller.commitSuggestion(quillController);

      expect(quillController.document.toPlainText(), contains('नमस्ते'));

      quillController.undo();
      expect(
        quillController.document.toPlainText(),
        isNot(contains('नमस्ते')),
      );
    });

    test('Pressing backspace after commit restores Roman token and suggestions',
        () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Raam');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 4),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);

      final topSuggestion = controller.hindiSuggestion!;
      controller.commitSuggestion(quillController);
      expect(quillController.document.toPlainText(), contains(topSuggestion));
      expect(controller.canRestoreCommit, isTrue);

      final handled = controller.handleBackspace(quillController);
      expect(handled, isTrue);
      expect(quillController.document.toPlainText(), equals('Raam\n'));
    });
  });
}

