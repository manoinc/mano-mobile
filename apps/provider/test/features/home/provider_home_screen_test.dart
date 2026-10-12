import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';
import '../agenda/agenda_fakes.dart';

Session _sessionFor({String? username, String? email}) => Session(
  user: AuthenticatedUser(
    subject: 'user-1',
    username: username,
    email: email,
    roles: const {ManoRole.provider},
  ),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Session? session,
  List<Override> overrides = const [],
}) => pumpRouterAt(
  tester,
  '/home',
  session: FakeSessionRepository(
    onRestore: () async => Ok(session ?? fakeSession()),
  ),
  overrides: overrides,
);

void main() {
  testWidgets('greets a user who has a name', (tester) async {
    await _pump(tester, session: _sessionFor(username: 'Andrés'));
    expect(find.text('Hola, Andrés'), findsOneWidget);
  });

  testWidgets('shows a plain title when there is no usable name', (
    tester,
  ) async {
    await _pump(tester, session: _sessionFor(username: 'Profesional'));
    expect(find.text('Inicio'), findsWidgets);
    expect(find.byType(ManoGreetingHeader), findsNothing);
    expect(find.textContaining('Hola'), findsNothing);
  });

  testWidgets('shows the next job and opens it', (tester) async {
    final c = await _pump(tester);
    expect(find.text('Próximo trabajo'), findsOneWidget);
    final card = find.byKey(const Key('home-next-job'));
    expect(card, findsOneWidget);
    expect(tester.widget<ManoProjectCard>(card).title, isNotEmpty);

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(routerPath(c), '/agenda/job/job-1');
  });

  testWidgets('hides the next-job card when nothing is scheduled', (
    tester,
  ) async {
    await _pump(tester, overrides: emptyAgenda());
    expect(find.text('Próximo trabajo'), findsNothing);
    expect(find.text('Solicitudes'), findsWidgets);
  });
}
