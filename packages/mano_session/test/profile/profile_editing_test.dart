import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  late ProviderContainer container;

  setUp(
    () => container = ProviderContainer.test(
      overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
    ),
  );

  test('a saved profile is what Perfil reads next', () async {
    final before = await container.read(providerProfileProvider.future);
    final draft = ProviderProfileDraft.from(before)
        .copyWith(displayName: 'Andrés C.', bio: 'Nuevo');

    final result = await container
        .read(providerProfileActionsProvider.notifier)
        .save(draft);

    expect(result.isOk, isTrue);
    final after = await container.read(providerProfileProvider.future);
    expect(after.party.displayName, 'Andrés C.');
    expect(after.bio, 'Nuevo');
  });

  test('a refused save leaves the profile alone', () async {
    final before = await container.read(providerProfileProvider.future);
    final result = await container
        .read(providerProfileActionsProvider.notifier)
        .save(ProviderProfileDraft.from(before).copyWith(skills: []));

    expect(result.failureOrNull, isA<DataRejected>());
    expect(
      (await container.read(providerProfileProvider.future)).skills,
      before.skills,
    );
  });
}
