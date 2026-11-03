import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

const _casa = SavedAddress(label: 'Casa', line: 'Calle 45 # 12-30');
const _trabajo = SavedAddress(label: 'Trabajo', line: 'Carrera 7 # 71-21');

void main() {
  group('MockClientProfileRepository', () {
    test('starts from the seed and keeps what is saved', () async {
      final repo = MockClientProfileRepository(
        initial: const ClientProfile(displayName: 'Ana'),
      );
      expect((await repo.profile()).displayName, 'Ana');

      const next = ClientProfile(
        displayName: 'Ana Rojas',
        phone: '3001234567',
        email: 'ana@mano.co',
      );
      expect((await repo.update(next)).valueOrNull, next);
      expect(await repo.profile(), next);
    });

    test('a new photo is kept without validating the rest', () async {
      final repo = MockClientProfileRepository();
      final result = await repo.updatePhoto('https://cdn/avatar.png');
      expect(result.valueOrNull!.photoUrl, 'https://cdn/avatar.png');
      expect((await repo.profile()).photoUrl, 'https://cdn/avatar.png');
    });

    test('refuses a profile with problems', () async {
      final repo = MockClientProfileRepository();
      final result = await repo.update(const ClientProfile());
      expect(result.failureOrNull, isA<DataRejected>());
    });
  });

  group('MockAddressBook', () {
    late MockAddressBook book;
    setUp(() => book = MockAddressBook());

    test('starts empty', () async {
      expect(await book.list(), isEmpty);
    });

    test('the first address becomes the default; ids are assigned', () async {
      final casa = (await book.add(_casa)).valueOrNull!;
      final trabajo = (await book.add(_trabajo)).valueOrNull!;
      expect(casa.id, isNotEmpty);
      expect(trabajo.id, isNot(casa.id));
      expect(casa.isDefault, isTrue);
      expect(trabajo.isDefault, isFalse);
      expect((await book.list()).map((a) => a.label), ['Casa', 'Trabajo']);
    });

    test('adding one marked default takes the default over', () async {
      await book.add(_casa);
      await book.add(_trabajo.copyWith(isDefault: true));
      expect((await book.list()).first.label, 'Trabajo');
    });

    test('updates in place, keeping the default', () async {
      final casa = (await book.add(_casa)).valueOrNull!;
      await book.update(casa.copyWith(notes: 'Torre 2', isDefault: false));
      final list = await book.list();
      expect(list.single.notes, 'Torre 2');
      expect(list.single.isDefault, isTrue);
    });

    test('setDefault and remove keep exactly one default', () async {
      final casa = (await book.add(_casa)).valueOrNull!;
      final trabajo = (await book.add(_trabajo)).valueOrNull!;
      await book.setDefault(trabajo.id);
      expect((await book.list()).first.id, trabajo.id);

      await book.remove(trabajo.id);
      final list = await book.list();
      expect(list.single.id, casa.id);
      expect(list.single.isDefault, isTrue);
    });

    test('unknown ids and invalid addresses are refused', () async {
      expect((await book.remove('nope')).failureOrNull, isA<DataNotFound>());
      expect(
        (await book.setDefault('nope')).failureOrNull,
        isA<DataNotFound>(),
      );
      expect(
        (await book.update(_casa.copyWith(id: 'nope'))).failureOrNull,
        isA<DataNotFound>(),
      );
      expect(
        (await book.add(_casa.copyWith(line: ''))).failureOrNull,
        isA<DataRejected>(),
      );
    });
  });

  group('MockPaymentMethods', () {
    late MockPaymentMethods methods;
    setUp(() => methods = MockPaymentMethods(now: () => DateTime(2026, 11, 2)));

    test('keeps only brand and last four, first is default', () async {
      final card = (await methods.add(
        const NewCard(number: '4242 4242 4242 4242', expiry: '12/28'),
      )).valueOrNull!;
      final nequi = (await methods.add(const NewNequi(phone: '3001234567')))
          .valueOrNull!;
      expect(card.label, 'Visa');
      expect(card.last4, '4242');
      expect(card.isDefault, isTrue);
      expect(nequi.isDefault, isFalse);
      expect(await methods.list(), hasLength(2));
    });

    test('setDefault and remove keep exactly one default', () async {
      final card = (await methods.add(
        const NewCard(number: '4242424242424242', expiry: '12/28'),
      )).valueOrNull!;
      final nequi = (await methods.add(const NewNequi(phone: '3001234567')))
          .valueOrNull!;
      await methods.setDefault(nequi.id);
      expect((await methods.list()).first.id, nequi.id);
      await methods.remove(nequi.id);
      expect((await methods.list()).single.id, card.id);
      expect((await methods.list()).single.isDefault, isTrue);
    });

    test('refuses invalid input and unknown ids', () async {
      expect(
        (await methods.add(const NewCard(number: '1234', expiry: '12/28')))
            .failureOrNull,
        isA<DataRejected>(),
      );
      expect((await methods.remove('nope')).failureOrNull, isA<DataNotFound>());
    });
  });

  group('MockSupportDesk', () {
    test('files a ticket with a radicado number', () async {
      final desk = MockSupportDesk(now: () => DateTime(2026, 11, 2));
      const draft = SupportTicketDraft(
        subject: 'Cobro doble',
        description: 'Me cobraron dos veces la limpieza.',
      );
      final first = (await desk.file(draft)).valueOrNull!;
      final second = (await desk.file(draft)).valueOrNull!;
      expect(first.ticketNumber, 'PQR-2026-00001');
      expect(second.ticketNumber, 'PQR-2026-00002');
      expect(first.subject, 'Cobro doble');
      expect(first.createdAt, DateTime(2026, 11, 2));
    });

    test('refuses a draft with problems', () async {
      final desk = MockSupportDesk();
      final result = await desk.file(
        const SupportTicketDraft(subject: '', description: ''),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });
  });
}
