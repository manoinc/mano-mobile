import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

AuthenticatedUser _user({String? username, String? email}) => AuthenticatedUser(
  subject: 'sub-1',
  username: username,
  email: email,
  roles: const {},
);

void main() {
  group('greetingName', () {
    test('uses a real name', () {
      expect(greetingName(_user(username: 'Andrés')), 'Andrés');
    });

    test('is null for no user, blanks, the bare subject and placeholders', () {
      expect(greetingName(null), isNull);
      expect(greetingName(_user(username: '  ')), isNull);
      expect(greetingName(_user()), isNull);
      expect(greetingName(_user(username: 'Profesional')), isNull);
      expect(greetingName(_user(username: 'solicitante')), isNull);
    });
  });

  test('the onboarding name outranks the profile, not the account', () {
    expect(resolveGreetingName(null, null, onboardingName: 'Lucía'), 'Lucía');
    expect(
      resolveGreetingName(
        _user(username: 'Andrés'),
        null,
        onboardingName: 'Lucía',
      ),
      'Andrés',
    );
    expect(resolveGreetingName(null, null, onboardingName: ' '), isNull);
  });
}
