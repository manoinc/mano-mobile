import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

const _config = ManoConfig(
  gatewayGraphQlUrl: 'http://gw/graphql',
  appRole: ManoRole.requester,
);

ProviderContainer _container({bool offline = false}) => ProviderContainer.test(
  overrides: [
    manoConfigProvider.overrideWithValue(_config),
    offlineMarketplaceProvider.overrideWithValue(offline),
  ],
);

void main() {
  test('the support desk reads from the live gateway', () {
    expect(_container().read(supportDeskProvider), isA<GatewaySupportDesk>());
  });

  test('offline it is the in-memory desk, with tickets and threads', () async {
    final c = _container(offline: true);
    final desk = c.read(supportDeskProvider);
    expect(desk, isA<MockSupportDesk>());

    final ticket = (await desk.submit(
      const SupportTicketDraft(subject: 'Ayuda', description: 'Hola'),
    )).valueOrNull!;
    await desk.send(ticket.id, 'Más datos');

    expect(await c.read(myTicketsProvider.future), [ticket]);
    final thread = await c.read(supportThreadProvider(ticket.id).future);
    expect(thread.single.body, 'Más datos');
  });

  test('a failed read surfaces as an error state', () async {
    final c = _container(offline: true);
    await expectLater(
      c.read(supportThreadProvider('missing').future),
      throwsA(isA<StateError>()),
    );
  });
}
