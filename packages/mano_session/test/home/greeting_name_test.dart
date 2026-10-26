import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

AuthenticatedUser _user({String? username, String? email}) => AuthenticatedUser(
  subject: 'sub-1',
  username: username,
  email: email,
  roles: const {},
);

const _andres = ProviderProfile(
  party: Party(id: 'p1', displayName: 'Andrés Castro', photoUrl: 'a.jpg'),
  bio: '',
  zones: [],
  yearsExperience: 0,
  verified: true,
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

    test('never greets with an email address', () {
      expect(greetingName(_user(email: 'e2e-pro-1956@mano.test')), isNull);
      expect(
        greetingName(
          _user(username: 'e2e-pro-1956@mano.test', email: 'x@mano.test'),
        ),
        isNull,
      );
    });
  });

  group('resolveGreetingName', () {
    test('the onboarding name outranks the profile and the account', () {
      expect(
        resolveGreetingName(
          _user(username: 'Andrés'),
          _andres,
          onboardingName: 'Lucía',
        ),
        'Lucía',
      );
      expect(resolveGreetingName(null, null, onboardingName: 'Lucía'), 'Lucía');
    });

    test('then the profile, then the account', () {
      expect(resolveGreetingName(_user(username: 'Laura'), _andres), 'Andrés');
      expect(resolveGreetingName(_user(username: 'Laura'), null), 'Laura');
    });

    test('an email account with nothing else is plain Hola', () {
      expect(
        resolveGreetingName(_user(username: 'e2e-pro@mano.test'), null),
        isNull,
      );
      expect(resolveGreetingName(null, null, onboardingName: ' '), isNull);
    });
  });

  test('the profile photo only shows beside the profile name', () {
    expect(greetingPhoto(_andres, name: 'Andrés'), 'a.jpg');
    expect(greetingPhoto(_andres, name: 'Lucía'), isNull);
  });

  group('requesterGreetingName', () {
    test('the registered name outranks the account', () {
      const browsing = OnboardingBrowsing(name: 'Ana');
      expect(requesterGreetingName(_user(username: 'Laura'), browsing), 'Ana');
      expect(requesterGreetingName(null, browsing), 'Ana');
    });

    test('falls back to a non-email account name, else Hola', () {
      const blank = OnboardingBrowsing();
      expect(requesterGreetingName(_user(username: 'Laura'), blank), 'Laura');
      expect(
        requesterGreetingName(_user(email: 'ana@mano.test'), blank),
        isNull,
      );
      expect(requesterGreetingName(null, blank), isNull);
      expect(requesterGreetingName(null, const OnboardingTour()), isNull);
    });
  });
}
