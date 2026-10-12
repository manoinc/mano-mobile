import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/screens/profile_tab_screen.dart';
import 'package:mano_session/mano_session.dart';

const _user = AuthenticatedUser(
  subject: 'user-1',
  username: 'mano-test',
  roles: {ManoRole.requester},
);

Session _fakeSession() => Session(
  user: _user,
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

Future<InMemorySessionRepository> _host(WidgetTester tester) async {
  final repository = InMemorySessionRepository(
    onRestore: () async => Ok(_fakeSession()),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: const ProfileTabScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('renders the signed-in user\'s name in the header', (
    tester,
  ) async {
    await _host(tester);

    expect(find.text('mano-test'), findsOneWidget);
  });

  testWidgets('renders every non-destructive menu label', (tester) async {
    await _host(tester);

    expect(find.text('Información personal'), findsOneWidget);
    expect(find.text('Direcciones guardadas'), findsOneWidget);
    expect(find.text('Métodos de pago'), findsOneWidget);
    expect(find.text('Historial de pedidos'), findsOneWidget);
    expect(find.text('Atención al cliente'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
  });

  testWidgets('renders the Log Out row', (tester) async {
    await _host(tester);

    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('tapping a non-destructive row shows the stub notice', (
    tester,
  ) async {
    await _host(tester);

    await tester.tap(find.text('Información personal'));
    await tester.pumpAndSettle();

    expect(find.text('Muy pronto'), findsOneWidget);
  });

  testWidgets('tapping Log Out calls signOut on the repository, not a stub', (
    tester,
  ) async {
    final repository = await _host(tester);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Muy pronto'), findsNothing);
  });

  testWidgets(
    'does not fetch a network photo for the header -- no real photo exists yet, and inventing one from the subject would leak it',
    (tester) async {
      await _host(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.person), findsOneWidget);
    },
  );
}
