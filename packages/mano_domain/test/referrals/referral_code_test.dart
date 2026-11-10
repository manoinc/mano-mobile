import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ReferralCode.parse', () {
    test('accepts a code as mano-profiles mints it', () {
      expect(ReferralCode.parse('RP-bb2cde6b')?.value, 'RP-bb2cde6b');
    });

    test('trims and normalises the case the backend matches exactly', () {
      expect(ReferralCode.parse('  rp-BB2CDE6B ')?.value, 'RP-bb2cde6b');
    });

    test('refuses anything else', () {
      for (final raw in [
        '',
        'RP-',
        'RP-bb2cde6',
        'RP-bb2cde6bb',
        'RP-bb2cde6g',
        'XX-bb2cde6b',
        'RP-bb2c de6',
        '<script>',
      ]) {
        expect(ReferralCode.parse(raw), isNull, reason: raw);
      }
    });

    test('two codes with the same value are equal', () {
      expect(
        ReferralCode.parse('RP-bb2cde6b'),
        ReferralCode.parse('rp-bb2cde6b'),
      );
    });
  });

  group('ReferralCode.fromInviteLink', () {
    test('reads the code from /r/<code>', () {
      final link = Uri.parse('https://manoapp.co/r/RP-bb2cde6b');
      expect(ReferralCode.fromInviteLink(link)?.value, 'RP-bb2cde6b');
    });

    test('tolerates a trailing slash and a query', () {
      final link = Uri.parse('https://manoapp.co/r/RP-bb2cde6b/?utm=wa');
      expect(ReferralCode.fromInviteLink(link)?.value, 'RP-bb2cde6b');
    });

    test('ignores other paths and malformed codes', () {
      for (final link in [
        'https://manoapp.co/',
        'https://manoapp.co/r/',
        'https://manoapp.co/x/RP-bb2cde6b',
        'https://manoapp.co/r/nope',
        'https://manoapp.co/r/RP-bb2cde6b/extra',
      ]) {
        expect(
          ReferralCode.fromInviteLink(Uri.parse(link)),
          isNull,
          reason: link,
        );
      }
    });
  });

  group('ReferralCode.fromInstallReferrer', () {
    test('reads ref=<code> from the Play referrer', () {
      expect(
        ReferralCode.fromInstallReferrer('ref=RP-bb2cde6b')?.value,
        'RP-bb2cde6b',
      );
    });

    test('finds ref among other parameters, still encoded or not', () {
      expect(
        ReferralCode.fromInstallReferrer(
          'utm_source=google-play&ref=RP-bb2cde6b',
        )?.value,
        'RP-bb2cde6b',
      );
      expect(
        ReferralCode.fromInstallReferrer('ref%3DRP-bb2cde6b')?.value,
        'RP-bb2cde6b',
      );
    });

    test('an organic install has no code', () {
      for (final referrer in [
        null,
        '',
        'utm_source=google-play&utm_medium=organic',
        'ref=nope',
        '%zz',
      ]) {
        expect(
          ReferralCode.fromInstallReferrer(referrer),
          isNull,
          reason: referrer,
        );
      }
    });
  });
}
