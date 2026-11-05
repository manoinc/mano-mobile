import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_billing.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';
import 'projects_fakes.dart';

// The catalog is always the gateway; offline tests stand a fake in for it.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  String location, {
  List<Override> overrides = const [],
  SessionRepository? session,
}) => pumpRouterAt(
  tester,
  location,
  session: session,
  overrides: [
    serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
    ...overrides,
  ],
);

Future<void> _segment(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(ManoProjectFilterTabs).first,
    matching: find.text(label),
  );
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Finder _lead(String id) => find.byKey(Key('lead-card-$id'));

Future<void> _show(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Inicio splits into Solicitudes, Proyectos and Mis cotizaciones',
    (tester) async {
      await _pump(tester, '/home', session: signedIn());

      for (final label in ['Solicitudes', 'Proyectos', 'Mis cotizaciones']) {
        expect(
          find.descendant(
            of: find.byType(ManoProjectFilterTabs).first,
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(find.byType(ManoRequestCard), findsWidgets);
    },
  );

  testWidgets('Proyectos lists open projects, each one free to quote', (
    tester,
  ) async {
    await _pump(tester, '/home', session: signedIn());
    await _segment(tester, 'Proyectos');

    await _show(tester, _lead('project-1'));
    final card = tester.widget<ManoLeadCard>(_lead('project-1'));
    expect(card.title, 'Pintar apartamento de 70 m²');
    expect(card.categoryLabel, 'Pintura');
    expect(card.budgetLabel, r'Presupuesto $1.800.000');
    expect(card.costLabel, 'Gratis');
    // Projects that stopped taking quotes are not on the board.
    expect(_lead('project-3'), findsNothing);
  });

  testWidgets('a category chip narrows the board', (tester) async {
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [
        providerCategoriesProvider.overrideWith(
          (ref) async => [ServiceCategories.plumbing],
        ),
      ],
    );
    await _segment(tester, 'Proyectos');

    final plumbing = find.descendant(
      of: find.byType(ManoProjectFilterTabs).last,
      matching: find.text('Plomería'),
    );
    await tester.ensureVisible(plumbing);
    await tester.tap(plumbing);
    await tester.pumpAndSettle();

    await _show(tester, _lead('project-6'));
    expect(_lead('project-1'), findsNothing);
  });

  testWidgets('a lead opens its project', (tester) async {
    final c = await _pump(tester, '/home', session: signedIn());
    await _segment(tester, 'Proyectos');
    await _show(tester, _lead('project-5'));

    await tester.tap(_lead('project-5'));
    await tester.pumpAndSettle();

    expect(routerPath(c), '/home/project/project-5');
  });

  testWidgets('no open projects says so', (tester) async {
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [leadRepositoryProvider.overrideWithValue(FakeLeads())],
    );
    await _segment(tester, 'Proyectos');

    expect(find.text('No hay proyectos abiertos por ahora.'), findsOneWidget);
  });

  testWidgets('a failed board offers a retry', (tester) async {
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(FakeLeads(fails: true)),
      ],
    );
    await _segment(tester, 'Proyectos');

    expect(find.text('No pudimos cargar los proyectos.'), findsOneWidget);
  });

  testWidgets('Mis cotizaciones labels each quote by its status', (
    tester,
  ) async {
    await _pump(tester, '/home', session: signedIn());
    await _segment(tester, 'Mis cotizaciones');

    final sent = find.byKey(const Key('my-quote-quote-1'));
    await _show(tester, sent);
    final sentCard = tester.widget<ManoProjectSummaryCard>(sent);
    expect(sentCard.statusLabel, 'Enviada');
    expect(sentCard.subtitle, r'Tu cotización $1.650.000');

    final chosen = find.byKey(const Key('my-quote-quote-4'));
    await _show(tester, chosen);
    final chosenCard = tester.widget<ManoProjectSummaryCard>(chosen);
    expect(chosenCard.statusLabel, 'Elegida');
    expect(
      chosenCard.subtitle,
      startsWith('El cliente te elegió. Compra su contacto por'),
    );
  });

  testWidgets('a chosen quote buys its lead and unlocks the contact', (
    tester,
  ) async {
    await _pump(tester, '/home', session: signedIn());
    await _segment(tester, 'Mis cotizaciones');
    final chosen = find.byKey(const Key('my-quote-quote-4'));
    await _show(tester, chosen);

    await tester.tap(chosen);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lead-purchase-sheet')), findsOneWidget);
    await tester.tap(find.textContaining('Comprar ·'));
    await tester.pumpAndSettle();

    expect(find.text('Contacto desbloqueado'), findsOneWidget);
    await _show(tester, chosen);
    expect(
      tester.widget<ManoProjectSummaryCard>(chosen).subtitle,
      'Contacto desbloqueado. Escríbele al cliente.',
    );
  });

  testWidgets('without enough coins the lead leads to recharging', (
    tester,
  ) async {
    final quote = Quote(
      id: 'quote-x',
      projectId: 'project-x',
      projectTitle: 'Pintar la fachada',
      worker: const Party(id: 'w', displayName: 'Ana', photoUrl: ''),
      amountCop: 900000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
      projectCategory: ServiceCategories.painting,
    );
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(
          FakeLeads(
            quotes: [quote],
            purchaseRefusal: const InsufficientCoins(),
          ),
        ),
        walletRepositoryProvider.overrideWithValue(
          ScriptedWallet(
            balance: 1,
            reply: const Ok(AwaitingApproval(paymentId: 'p', coins: 12)),
          ),
        ),
      ],
    );
    await _segment(tester, 'Mis cotizaciones');
    final card = find.byKey(const Key('my-quote-quote-x'));
    await _show(tester, card);

    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar · 4 coins'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insufficient-coins-sheet')), findsOneWidget);
    expect(find.text('Te faltan 3 coins'), findsOneWidget);
    await tester.tap(find.text('Recargar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recharge-sheet')), findsOneWidget);
  });

  testWidgets('a refused lead purchase says so in plain words', (tester) async {
    final quote = Quote(
      id: 'quote-y',
      projectId: 'project-y',
      projectTitle: 'Pintar la reja',
      worker: const Party(id: 'w', displayName: 'Ana', photoUrl: ''),
      amountCop: 300000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
      projectCategory: ServiceCategories.painting,
    );
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(
          FakeLeads(
            quotes: [quote],
            purchaseRefusal: const DataRejected(
              reason: 'FailedPrecondition: only the selected worker can buy',
            ),
          ),
        ),
      ],
    );
    await _segment(tester, 'Mis cotizaciones');
    final card = find.byKey(const Key('my-quote-quote-y'));
    await _show(tester, card);

    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comprar · 4 coins'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('insufficient-coins-sheet')), findsNothing);
    expect(find.text(const DataRejected().message), findsOneWidget);
  });

  testWidgets('no quotes yet points at the open projects', (tester) async {
    await _pump(
      tester,
      '/home',
      session: signedIn(),
      overrides: [leadRepositoryProvider.overrideWithValue(FakeLeads())],
    );
    await _segment(tester, 'Mis cotizaciones');

    expect(find.text('Aún no has enviado cotizaciones.'), findsOneWidget);
    await tester.tap(find.text('Ver proyectos'));
    await tester.pumpAndSettle();
    expect(find.text('No hay proyectos abiertos por ahora.'), findsOneWidget);
  });
}
