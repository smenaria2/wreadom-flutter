import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/data/services/reader_ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('next chapter ad allows progress when no ad is loaded', () async {
    final service = ReaderAdService(adsEnabledForTesting: true);

    final allowed = await service.showNextChapterAdIfReady();

    expect(allowed, isTrue);
    service.dispose();
  });
}
