import 'package:mano_session/mano_session.dart';

// The shared scriptable repository; the old name keeps the tests readable.
typedef FakeSessionRepository = InMemorySessionRepository;

Session fakeSession() => Session(
  user: const AuthenticatedUser(
    subject: 'user-1',
    username: 'mano-test',
    roles: {ManoRole.requester},
  ),
  accessToken: 'access-1',
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);
