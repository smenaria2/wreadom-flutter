import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/utils/tier_utils.dart';

void main() {
  group('tierInfoFor', () {
    test('clamps negative points and calculates first tier progress', () {
      final negative = tierInfoFor(-10, RankTrack.reader);
      expect(negative.points, 0);
      expect(negative.tier, 1);
      expect(negative.progressPercent, 0);
      expect(negative.pointsToNext, 500);

      final nearBoundary = tierInfoFor(499, RankTrack.author);
      expect(nearBoundary.tier, 1);
      expect(nearBoundary.pointsToNext, 1);
      expect(nearBoundary.progressPercent, closeTo(99.8, 0.001));
    });

    test('uses every threshold as the start of the next tier', () {
      for (var index = 0; index < tierDefinitions.length; index++) {
        final definition = tierDefinitions[index];
        final info = tierInfoFor(definition.minPoints, RankTrack.author);
        expect(info.tier, definition.tier);
        expect(
          info.progressPercent,
          index == tierDefinitions.length - 1 ? 100 : 0,
        );
      }
    });

    test('max tier has no next milestone', () {
      final info = tierInfoFor(1500000, RankTrack.reader);
      expect(info.tier, 8);
      expect(info.isMaxTier, isTrue);
      expect(info.pointsToNext, isNull);
      expect(info.progressPercent, 100);
    });
  });

  test('uses the shared tier palette for reader and author tracks', () {
    const expectedMainColors = [
      0xFF22C55E,
      0xFF14B8A6,
      0xFF0EA5E9,
      0xFF8B5CF6,
      0xFFF59E0B,
      0xFFF97316,
      0xFF4F46E5,
      0xFFD4AF37,
    ];
    for (var index = 0; index < tierDefinitions.length; index++) {
      final definition = tierDefinitions[index];
      expect(definition.mainColor.toARGB32(), expectedMainColors[index]);
      expect(
        definition.gradientFor(RankTrack.reader),
        definition.gradientFor(RankTrack.author),
      );
    }
  });
}
