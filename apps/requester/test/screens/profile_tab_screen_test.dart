import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../support/fake_session_repository.dart';
import '../support/pump_app.dart';

Future<(ProviderContainer, InMemorySessionRepository)> _signedIn(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  final repository = FakeSessionRepository(
    onRestore: () async => Ok(fakeSession()),
  );
  final container = await pumpRouterAt(
    tester,
    '/profile',
    session: repository,
    overrides: overrides,
  );
  return (container, repository);
}

/// A served profile with contact details.
final class _ServedProfile implements ClientProfileRepository {
  @override
  Future<ClientProfile> profile() async => const ClientProfile(
    displayName: 'Ana Rojas',
    phone: '3001234567',
    email: 'ana@mano.co',
  );

  @override
  Future<Result<ClientProfile, DataFailure>> update(ClientProfile p) async =>
      Ok(p);

  @override
  Future<Result<ClientProfile, DataFailure>> updatePhoto(
    MediaAttachment photo,
  ) async => Ok(await profile());
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

  testWidgets('the header shows the contact details under the name', (
    tester,
  ) async {
    await _signedIn(
      tester,
      overrides: [
        clientProfileRepositoryProvider.overrideWithValue(_ServedProfile()),
      ],
    );

    expect(find.text('Ana Rojas'), findsOneWidget);
    expect(find.text('ana@mano.co · 3001234567'), findsOneWidget);
  });

  group('¿Tienes un código?', () {
    Future<void> enter(WidgetTester tester, String code) async {
      await tester.tap(find.text('¿Tienes un código?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('Guardar profesional'));
      await tester.pumpAndSettle();
    }

    testWidgets('a known code saves the professional and says who', (
      tester,
    ) async {
      await _signedIn(tester);

      await enter(tester, 'MANO-CARLOS');

      expect(find.byType(ManoPromptSheet), findsNothing);
      expect(
        find.text('Guardamos a Carlos Mendoza en tus profesionales.'),
        findsOneWidget,
      );
    });

    testWidgets('an unknown code keeps the sheet open and says so', (
      tester,
    ) async {
      await _signedIn(tester);

      await enter(tester, 'NOPE');

      expect(find.byType(ManoPromptSheet), findsOneWidget);
      expect(
        find.text('Ese código no existe. Revísalo e intenta de nuevo.'),
        findsOneWidget,
      );
    });
  });
}
