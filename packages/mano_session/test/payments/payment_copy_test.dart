import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('PSE copy is shared by both apps', () {
    expect(LegalIdType.values.map(legalIdTypeLabel), ['CC', 'CE', 'NIT', 'PP']);
    expect(personTypeLabel(PsePersonType.natural), 'Persona natural');
    expect(personTypeLabel(PsePersonType.juridical), 'Persona jurídica');
  });
}
