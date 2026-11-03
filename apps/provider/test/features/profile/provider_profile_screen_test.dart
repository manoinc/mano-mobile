import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../services/services_fakes.dart';

final _overrides = [
  serviceCatalogProvider.overrideWithValue(FakeServiceCatalog()),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String path = '/profile',
  SessionRepository? session,
}) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = await pumpRouterAt(
    tester,
    path,
    overrides: _overrides,
    session: session,
  );
  return container;
}

Future<void> _scrollTo(WidgetTester tester, String text) =>
    tester.scrollUntilVisible(
      find.text(text),
      400,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

// Clear of the bottom bar, which floats over the list's last rows.
Future<void> _centre(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.drag(find.byType(ListView).first, const Offset(0, -300));
  await tester.pumpAndSettle();
}

void main() {
  group('the session row', () {
    testWidgets('signed in, Cerrar sesión signs out', (tester) async {
      final session = FakeSessionRepository(
        onRestore: () async => Ok(fakeSession()),
      );
      final container = await _pump(tester, session: session);
      await container.read(sessionProvider.future);
      await tester.pumpAndSettle();

      await _scrollTo(tester, 'Cerrar sesión');
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(session.signOutCalls, 1);
      expect(container.read(sessionProvider).value, isA<SignedOut>());
    });

    testWidgets('a guest gets Iniciar sesión, back to the door', (
      tester,
    ) async {
      final container = await _pump(tester);
      container.read(sessionProvider.notifier).browseAsGuest();
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsNothing);
      await _scrollTo(tester, 'Iniciar sesión');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider).value, isA<SignedOut>());
    });
  });

  testWidgets('shows the tasker, the week total and the chart', (tester) async {
    await _pump(tester);
    expect(find.text('Andrés Castro'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsWidgets);
    expect(find.text('\$765.000'), findsOneWidget);
    expect(find.textContaining('Próximo pago'), findsOneWidget);
    expect(find.byType(ManoBarChart), findsOneWidget);
  });

  testWidgets('switching to Este mes changes the total', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Este mes'));
    await tester.pumpAndSettle();
    expect(find.text('\$2.650.000'), findsOneWidget);
  });

  testWidgets('shows the stats grid', (tester) async {
    await _pump(tester);
    expect(find.text('4,9'), findsOneWidget);
    expect(find.text('118'), findsOneWidget);
    expect(find.text('96 %'), findsOneWidget);
    expect(find.text('98 %'), findsOneWidget);
  });

  testWidgets('shows latest reviews and links to all', (tester) async {
    await _pump(tester);
    expect(find.byType(ManoReviewTile), findsNWidgets(2));
    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoReviewTile), findsNWidgets(4));
  });

  testWidgets('the earnings section opens the breakdown', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ver desglose'));
    await tester.pumpAndSettle();
    expect(find.text('Trabajos pagados'), findsOneWidget);
    expect(find.textContaining('Laura Pérez'), findsWidgets);
  });

  testWidgets('the services row leads to Mis servicios', (tester) async {
    final c = await _pump(tester);
    await tester.ensureVisible(find.text('Tus servicios y habilidades'));
    await tester.tap(find.text('Tus servicios y habilidades'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/profile/services');
  });

  testWidgets('Ver perfil público opens the public preview', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ver perfil público'));
    await tester.pumpAndSettle();
    expect(find.byType(ManoProfileSheet), findsOneWidget);
  });

  testWidgets('the referral card opens a sheet that copies the code', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester);
    await _centre(tester, find.byType(ManoReferralCard));
    await tester.tap(find.byType(ManoReferralCard));
    await tester.pumpAndSettle();
    expect(find.text('ANDRES-M4N0'), findsOneWidget);
    expect(find.text('2 de 5 invitados'), findsWidgets);

    await tester.tap(find.text('Copiar código'));
    await tester.pumpAndSettle();
    expect(copied, 'ANDRES-M4N0');
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('the referral sheet links to Billetera', (tester) async {
    final c = await _pump(tester);
    await _centre(tester, find.byType(ManoReferralCard));
    await tester.tap(find.byType(ManoReferralCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mi Billetera'));
    await tester.pumpAndSettle();
    expect(routerPath(c), '/wallet');
  });
}
