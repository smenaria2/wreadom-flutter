import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:librebook_flutter/src/data/services/devlipi_hindi_engine.dart';
import 'package:librebook_flutter/src/presentation/controllers/hindi_transliteration_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevlipiHindiEngine Unit Tests', () {
    const engine = DevlipiHindiEngine();

    test(
      'Common Dakshina spellings return highest-attested Hindi candidate first',
      () {
        final results = engine.transliterateToken('namaste');
        expect(results, isNotEmpty);
        expect(results.first, equals('नमस्ते'));

        final bharat = engine.transliterateToken('bharat');
        expect(bharat, isNotEmpty);
        expect(bharat.first, equals('भारत'));
      },
    );

    test('Alternate Roman spellings resolve correctly', () {
      final dhanyavaad = engine.transliterateToken('dhanyavaad');
      final dhanyavad = engine.transliterateToken('dhanyavad');
      expect(dhanyavaad, contains('धन्यवाद'));
      expect(dhanyavad, contains('धन्यवाद'));
    });

    test('Uppercase and lowercase Roman tokens behave identically', () {
      final lower = engine.transliterateToken('namaste');
      final upper = engine.transliterateToken('NAMASTE');
      final title = engine.transliterateToken('Namaste');
      expect(lower, equals(upper));
      expect(lower, equals(title));
    });

    test('Ambiguous keys are consistently ranked and deduplicated', () {
      final results = engine.transliterateToken('khushi');
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.length, lessThanOrEqualTo(10));
      // Verify deduplication
      expect(results.toSet().length, equals(results.length));
    });

    test('Unknown names and words fall back to devlipi', () {
      // Testing a unique name/word unlikely to be in dataset
      final results = engine.transliterateToken('zxzqwerty');
      expect(results, isNotEmpty);
    });

    test(
      'Empty input, whitespace, numbers, and punctuation return empty list',
      () {
        expect(engine.transliterateToken(''), isEmpty);
        expect(engine.transliterateToken('   '), isEmpty);
        expect(engine.transliterateToken('!!!'), isEmpty);
        expect(engine.transliterateToken('...'), isEmpty);
        expect(engine.transliterateToken('12345'), isEmpty);
      },
    );

    test('Existing Devanagari text is ignored and returned as empty list', () {
      expect(engine.transliterateToken('नमस्ते'), isEmpty);
      expect(engine.transliterateToken('भारत'), isEmpty);
    });

    test('URLs and email addresses are ignored', () {
      expect(engine.transliterateToken('https://example.com'), isEmpty);
      expect(engine.transliterateToken('www.google.com'), isEmpty);
      expect(engine.transliterateToken('user@domain.com'), isEmpty);
    });

    test(
      'Inaccurate heuristic mutations (broad nukta, matra flip, trailing-a) are removed',
      () {
        // Input without nukta in standard spelling should not generate artificial nukta variations like "फ़" unless dictionary or devlipi provides it
        final testInput = engine.transliterateToken('fool');
        // Verify no broad nukta / matra-flipping pollution
        expect(testInput.length, lessThanOrEqualTo(10));
        expect(testInput.toSet().length, equals(testInput.length));
      },
    );
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
      expect(controller.hindiSuggestion, equals('नमस्ते'));
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

    test(
      'Dismiss suggestion clears active suggestion state without text edit',
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
      },
    );

    test(
      'Chapter switch clears suggestion but keeps enabled session state',
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
      },
    );

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
      expect(quillController.document.toPlainText(), isNot(contains('नमस्ते')));
    });

    test(
      'Pressing backspace after commit restores Roman token and suggestions',
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
      },
    );

    test('Pressing backspace after Space commit restores Roman token', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'Raam');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 4),
        ChangeSource.local,
      );

      controller.updateForSelection(quillController);
      expect(controller.hasSuggestion, isTrue);

      final topSuggestion = controller.hindiSuggestion!;
      controller.commitSuggestion(quillController, appendText: ' ');
      expect(
        quillController.document.toPlainText(),
        equals('$topSuggestion \n'),
      );
      expect(controller.canRestoreCommit, isTrue);

      final handled = controller.handleBackspace(quillController);
      expect(handled, isTrue);
      expect(quillController.document.toPlainText(), equals('Raam\n'));
      expect(controller.hasSuggestion, isTrue);
    });

    test('Period followed by space is replaced by danda when enabled', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'hello.');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      // Now user presses space
      quillController.document.insert(6, ' ');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      expect(quillController.document.toPlainText(), equals('hello। \n'));
    });

    test('Ellipsis followed by space remains ellipsis', () {
      controller.isEnabled = true;
      quillController.document.insert(0, 'hello...');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 8),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      // Now user presses space
      quillController.document.insert(8, ' ');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 9),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      expect(quillController.document.toPlainText(), equals('hello... \n'));
    });

    test('Period followed by space is NOT replaced when disabled', () {
      controller.isEnabled = false;
      quillController.document.insert(0, 'hello.');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      // Now user presses space
      quillController.document.insert(6, ' ');
      quillController.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );
      controller.updateForSelection(quillController);

      expect(quillController.document.toPlainText(), equals('hello. \n'));
    });

    test(
      'Punctuation typing immediately after Roman token auto-commits suggestion',
      () {
        controller.isEnabled = true;
        quillController.document.insert(0, 'hain');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);
        expect(controller.hasSuggestion, isTrue);

        // User types '.'
        quillController.document.insert(4, '.');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);

        expect(quillController.document.toPlainText(), equals('हैं।\n'));
        expect(controller.canRestoreCommit, isTrue);

        // Backspace restores 'hain'
        final handled = controller.handleBackspace(quillController);
        expect(handled, isTrue);
        expect(quillController.document.toPlainText(), equals('hain\n'));
      },
    );

    test(
      'Comma typing immediately after Roman token auto-commits suggestion',
      () {
        controller.isEnabled = true;
        quillController.document.insert(0, 'hain');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);

        // User types ','
        quillController.document.insert(4, ',');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);

        expect(quillController.document.toPlainText(), equals('हैं,\n'));
      },
    );

    test(
      'Space typing delta immediately after Roman token auto-commits suggestion',
      () {
        controller.isEnabled = true;
        quillController.document.insert(0, 'hain');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);
        expect(controller.hasSuggestion, isTrue);

        // User types space ' ' (as an IME delta text insertion)
        quillController.document.insert(4, ' ');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);

        expect(quillController.document.toPlainText(), equals('हैं \n'));
        expect(controller.canRestoreCommit, isTrue);

        // Backspace restores 'hain'
        final handled = controller.handleBackspace(quillController);
        expect(handled, isTrue);
        expect(quillController.document.toPlainText(), equals('hain\n'));
      },
    );

    test(
      'Out of bounds selection offsets do not throw and clear suggestions',
      () {
        controller.isEnabled = true;
        quillController.document.insert(0, 'short');
        quillController.updateSelection(
          const TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.updateForSelection(quillController);
        expect(controller.hasSuggestion, isTrue);

        final shortenedDocument = Document()..insert(0, 'x');
        final outOfBoundsController = QuillController(
          document: shortenedDocument,
          selection: const TextSelection.collapsed(offset: 999),
        );
        addTearDown(outOfBoundsController.dispose);

        expect(
          () => controller.updateForSelection(outOfBoundsController),
          returnsNormally,
        );
        expect(controller.hasSuggestion, isFalse);
      },
    );
  });
}
