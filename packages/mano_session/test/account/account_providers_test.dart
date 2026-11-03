import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

const _casa = SavedAddress(label: 'Casa', line: 'Calle 45 # 12-30');
const _trabajo = SavedAddress(label: 'Trabajo', line: 'Carrera 7 # 71-21');

void main() {
  group('clientProfileSeed', () {
    test('takes the registration name and the account email', () {
      const user = AuthenticatedUser(
        subject: 'u-1',
        username: 'ana@mano.co',
        roles: {ManoRole.requester},
      );
      final seed = clientProfileSeed(
        user,
        const OnboardingBrowsing(name: 'Ana'),
      );
      expect(seed.displayName, 'Ana');
      expect(seed.email, 'ana@mano.co');
      expect(seed.photoUrl, isNull);
    });

    test('is blank for a guest', () {
      expect(
        clientProfileSeed(null, const OnboardingTour()),
        const ClientProfile(),
      );
    });
  });

  group('client profile', () {
    late ProviderContainer container;
    setUp(
      () => container = ProviderContainer.test(
        overrides: [
          clientProfileRepositoryProvider.overrideWithValue(
            MockClientProfileRepository(
              initial: const ClientProfile(displayName: 'Ana'),
            ),
          ),
        ],
      ),
    );

    test('saving refreshes the profile', () async {
      expect(
        (await container.read(clientProfileProvider.future)).displayName,
        'Ana',
      );
      const next = ClientProfile(
        displayName: 'Ana Rojas',
        phone: '3001234567',
        email: 'ana@mano.co',
      );
      final result = await container
          .read(clientProfileActionsProvider.notifier)
          .save(next);
      expect(result.isOk, isTrue);
      expect(await container.read(clientProfileProvider.future), next);
    });

    test('a new photo refreshes the profile', () async {
      await container
          .read(clientProfileActionsProvider.notifier)
          .setPhoto('https://cdn/a.png');
      expect(
        (await container.read(clientProfileProvider.future)).photoUrl,
        'https://cdn/a.png',
      );
    });
  });

  group('address book', () {
    test('actions refresh the list and the default', () async {
      final container = ProviderContainer.test();
      final actions = container.read(addressBookActionsProvider.notifier);
      expect(await container.read(defaultAddressProvider.future), isNull);

      await actions.add(_casa);
      final trabajo = (await actions.add(_trabajo)).valueOrNull!;
      expect(
        (await container.read(defaultAddressProvider.future))?.label,
        'Casa',
      );

      await actions.setDefault(trabajo.id);
      expect(
        (await container.read(defaultAddressProvider.future))?.label,
        'Trabajo',
      );

      await actions.update(trabajo.copyWith(label: 'Oficina'));
      await actions.remove(
        (await container.read(savedAddressesProvider.future)).last.id,
      );
      final list = await container.read(savedAddressesProvider.future);
      expect(list.single.label, 'Oficina');
    });

    test('the book outlives the screens that read it', () async {
      final container = ProviderContainer.test();
      final first = container.read(addressBookProvider);
      expect(container.read(addressBookProvider), same(first));
    });
  });

  group('payment methods', () {
    test('actions refresh the list', () async {
      final container = ProviderContainer.test(
        overrides: [
          paymentMethodsProvider.overrideWithValue(
            MockPaymentMethods(now: () => DateTime(2026, 11, 2)),
          ),
        ],
      );
      final actions = container.read(paymentMethodActionsProvider.notifier);
      expect(await container.read(savedPaymentMethodsProvider.future), isEmpty);

      final card = (await actions.add(
        const NewCard(number: '4242424242424242', expiry: '12/28'),
      )).valueOrNull!;
      final nequi = (await actions.add(const NewNequi(phone: '3001234567')))
          .valueOrNull!;
      await actions.setDefault(nequi.id);
      expect(
        (await container.read(savedPaymentMethodsProvider.future)).first.id,
        nequi.id,
      );
      await actions.remove(card.id);
      expect(
        await container.read(savedPaymentMethodsProvider.future),
        hasLength(1),
      );
    });
  });

  group('notification preferences', () {
    test('start on and toggle locally', () {
      final container = ProviderContainer.test();
      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.jobUpdates, isTrue);
      expect(prefs.messages, isTrue);
      expect(prefs.promotions, isFalse);

      container
          .read(notificationPreferencesProvider.notifier)
          .setPromotions(true);
      container
          .read(notificationPreferencesProvider.notifier)
          .setJobUpdates(false);
      final next = container.read(notificationPreferencesProvider);
      expect(next.promotions, isTrue);
      expect(next.jobUpdates, isFalse);
    });
  });
}
