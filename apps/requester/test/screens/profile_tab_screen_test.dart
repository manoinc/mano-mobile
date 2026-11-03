import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/fake_session_repository.dart';
import '../support/pump_app.dart';

Future<(ProviderContainer, InMemorySessionRepository)> _signedIn(
  WidgetTester tester,
) async {
  final repository = FakeSessionRepository(
    onRestore: () async => Ok(fakeSession()),
  );
  final container = await pumpRouterAt(tester, '/profile', session: repository);
  return (container, repository);
}

void main() {
  testWidgets('renders the signed-in user\'s name in the header', (
    tester,
  ) async {
    await _signedIn(tester);

    expect(find.text('mano-test'), findsOneWidget);
  });

  testWidgets('renders every menu label and Cerrar sesión', (tester) async {
    await _signedIn(tester);

    for (final label in [
      'Información personal',
      'Direcciones guardadas',
      'Métodos de pago',
      'Historial de pedidos',
      'Atención al cliente',
      'Configuración',
      'Cerrar sesión',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  for (final (label, path) in [
    ('Información personal', '/profile/personal'),
    ('Direcciones guardadas', '/profile/addresses'),
    ('Métodos de pago', '/profile/payments'),
    ('Historial de pedidos', '/profile/history'),
    ('Atención al cliente', '/profile/support'),
    ('Configuración', '/profile/settings'),
  ]) {
    testWidgets('$label opens $path', (tester) async {
      final (container, _) = await _signedIn(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(routerPath(container), path);
      expect(find.text('Muy pronto'), findsNothing);
    });
  }

  testWidgets('the header edit button opens Información personal', (
    tester,
  ) async {
    final (container, _) = await _signedIn(tester);

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();

    expect(routerPath(container), '/profile/personal');
  });

  testWidgets('tapping Cerrar sesión signs out', (tester) async {
    final (_, repository) = await _signedIn(tester);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
  });

  testWidgets(
    'does not fetch a network photo for the header until one is uploaded',
    (tester) async {
      await _signedIn(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.person), findsOneWidget);
    },
  );

  testWidgets('a guest is asked for an account before personal data', (
    tester,
  ) async {
    final container = await pumpRouterAt(tester, '/profile');
    container.read(sessionProvider.notifier).browseAsGuest();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Información personal'));
    await tester.pumpAndSettle();

    expect(find.byType(ManoAccountNeededSheet), findsOneWidget);
    expect(routerPath(container), '/profile');
  });
}
