import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('security hardening source checks', () {
    test('admin topic writes require admin claim in client controller', () {
      final source = File(
        'lib/src/presentation/providers/admin_topic_providers.dart',
      ).readAsStringSync();

      expect(source, contains('currentUserAdminClaimProvider.future'));
      expect(source, contains('Future<void> _requireAdmin()'));
      expect(source, contains('await _requireAdmin();'));
    });

    test(
      'local functions admin check does not hard-code an email fallback',
      () {
        final source = File('functions/index.js').readAsStringSync();

        expect(source, isNot(contains('smenaria2@gmail.com')));
        expect(source, contains('return token.admin === true;'));
      },
    );

    test('composer and admin UI have runtime guardrails', () {
      final composer = File(
        'lib/src/presentation/components/create_post_sheet.dart',
      ).readAsStringSync();
      final adminTopics = File(
        'lib/src/presentation/screens/admin_daily_topics_screen.dart',
      ).readAsStringSync();

      expect(composer, contains('Audio upload has not completed'));
      expect(composer, contains('_pickedImageBytes'));
      expect(composer, contains('scrollDirection: Axis.horizontal'));
      expect(composer, contains('maxHeight: maxSheetHeight'));
      expect(adminTopics, contains('PopupMenuButton<_TopicTileAction>'));
      expect(adminTopics, contains('constraints.maxWidth < 430'));
    });
    test('webviews restrict script/navigation where possible', () {
      final legal = File(
        'lib/src/presentation/screens/legal_document_screen.dart',
      ).readAsStringSync();
      final media = File(
        'lib/src/presentation/widgets/in_app_media_web_view.dart',
      ).readAsStringSync();
      final archive = File(
        'lib/src/presentation/screens/archive_reader_screen.dart',
      ).readAsStringSync();
      final instagram = File(
        'lib/src/presentation/widgets/instagram_embed_widget.dart',
      ).readAsStringSync();

      expect(legal, contains('JavaScriptMode.disabled'));
      expect(legal, contains('_isAllowedLegalUri'));
      expect(media, contains('_isAllowedMediaNavigation'));
      expect(media, contains('_requiresJavaScript'));
      expect(archive, contains('_isAllowedArchiveNavigation'));
      expect(archive, contains('Uri.tryParse(request.url)'));
      expect(instagram, contains('_htmlAttribute(embedUrl)'));
    });
  });
}
