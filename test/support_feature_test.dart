import 'package:flutter_test/flutter_test.dart';
import 'package:librebook_flutter/src/domain/models/author_support.dart';
import 'package:librebook_flutter/src/utils/upi_link_builder.dart';

SupportClaim _claim(
  String id,
  String status, {
  int updatedAt = 1000,
  int? verifiedAt,
  String name = 'Reader',
  String? supporter,
}) => SupportClaim(
  id: id,
  authorId: 'a',
  supporterId: supporter ?? id,
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
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    SupportClaim claim(String id, String status, {String supporter = 'u'}) =>
        _claim(
          id,
          status,
          updatedAt: nowMs,
          verifiedAt: status == 'verified' ? nowMs : null,
          supporter: supporter,
        );

    test('author sees verified first, then pending; hidden dropped', () {
      final result = SupportClaim.visibleSorted([
        _claim('c1', 'claimed', updatedAt: nowMs - 1000),
        _claim('v1', 'verified', updatedAt: nowMs - 5000, verifiedAt: nowMs - 5000),
        _claim('h1', 'hidden', updatedAt: nowMs),
        _claim('c2', 'claimed', updatedAt: nowMs - 500),
        _claim('v2', 'verified', updatedAt: nowMs - 2000, verifiedAt: nowMs - 2000),
      ], forAuthor: true);
      expect(result.map((c) => c.id), ['v2', 'v1', 'c2', 'c1']);
    });

    test('unconfirmed claims are hidden from everyone but the supporter', () {
      final mine = claim('mine', 'claimed', supporter: 'me');
      final other = claim('other', 'claimed', supporter: 'someone');
      final verified = claim('v', 'verified', supporter: 'someone');

      // Another reader sees only the confirmed one.
      expect(
        SupportClaim.visibleSorted(
          [mine, other, verified],
          forAuthor: false,
          viewerId: 'x',
        ).map((c) => c.id),
        ['v'],
      );
      // Signed-out viewers see only confirmed ones.
      expect(
        SupportClaim.visibleSorted([mine, other, verified], forAuthor: false)
            .map((c) => c.id),
        ['v'],
      );
      // The supporter additionally sees their own pending claim.
      expect(
        SupportClaim.visibleSorted(
          [mine, other, verified],
          forAuthor: false,
          viewerId: 'me',
        ).map((c) => c.id),
        ['v', 'mine'],
      );
    });

    test('once confirmed the claim shows for everyone, including the payer', () {
      final confirmed = claim('mine', 'verified', supporter: 'me');
      for (final viewer in ['me', 'x', null]) {
        expect(
          SupportClaim.visibleSorted(
            [confirmed],
            forAuthor: false,
            viewerId: viewer,
          ),
          hasLength(1),
        );
      }
    });

    test('blank names are dropped', () {
      final blank = _claim('b', 'verified', name: '');
      expect(
        SupportClaim.visibleSorted([blank], forAuthor: true),
        isEmpty,
      );
    });
  });
}
