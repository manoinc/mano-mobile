/// A country a phone number can belong to.
final class Country {
  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
  });

  /// ISO 3166-1 alpha-2, e.g. `CO`.
  final String code;

  /// In Spanish, e.g. `Colombia`.
  final String name;

  /// Without the plus, e.g. `57`.
  final String dialCode;

  static const colombia = Country(code: 'CO', name: 'Colombia', dialCode: '57');

  /// The flag emoji, built from the code's regional indicator letters.
  String get flag =>
      String.fromCharCodes(code.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41));

  @override
  bool operator ==(Object other) => other is Country && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// The countries the sign-in offers, Colombia first.
const supportedCountries = [
  Country.colombia,
  Country(code: 'MX', name: 'México', dialCode: '52'),
  Country(code: 'PE', name: 'Perú', dialCode: '51'),
  Country(code: 'EC', name: 'Ecuador', dialCode: '593'),
  Country(code: 'CL', name: 'Chile', dialCode: '56'),
  Country(code: 'AR', name: 'Argentina', dialCode: '54'),
  Country(code: 'VE', name: 'Venezuela', dialCode: '58'),
  Country(code: 'US', name: 'Estados Unidos', dialCode: '1'),
  Country(code: 'ES', name: 'España', dialCode: '34'),
];

/// The supported country with [code], or null.
Country? countryByCode(String code) {
  final upper = code.toUpperCase();
  for (final country in supportedCountries) {
    if (country.code == upper) return country;
  }
  return null;
}

/// [value] as `+<dial><digits>`, or null if it is not a number in [country].
String? phoneE164(String value, Country country) {
  var digits = value.replaceAll(RegExp(r'[\s\-().]'), '');
  final prefix = '+${country.dialCode}';
  if (digits.startsWith(prefix)) digits = digits.substring(prefix.length);
  final valid = country == Country.colombia
      ? RegExp(r'^3\d{9}$')
      : RegExp(r'^\d{6,12}$');
  return valid.hasMatch(digits) ? '$prefix$digits' : null;
}
