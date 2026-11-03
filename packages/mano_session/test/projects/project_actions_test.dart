import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

ProviderContainer _offline() => ProviderContainer.test(
  overrides: [offlineMarketplaceProvider.overrideWithValue(true)],
);

const _draft = ProjectDraft(
  category: ServiceCategories.painting,
  title: 'Pintar la fachada',
  description: 'Casa de dos pisos en Envigado.',
  budgetCop: 2000000,
);

void main() {
  group('ProjectActions', () {
    test(
      'publish adds the project to my projects and the open board',
      () async {
        final c = _offline();
        await c.read(myProjectsProvider.future);
        await c.read(openProjectsProvider(null).future);

        final result = await c
            .read(projectActionsProvider.notifier)
            .publish(_draft);

        final id = result.valueOrNull!.id;
        expect((await c.read(myProjectsProvider.future)).first.id, id);
        expect(
          (await c.read(openProjectsProvider(null).future)).map((p) => p.id),
          contains(id),
        );
      },
    );

    test('an invalid draft fails and refreshes nothing', () async {
      final c = _offline();
      var builds = 0;
      c.listen(myProjectsProvider, (_, _) => builds++);
      await c.read(myProjectsProvider.future);
      final before = builds;

      final result = await c
          .read(projectActionsProvider.notifier)
          .publish(const ProjectDraft());

      expect(result.failureOrNull, isA<DataRejected>());
      await c.read(myProjectsProvider.future);
      expect(builds, before);
    });

    test('cancel moves the project to cancelled', () async {
      final c = _offline();
      final open = (await c.read(myProjectsProvider.future))
          .firstWhere((p) => p.canCancel);

      await c.read(projectActionsProvider.notifier).cancel(open.id);

      expect(
        (await c.read(myProjectsProvider.future))
            .firstWhere((p) => p.id == open.id)
            .status,
        ProjectStatus.cancelled,
      );
    });

    test('select and discard refresh the project\'s quotes', () async {
      final c = _offline();
      final project = (await c.read(myProjectsProvider.future)).firstWhere(
        (p) => p.status == ProjectStatus.open && p.quotes!.length > 1,
      );
      final [first, second, ...] = project.quotes!;
      final actions = c.read(projectActionsProvider.notifier);

      await actions.selectQuote(first.id);
      await actions.discardQuote(second.id);

      final after = (await c.read(myProjectsProvider.future))
          .firstWhere((p) => p.id == project.id);
      expect(after.status, ProjectStatus.awarded);
      expect(after.quotes!.map((q) => q.status), [
        QuoteStatus.selected,
        QuoteStatus.discarded,
        ...project.quotes!.skip(2).map((q) => q.status),
      ]);
    });
  });

  group('LeadActions', () {
    test('submitQuote adds it to my quotes', () async {
      final c = _offline();
      final before = await c.read(myQuotesProvider.future);
      final fresh = (await c.read(openProjectsProvider(null).future))
          .firstWhere((p) => !before.any((q) => q.projectId == p.id));

      final result = await c
          .read(leadActionsProvider.notifier)
          .submitQuote(fresh.id, amountCop: 250000, message: 'Incluye todo');

      expect(result.isOk, isTrue);
      expect((await c.read(myQuotesProvider.future)).first.projectId, fresh.id);
    });

    test('a second quote is already quoted and refreshes nothing', () async {
      final c = _offline();
      final quoted = (await c.read(myQuotesProvider.future)).first;
      var builds = 0;
      c.listen(myQuotesProvider, (_, _) => builds++);
      await c.read(myQuotesProvider.future);
      final before = builds;

      final result = await c
          .read(leadActionsProvider.notifier)
          .submitQuote(quoted.projectId, amountCop: 1);

      expect(result.failureOrNull?.isAlreadyQuoted, isTrue);
      await c.read(myQuotesProvider.future);
      expect(builds, before);
    });

    test(
      'the selected quote\'s lead is bought; an unselected one is refused',
      () async {
        final c = _offline();
        final before = await c.read(myQuotesProvider.future);
        // Offline one board backs both apps: pick a project the mock requester owns.
        final owned = {
          for (final p in await c.read(myProjectsProvider.future)) p.id,
        };
        final fresh = (await c.read(openProjectsProvider(null).future))
            .firstWhere(
              (p) =>
                  owned.contains(p.id) &&
                  !before.any((q) => q.projectId == p.id),
            );
        final leads = c.read(leadActionsProvider.notifier);
        final quote = (await leads.submitQuote(
          fresh.id,
          amountCop: 250000,
        )).valueOrNull!;

        final refused = await leads.purchaseLead(quote.id);
        expect(refused.failureOrNull, isA<DataRejected>());

        final selected = await c
            .read(projectActionsProvider.notifier)
            .selectQuote(quote.id);
        expect(selected.isOk, isTrue);
        final bought = await leads.purchaseLead(quote.id);

        expect(bought.valueOrNull?.leadPurchased, isTrue);
        final mine = await c.read(myQuotesProvider.future);
        expect(mine.firstWhere((q) => q.id == quote.id).leadPurchased, isTrue);
      },
    );
  });
}
