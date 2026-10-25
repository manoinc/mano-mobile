import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _offline() => ProviderContainer.test(
  overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
);

void main() {
  test('the projects ports read from the gateway by default', () {
    final c = ProviderContainer.test(
      overrides: [
        manoConfigProvider.overrideWithValue(
          const ManoConfig(
            gatewayGraphQlUrl: 'http://gw/graphql',
            appRole: ManoRole.requester,
          ),
        ),
      ],
    );
    expect(c.read(projectRepositoryProvider), isA<GatewayProjectRepository>());
    expect(c.read(leadRepositoryProvider), isA<GatewayLeadRepository>());
  });

  test('offline, both ports share one mock board', () async {
    final c = _offline();
    expect(c.read(projectRepositoryProvider), isA<MockProjectRepository>());
    expect(c.read(leadRepositoryProvider), isA<MockLeadRepository>());

    final published =
        (await c
                .read(projectRepositoryProvider)
                .publish(
                  const ProjectDraft(
                    category: ServiceCategories.cleaning,
                    title: 'Aseo',
                    description: 'Casa',
                  ),
                ))
            .valueOrNull!;

    expect(
      (await c.read(leadRepositoryProvider).openProjects()).map((p) => p.id),
      contains(published.id),
    );
  });

  test(
    'reads list my projects, open projects by category and my quotes',
    () async {
      final c = _offline();

      expect(await c.read(myProjectsProvider.future), isNotEmpty);
      final plumbing = await c.read(
        openProjectsProvider(ServiceCategories.plumbing).future,
      );
      expect(plumbing, isNotEmpty);
      expect(
        plumbing.every((p) => p.category == ServiceCategories.plumbing),
        isTrue,
      );
      expect(
        (await c.read(openProjectsProvider(null).future)).length,
        greaterThan(plumbing.length),
      );
      expect(await c.read(myQuotesProvider.future), isNotEmpty);
    },
  );
}
