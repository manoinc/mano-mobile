import 'package:mano_domain/mano_domain.dart';

// PSE payer copy, one wording for both apps.

String legalIdTypeLabel(LegalIdType type) => switch (type) {
  LegalIdType.cc => 'CC',
  LegalIdType.ce => 'CE',
  LegalIdType.nit => 'NIT',
  LegalIdType.pp => 'PP',
};

String personTypeLabel(PsePersonType type) => switch (type) {
  PsePersonType.natural => 'Persona natural',
  PsePersonType.juridical => 'Persona jurídica',
};
