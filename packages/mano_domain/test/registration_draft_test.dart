import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('RegistrationDraft', () {
    test('starts empty, and an empty draft is not complete', () {
      const draft = RegistrationDraft();

      expect(draft.givenName, isEmpty);
      expect(draft.familyName, isEmpty);
      expect(draft.address, isEmpty);
      expect(draft.isNameComplete, isFalse);
      expect(draft.isAddressComplete, isFalse);
    });

    test('opts into notifications and offers by default', () {
      // The sheet shows both switches already on; the draft has to agree.
      const draft = RegistrationDraft();

      expect(draft.wantsNotifications, isTrue);
      expect(draft.wantsPromotions, isTrue);
    });

    test('copyWith leaves untouched fields alone', () {
      const draft = RegistrationDraft(givenName: 'Ana', familyName: 'Rojas');

      final moved = draft.copyWith(address: 'Calle 12 #3-45');

      expect(moved.givenName, 'Ana');
      expect(moved.familyName, 'Rojas');
      expect(moved.address, 'Calle 12 #3-45');
    });

    test('copyWith can turn a flag off', () {
      // A `bool?` parameter that treats false as "unset" is the classic
      // copyWith bug, and it would silently re-enable marketing email.
      const draft = RegistrationDraft();

      expect(draft.copyWith(wantsPromotions: false).wantsPromotions, isFalse);
      expect(draft.copyWith(wantsPromotions: false).wantsNotifications, isTrue);
    });

    test('completeness ignores surrounding whitespace', () {
      const padded = RegistrationDraft(givenName: '  Ana  ', familyName: ' R ');

      expect(padded.isNameComplete, isTrue);
      expect(const RegistrationDraft(givenName: '   ').isNameComplete, isFalse);
      expect(
        const RegistrationDraft(address: '   ').isAddressComplete,
        isFalse,
      );
    });

    test('needs both halves of a name', () {
      expect(const RegistrationDraft(givenName: 'Ana').isNameComplete, isFalse);
      expect(
        const RegistrationDraft(familyName: 'Rojas').isNameComplete,
        isFalse,
      );
    });

    test('greetingName is the trimmed first name, for the step 2 headline', () {
      expect(const RegistrationDraft(givenName: '  Ana  ').greetingName, 'Ana');
    });

    test('greetingName takes only the first word of a compound first name', () {
      // "¡Un gusto conocerte, Ana María!" is a mouthful; the greeting uses one.
      expect(
        const RegistrationDraft(givenName: 'Ana María').greetingName,
        'Ana',
      );
    });

    test('has value equality', () {
      const a = RegistrationDraft(givenName: 'Ana', address: 'Calle 1');
      const b = RegistrationDraft(givenName: 'Ana', address: 'Calle 1');
      const c = RegistrationDraft(givenName: 'Ana', address: 'Calle 2');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('toString keeps the address out of it', () {
      // Where somebody lives is the most sensitive thing here, and toString
      // ends up in logs.
      const draft = RegistrationDraft(
        givenName: 'Ana',
        familyName: 'Rojas',
        address: 'Calle 12 #3-45',
      );

      expect(draft.toString(), isNot(contains('Calle')));
      expect(draft.toString(), contains('Ana'));
    });
  });
}
