import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('the supported countries', () {
    test('start with Colombia, the default', () {
      expect(supportedCountries.first, Country.colombia);
      expect(Country.colombia.code, 'CO');
      expect(Country.colombia.dialCode, '57');
    });

    test('cover the region plus the US and Spain', () {
      expect(supportedCountries.map((c) => c.code), [
        'CO',
        'MX',
        'PE',
        'EC',
        'CL',
        'AR',
        'VE',
        'US',
        'ES',
      ]);
    });

    test('each carries its flag', () {
      expect(Country.colombia.flag, '🇨🇴');
      expect(countryByCode('ES')?.flag, '🇪🇸');
    });

    test('are found by code, ignoring case', () {
      expect(countryByCode('mx')?.name, 'México');
      expect(countryByCode('ZZ'), isNull);
    });
  });

  group('a number in E.164', () {
    test('a Colombian mobile takes +57 whatever the separators', () {
      expect(phoneE164('300 123 4567', Country.colombia), '+573001234567');
      expect(
        phoneE164('+57 (300) 123-4567', Country.colombia),
        '+573001234567',
      );
    });

    test('a Colombian number must be ten digits starting with 3', () {
      expect(phoneE164('601 123 4567', Country.colombia), isNull);
      expect(phoneE164('30012', Country.colombia), isNull);
    });

    test('elsewhere takes six to twelve digits after the dial code', () {
      final mexico = countryByCode('MX')!;
      final ecuador = countryByCode('EC')!;

      expect(phoneE164('55 1234 5678', mexico), '+525512345678');
      expect(phoneE164('+593 99 123 4567', ecuador), '+593991234567');
      expect(phoneE164('12345', mexico), isNull);
      expect(phoneE164('1234567890123', mexico), isNull);
      expect(phoneE164('55a1234', mexico), isNull);
    });
  });
}
