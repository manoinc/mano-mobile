import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_provider/features/home/home_labels.dart';
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
  group('greetingName', () {
    AuthenticatedUser user({String? username, String? email}) =>
        AuthenticatedUser(
          subject: 'sub-1',
          username: username,
          email: email,
          roles: const {},
        );

    test('uses a real name', () {
      expect(greetingName(user(username: 'Andrés')), 'Andrés');
    });

    test('is null for no user, blanks, the bare subject and placeholders', () {
      expect(greetingName(null), isNull);
      expect(greetingName(user(username: '  ')), isNull);
      expect(greetingName(user()), isNull);
      expect(greetingName(user(username: 'Profesional')), isNull);
      expect(greetingName(user(username: 'solicitante')), isNull);
    });
  });

  testWidgets('greets a user who has a name', (tester) async {
    await _pump(tester, session: _sessionFor(username: 'Andrés'));
    expect(find.text('Hola, Andrés'), findsOneWidget);
  });

  testWidgets('greets by the profile first name when the user has none', (
    tester,
  ) async {
    await _pump(tester, session: _sessionFor(username: 'Profesional'));
    expect(find.text('Hola, Andrés'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ManoGreetingHeader),
        matching: find.byType(ManoAvatar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a plain title when no name is available at all', (
    tester,
  ) async {
    await _pump(
      tester,
      session: _sessionFor(username: 'Profesional'),
      overrides: [
        providerProfileRepositoryProvider.overrideWithValue(
          _NamelessProfiles(),
        ),
      ],
    );
    expect(find.text('Inicio'), findsWidgets);
    expect(find.byType(ManoGreetingHeader), findsNothing);
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

class _NamelessProfiles implements ProviderProfileRepository {
  @override
  Future<ProviderProfile> profile() async => const ProviderProfile(
    party: Party(id: 'p', displayName: ' ', photoUrl: ''),
    bio: '',
    zones: [],
    yearsExperience: 0,
    verified: false,
  );

  @override
  Future<ProviderStats> stats() => throw UnimplementedError();

  @override
  Future<List<Review>> reviews() => throw UnimplementedError();

  @override
  Future<ReferralProgram> referral() => throw UnimplementedError();
}
