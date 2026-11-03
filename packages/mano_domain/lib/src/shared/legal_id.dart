/// Cédula de ciudadanía, cédula de extranjería, NIT, pasaporte.
enum LegalIdType { cc, ce, nit, pp }

final _separators = RegExp(r'[\s.\-]');

/// [raw] without spaces, dots or dashes, upper-cased.
String normalizeLegalId(String raw) =>
    raw.replaceAll(_separators, '').toUpperCase();

/// Whether [raw], once normalised, fits [type].
bool isValidLegalId(LegalIdType type, String raw) =>
    _legalIdPattern(type).hasMatch(normalizeLegalId(raw));

// CC 6-10 digits, CE 6-12 alphanumeric, NIT 9-10 digits (with check digit), PP 5-12.
RegExp _legalIdPattern(LegalIdType type) => switch (type) {
  LegalIdType.cc => RegExp(r'^\d{6,10}$'),
  LegalIdType.ce => RegExp(r'^[A-Z0-9]{6,12}$'),
  LegalIdType.nit => RegExp(r'^\d{9,10}$'),
  LegalIdType.pp => RegExp(r'^[A-Z0-9]{5,12}$'),
};
