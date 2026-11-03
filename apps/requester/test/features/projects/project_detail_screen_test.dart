import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/projects/project_detail_screen.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/pump_app.dart';
import 'projects_fakes.dart';

List<String> _quoteNames(WidgetTester tester) => [
  for (final card in tester.widgetList<ManoQuoteCard>(
    find.byType(ManoQuoteCard),
  ))
    card.name,
];

ManoQuoteCard _quote(WidgetTester tester, String id) =>
    tester.widget<ManoQuoteCard>(find.byKey(Key('quote-$id')));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the project and its quotes, cheapest first', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects/project/project-1');

    expect(find.byType(ProjectDetailScreen), findsOneWidget);
    expect(find.text('Pintar apartamento de 70 m²'), findsOneWidget);
    expect(find.text(r'$1.800.000'), findsOneWidget);
    expect(find.text('Cotizaciones (3)'), findsOneWidget);
    expect(_quoteNames(tester), ['Jorge Peña', 'Andrés Castro', 'Ana Gómez']);
  });

  testWidgets('the project photos show and open full screen', (tester) async {
    await pumpRouterAt(tester, '/projects/project/project-1');

    expect(find.byType(ManoPhotoGallery), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('Ver foto 1'));
    expect(find.byType(ManoImageViewer), findsOneWidget);
  });

  testWidgets('the sort toggles to the newest first', (tester) async {
    await pumpRouterAt(tester, '/projects/project/project-1');

    await _tap(tester, find.text('Menor precio'));

    expect(find.text('Más recientes'), findsOneWidget);
    expect(_quoteNames(tester), ['Jorge Peña', 'Ana Gómez', 'Andrés Castro']);
  });

  testWidgets('choosing a quote confirms, then pins it as Elegida', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/projects/project/project-1',
      session: signedIn(),
    );

    await _tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('quote-quote-1')),
        matching: find.text('Elegir'),
      ),
    );
    expect(
      find.text(r'¿Elegir a Andrés Castro por $1.650.000?'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Elegir cotización'));

    expect(_quoteNames(tester).first, 'Andrés Castro');
    expect(_quote(tester, 'quote-1').statusLabel, 'Elegida');
    expect(_quote(tester, 'quote-1').onSelect, isNull);
  });

  testWidgets('a discarded quote folds away under Descartadas', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects/project/project-1',
      session: signedIn(),
    );

    await _tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('quote-quote-3')),
        matching: find.text('Descartar'),
      ),
    );

    expect(find.byKey(const Key('quote-quote-3')), findsNothing);
    await _tap(tester, find.text('Descartadas (1)'));
    expect(find.byKey(const Key('quote-quote-3')), findsOneWidget);
  });

  testWidgets('a guest is asked to sign in before choosing', (tester) async {
    await pumpRouterAt(tester, '/projects/project/project-1');

    await _tap(
      tester,
      find.descendant(
        of: find.byKey(const Key('quote-quote-1')),
        matching: find.text('Elegir'),
      ),
    );

    expect(find.text('Necesitas una cuenta'), findsOneWidget);
  });

  testWidgets('cancelling from the menu asks first, then marks it Cancelado', (
    tester,
  ) async {
    await pumpRouterAt(
      tester,
      '/projects/project/project-2',
      session: signedIn(),
    );

    await _tap(tester, find.byTooltip('Más opciones'));
    await _tap(tester, find.text('Cancelar proyecto'));
    expect(find.text('¿Cancelar este proyecto?'), findsOneWidget);
    await _tap(tester, find.text('Sí, cancelar'));

    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.byTooltip('Más opciones'), findsNothing);
  });

  testWidgets('a cancelled project offers no menu and no actions', (
    tester,
  ) async {
    await pumpRouterAt(tester, '/projects/project/project-4');

    expect(find.byTooltip('Más opciones'), findsNothing);
    expect(find.text('Aún no hay cotizaciones.'), findsOneWidget);
  });

  testWidgets('an unknown project says so', (tester) async {
    await pumpRouterAt(tester, '/projects/project/nope');

    expect(find.text('No encontramos este proyecto.'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    await pumpRouterAt(
      tester,
      '/projects/project/project-1',
      overrides: [
        projectRepositoryProvider.overrideWithValue(FakeProjects(fails: true)),
      ],
    );

    expect(find.text('No pudimos cargar este proyecto.'), findsOneWidget);
  });

  testWidgets('the last quote clears the system navigation bar', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(bottom: 48)
      ..viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);
    await pumpRouterAt(tester, '/projects/project/project-1');

    await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(ManoQuoteCard).last).bottom,
      lessThanOrEqualTo(640 - 48),
    );
  });
}
