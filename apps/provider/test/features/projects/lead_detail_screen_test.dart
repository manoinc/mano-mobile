import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/projects/lead_detail_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_billing.dart';
import '../../support/pump_app.dart';
import 'projects_fakes.dart';

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _quote(WidgetTester tester, List<String> keys) async {
  await _tap(tester, find.text('Cotizar gratis'));
  for (final key in keys) {
    await tester.ensureVisible(find.text(key));
    await tester.tap(find.text(key));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the project and offers to quote for free', (tester) async {
    await pumpRouterAt(tester, '/home/project/project-5', session: signedIn());

    expect(find.byType(LeadDetailScreen), findsOneWidget);
    expect(find.text('Limpieza final de obra'), findsOneWidget);
    expect(find.text(r'$450.000'), findsOneWidget);
    expect(find.text('Cotizar gratis'), findsOneWidget);
  });

  testWidgets('the client photos show when there are any', (tester) async {
    await pumpRouterAt(tester, '/home/project/project-5', session: signedIn());
    expect(find.byType(ManoPhotoGallery), findsOneWidget);

    await pumpRouterAt(tester, '/home/project/project-6', session: signedIn());
    expect(find.byType(ManoPhotoGallery), findsNothing);
  });

  testWidgets('sending a quote turns the action into "Ya cotizaste"', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/home/project/project-5', session: signedIn());

    await _quote(tester, ['4', '2', '000', '0']);
    expect(find.text(r'$420.000'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Incluye materiales.');
    await _tap(tester, find.text('Enviar cotización'));

    expect(find.text('Cotización enviada'), findsOneWidget);
    expect(find.text(r'Ya cotizaste · $420.000'), findsOneWidget);
    expect(find.text('Cotizar gratis'), findsNothing);
  });

  testWidgets('Enviar waits for an amount', (tester) async {
    await pumpRouterAt(tester, '/home/project/project-5', session: signedIn());
    await _tap(tester, find.text('Cotizar gratis'));

    final send = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Enviar cotización'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(send.enabled, isFalse);
  });

  testWidgets('an already quoted project never offers the button', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/home/project/project-1', session: signedIn());

    expect(find.text(r'Ya cotizaste · $1.650.000'), findsOneWidget);
    expect(find.text('Cotizar gratis'), findsNothing);
  });

  testWidgets('a second quote is refused as already quoted', (tester) async {
    await pumpRouterAt(
      tester,
      '/home/project/project-9',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(
          FakeLeads(
            open: [openProject()],
            refusal: const DataRejected(reason: 'AlreadyExists: one quote'),
          ),
        ),
      ],
    );

    await _quote(tester, ['9']);
    await _tap(tester, find.text('Enviar cotización'));

    expect(find.text('Ya cotizaste este proyecto'), findsOneWidget);
  });

  testWidgets('a project that closed meanwhile says so', (tester) async {
    await pumpRouterAt(
      tester,
      '/home/project/project-9',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(
          FakeLeads(
            open: [openProject()],
            refusal: const DataRejected(reason: 'FailedPrecondition: closed'),
          ),
        ),
      ],
    );

    await _quote(tester, ['9']);
    await _tap(tester, find.text('Enviar cotización'));

    expect(
      find.text('Este proyecto ya no recibe cotizaciones'),
      findsOneWidget,
    );
  });

  testWidgets('a guest is asked to sign in before quoting', (tester) async {
    await pumpRouterAt(tester, '/home/project/project-5');

    await _tap(tester, find.text('Cotizar gratis'));

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });

  testWidgets('a project no longer on the board says so', (tester) async {
    await pumpRouterAt(
      tester,
      '/home/project/project-3',
      session: signedIn(),
      overrides: [leadRepositoryProvider.overrideWithValue(FakeLeads())],
    );

    expect(
      find.text('Este proyecto ya no recibe cotizaciones.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load offers a retry', (tester) async {
    await pumpRouterAt(
      tester,
      '/home/project/project-5',
      session: signedIn(),
      overrides: [
        leadRepositoryProvider.overrideWithValue(FakeLeads(fails: true)),
      ],
    );

    expect(find.text('No pudimos cargar este proyecto.'), findsOneWidget);
  });

  group('a project already awarded', () {
    final chosen = Quote(
      id: 'quote-z',
      projectId: 'project-z',
      projectTitle: 'Cambiar la iluminación',
      worker: const Party(id: 'w', displayName: 'Ana', photoUrl: ''),
      amountCop: 580000,
      status: QuoteStatus.selected,
      createdAt: DateTime(2026, 11, 3),
      projectCategory: ServiceCategories.electrical,
    );

    Future<FakeLinks> pumpWith(WidgetTester tester, Quote quote) async {
      final links = FakeLinks();
      await pumpRouterAt(
        tester,
        '/home/project/project-z',
        session: signedIn(),
        overrides: [
          leadRepositoryProvider.overrideWithValue(FakeLeads(quotes: [quote])),
          externalLinkOpenerProvider.overrideWithValue(links.open),
        ],
      );
      return links;
    }

    testWidgets('a bought lead shows the contact and reaches the client', (
      tester,
    ) async {
      final links = await pumpWith(
        tester,
        chosen.copyWith(
          leadPurchased: true,
          clientContact: const ContactInfo(
            phone: '300 123 4567',
            email: 'laura@mano.test',
          ),
        ),
      );

      expect(find.text('Cambiar la iluminación'), findsOneWidget);
      expect(find.text('300 123 4567'), findsWidgets);
      expect(find.text('laura@mano.test'), findsOneWidget);
      await _tap(tester, find.text('Llamar'));
      await _tap(tester, find.text('Abrir'));
      await _tap(tester, find.text('Escribir'));
      expect(links.opened, [
        Uri.parse('tel:3001234567'),
        Uri.parse('https://wa.me/573001234567'),
        Uri.parse('mailto:laura@mano.test'),
      ]);
    });

    testWidgets('a chosen lead not yet bought offers to buy it', (
      tester,
    ) async {
      await pumpWith(tester, chosen);

      expect(find.text('Cambiar la iluminación'), findsOneWidget);
      expect(find.text('Llamar'), findsNothing);
      await _tap(tester, find.text('Comprar contacto'));
      expect(find.byKey(const Key('lead-purchase-sheet')), findsOneWidget);
    });
  });
}
