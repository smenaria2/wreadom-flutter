import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author_support.dart';
import 'package:librebook_flutter/src/utils/upi_link_builder.dart';

SupportClaim _claim(
  String id,
  String status, {
  int updatedAt = 1000,
  int? verifiedAt,
  String name = 'Reader',
}) => SupportClaim(
  id: id,
  authorId: 'a',
  supporterId: id,
  supporterName: name,
  status: status,
  createdAt: updatedAt,
  updatedAt: updatedAt,
  verifiedAt: verifiedAt,
);

void main() {
  group('UpiLinkBuilder', () {
    test('normalizes and validates VPAs', () {
      expect(UpiLinkBuilder.normalizeVpa(' Name.X@OkHDFC '), 'name.x@okhdfc');
      expect(UpiLinkBuilder.normalizeVpa('9876543210@ybl'), '9876543210@ybl');
      expect(UpiLinkBuilder.normalizeVpa('no-at-sign'), isNull);
      expect(UpiLinkBuilder.normalizeVpa('a@b'), isNull);
      expect(UpiLinkBuilder.normalizeVpa(''), isNull);
      expect(UpiLinkBuilder.normalizeVpa('bad space@ybl'), isNull);
    });

    test('validates 12-digit UTR', () {
      expect(UpiLinkBuilder.normalizeUtr('123456789012'), '123456789012');
      expect(UpiLinkBuilder.normalizeUtr('12345'), isNull);
      expect(UpiLinkBuilder.normalizeUtr('12345678901a'), isNull);
    });

    test('builds an encoded upi link', () {
      final link = UpiLinkBuilder.build(
        vpa: 'a@ybl',
        payeeName: 'Asha Rao',
        amountInr: 50,
      );
      expect(link, startsWith('upi://pay?'));
      expect(link, contains('pa=a%40ybl'));
      expect(link, contains('pn=Asha%20Rao'));
      expect(link, contains('am=50.00'));
      expect(link, contains('cu=INR'));
      expect(link, isNot(contains('+')));
    });

    test('omits amount when not set', () {
      final link = UpiLinkBuilder.build(vpa: 'a@ybl', payeeName: 'A');
      expect(link, isNot(contains('am=')));
    });
  });

  group('SupportClaim.visibleSorted', () {
    final now = DateTime.fromMillisecondsSinceEpoch(
      100 * Duration.millisecondsPerDay,
    );
    final nowMs = now.millisecondsSinceEpoch;

    test('verified first, then claimed; hidden dropped', () {
      final result = SupportClaim.visibleSorted([
        _claim('c1', 'claimed', updatedAt: nowMs - 1000),
        _claim('v1', 'verified', updatedAt: nowMs - 5000, verifiedAt: nowMs - 5000),
        _claim('h1', 'hidden', updatedAt: nowMs),
        _claim('c2', 'claimed', updatedAt: nowMs - 500),
        _claim('v2', 'verified', updatedAt: nowMs - 2000, verifiedAt: nowMs - 2000),
      ], forAuthor: false, now: now);
      expect(result.map((c) => c.id), ['v2', 'v1', 'c2', 'c1']);
    });

    test('old unconfirmed claims hidden from public but not the author', () {
      final old = _claim(
        'old',
        'claimed',
        updatedAt: nowMs - const Duration(days: 20).inMilliseconds,
      );
      expect(
        SupportClaim.visibleSorted([old], forAuthor: false, now: now),
        isEmpty,
      );
      expect(
        SupportClaim.visibleSorted([old], forAuthor: true, now: now),
        hasLength(1),
      );
    });

    test('verified claims never expire and blank names are dropped', () {
      final verifiedOld = _claim(
        'v',
        'verified',
        updatedAt: 1,
        verifiedAt: 1,
      );
      final blank = _claim('b', 'verified', name: '');
      final result = SupportClaim.visibleSorted(
        [verifiedOld, blank],
        forAuthor: false,
        now: now,
      );
      expect(result.map((c) => c.id), ['v']);
    });
  });
}
